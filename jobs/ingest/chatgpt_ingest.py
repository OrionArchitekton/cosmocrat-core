#!/usr/bin/env python3
"""
Ingest ChatGPT export data into ClickHouse.

This script expects that the ChatGPT export ZIP has already been unpacked to
`data/ingest/ChatGPT-Data` (matching the layout produced by the official export).

Usage:
    python jobs/ingest/chatgpt_ingest.py \
        --input ~/cosmocrat-core/data/ingest/ChatGPT-Data/conversations.json

Environment variables:
    CLICKHOUSE_URL          – HTTP endpoint (e.g. http://localhost:8123)
    CLICKHOUSE_USER         – ClickHouse username (defaults to "default")
    CLICKHOUSE_PASSWORD     – ClickHouse password (defaults to empty)
    CLICKHOUSE_DATABASE     – Target database (defaults to "default")
"""

from __future__ import annotations

import argparse
import json
import logging
import os
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

import requests

LOGGER = logging.getLogger("chatgpt_ingest")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("~/cosmocrat-core/data/ingest/ChatGPT-Data/conversations.json").expanduser(),
        help="Path to conversations.json from the ChatGPT export",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=500,
        help="Number of rows to insert per batch.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse the export and summarise the output without writing to ClickHouse.",
    )
    parser.add_argument(
        "--verbosity",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Logging level.",
    )
    return parser.parse_args()


def json_load(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def create_table(clickhouse: "ClickHouseClient") -> None:
    query = """
    CREATE TABLE IF NOT EXISTS chatgpt_messages (
        conversation_id String,
        conversation_title String,
        message_id String,
        parent_id Nullable(String),
        author_role String,
        content_type String,
        content_text String,
        create_time Float64,
        update_time Float64,
        weight Nullable(Float64),
        status String,
        end_turn UInt8,
        metadata_json String,
        raw_message_json String
    )
    ENGINE = MergeTree
    ORDER BY (conversation_id, create_time, message_id)
    """
    clickhouse.execute_ddl(query)


def flatten_conversation(entry: Dict[str, Any]) -> Iterable[Dict[str, Any]]:
    conversation_id = entry.get("conversation_id") or entry.get("id")
    title = entry.get("title") or ""

    mapping = entry.get("mapping") or {}
    for node_id, node in mapping.items():
        message = node.get("message")
        if not message:
            continue

        author_role = (message.get("author") or {}).get("role") or "unknown"
        content = message.get("content") or {}
        content_type = content.get("content_type") or "unknown"
        parts = content.get("parts") or []
        text_parts: List[str] = []
        for part in parts:
            if isinstance(part, str):
                text_parts.append(part)
            elif isinstance(part, dict) and "text" in part:
                text_parts.append(str(part["text"]))
            else:
                text_parts.append(json.dumps(part, ensure_ascii=False))

        def to_float(value: Any) -> float:
            if value in (None, "", False):
                return 0.0
            try:
                return float(value)
            except (TypeError, ValueError):
                return 0.0

        yield {
            "conversation_id": conversation_id or "",
            "conversation_title": title,
            "message_id": message.get("id") or node_id,
            "parent_id": node.get("parent"),
            "author_role": author_role,
            "content_type": content_type,
            "content_text": "\n\n".join(text_parts),
            "create_time": to_float(message.get("create_time")),
            "update_time": to_float(message.get("update_time")),
            "weight": message.get("weight"),
            "status": message.get("status") or "",
            "end_turn": 1 if message.get("end_turn") else 0,
            "metadata_json": json.dumps(message.get("metadata") or {}, ensure_ascii=False),
            "raw_message_json": json.dumps(message, ensure_ascii=False),
        }


def collect_rows(conversations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for entry in conversations:
        rows.extend(flatten_conversation(entry))
    return rows


def chunked(iterable: List[Dict[str, Any]], size: int) -> Iterable[List[Dict[str, Any]]]:
    for index in range(0, len(iterable), size):
        yield iterable[index : index + size]


class ClickHouseClient:
    def __init__(
        self,
        base_url: str,
        user: Optional[str] = None,
        password: Optional[str] = None,
        database: str = "default",
        timeout: int = 180,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.auth = (user, password) if user is not None else None
        self.database = database
        self.timeout = timeout

    def _request(self, query: str, data: Optional[str] = None) -> requests.Response:
        params = {"database": self.database, "query": query}
        response = requests.post(
            self.base_url,
            params=params,
            data=data.encode("utf-8") if data is not None else None,
            auth=self.auth,
            timeout=self.timeout,
        )
        if response.status_code != 200:
            LOGGER.error("ClickHouse error: %s", response.text.strip())
            response.raise_for_status()
        return response

    def execute_ddl(self, query: str) -> None:
        LOGGER.debug("Executing DDL:\n%s", query.strip())
        self._request(query)

    def insert_json_each_row(self, table: str, rows: Iterable[Dict[str, Any]]) -> None:
        payload = "\n".join(json.dumps(row, ensure_ascii=False) for row in rows)
        query = f"INSERT INTO {table} FORMAT JSONEachRow"
        LOGGER.debug("Inserting %d rows into %s", payload.count("\n") + 1 if payload else 0, table)
        self._request(query, data=payload)


def main() -> None:
    args = parse_args()
    logging.basicConfig(level=getattr(logging, args.verbosity))

    if not args.input.exists():
        raise FileNotFoundError(f"Input file not found: {args.input}")

    LOGGER.info("Loading conversations from %s", args.input)
    conversations = json_load(args.input)
    rows = collect_rows(conversations)
    LOGGER.info("Prepared %d messages from %d conversations", len(rows), len(conversations))

    if args.dry_run:
        LOGGER.info("Dry-run complete. No data written to ClickHouse.")
        return

    clickhouse_url = os.environ.get("CLICKHOUSE_URL", "http://localhost:8123")
    clickhouse_user = os.environ.get("CLICKHOUSE_USER")
    clickhouse_password = os.environ.get("CLICKHOUSE_PASSWORD")
    clickhouse_database = os.environ.get("CLICKHOUSE_DATABASE", "default")

    LOGGER.info(
        "Connecting to ClickHouse at %s (database=%s)",
        clickhouse_url,
        clickhouse_database,
    )
    timeout_seconds = int(os.environ.get("CLICKHOUSE_HTTP_TIMEOUT", "180"))
    client = ClickHouseClient(
        clickhouse_url,
        user=clickhouse_user,
        password=clickhouse_password,
        database=clickhouse_database,
        timeout=timeout_seconds,
    )

    create_table(client)

    inserted = 0
    for batch in chunked(rows, args.batch_size):
        client.insert_json_each_row("chatgpt_messages", batch)
        inserted += len(batch)
        LOGGER.debug("Inserted %d/%d rows", inserted, len(rows))

    LOGGER.info("Ingestion complete. Inserted %d rows into chatgpt_messages.", inserted)


if __name__ == "__main__":
    main()

