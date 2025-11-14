# ChatGPT Memory Ingestion

This runbook covers how to load a ChatGPT export (ZIP download from chat.openai.com) into the shared ClickHouse instance for downstream Langfuse / LangGraph pipelines.

## Prerequisites

* ChatGPT export downloaded and copied to the headless host (e.g. `ChatGPT-Data-ForInitngest.zip`).
* The Docker stack is up and the `clickhouse` service is healthy.
* Environment contains Doppler secrets for `CLICKHOUSE_URL`, `CLICKHOUSE_USER`, and `CLICKHOUSE_PASSWORD`.

## 1. Prepare the data folder

```bash
# on your workstation
scp ChatGPT-Data-ForInitngest.zip edge-01:~/cosmocrat-core/data/ingest/

# on edge-01
cd ~/cosmocrat-core/data/ingest
unzip -o ChatGPT-Data-ForInitngest.zip -d ChatGPT-Data
```

## 2. Run the ingestion script

```bash
cd ~/cosmocrat-core
doppler run -- python jobs/ingest/chatgpt_ingest.py \
  --input data/ingest/ChatGPT-Data/conversations.json
```

The script will:

1. Flatten each conversation into individual messages.
2. Create the `chatgpt_messages` table if it does not exist.
3. Insert the dataset in batches via the ClickHouse HTTP API.

By default it loads every message; use `--dry-run` to inspect counts without writing data, or `--batch-size` to adjust insert granularity.

## 3. Verify the import

```bash
doppler run -- curl -sS "$CLICKHOUSE_URL/?query=SELECT%20count()%20FROM%20chatgpt_messages"
```

You should see the total number of messages inserted. For exploratory analysis you can open the ClickHouse UI or query via Langfuse dashboards.

## 4. Instrumentation (optional)

If you want Langfuse traces around the ingestion run, initialise the Python SDK with masking enabled to avoid leaking PII before wrapping the ingest call:

```python
from langfuse import Langfuse

client = Langfuse(mask=lambda data, **_: data)
with client.start_as_current_span(name="chatgpt-ingest"):
    ingest()  # call into the script's main logic
```

See the Langfuse advanced usage guide for masking and sampling options that help keep sensitive export data safe while still providing observability into ingestion runs [[docs]](https://langfuse.com/docs/observability/sdk/python/advanced-usage).

## 5. Scheduling

For repeat imports (e.g. monthly exports) drop the ZIP into `data/ingest/` and rerun the script. The table can be truncated beforehand if you want a clean load:

```bash
doppler run -- curl -sS "$CLICKHOUSE_URL/?query=TRUNCATE%20TABLE%20chatgpt_messages"
```

Otherwise the script will append rows; upstream consumers should treat `conversation_id` + `message_id` as the primary key.

