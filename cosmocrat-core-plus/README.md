# Cosmocrat Core (Enhanced Scaffold)

Core runtime + optional ClickHouse, n8n, Appsmith, Supabase client, Slack webhook helper.

## Quick start
1) `cp .env.example .env` (or `doppler setup`)
2) Core only:
   ```bash
   ./ops/scripts/bootstrap.sh
   ./ops/scripts/healthcheck.sh
   ```
3) Enable ClickHouse (Lang v3):
   ```bash
   docker compose --profile analytics up -d clickhouse
   ```
4) Enable n8n:
   ```bash
   docker compose --profile automation up -d n8n
   ```
5) Enable Appsmith:
   ```bash
   docker compose --profile cockpit up -d appsmith
   ```

## Notes
- Services emit optional events to ClickHouse via `CH_HTTP_URL` (set to `http://clickhouse:8123`).
- Supabase client helper lives in `app/tools/supabase_client.py` (REST usage).
- Slack helper: `app/tools/slack.py` uses `SLACK_WEBHOOK_URL`.

Mount your packs in `/packs/*` after core is green.
