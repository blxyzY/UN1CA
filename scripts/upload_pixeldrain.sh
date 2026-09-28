#!/usr/bin/env bash
# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later
#

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "Usage: $0 <file>" >&2
    exit 1
fi

if [ -z "${PIXELDRAIN_API_KEY:-}" ]; then
    echo "Error: PIXELDRAIN_API_KEY is not set. Pixeldrain now requires authentication for uploads." >&2
    echo "Get your API key at: https://pixeldrain.com/user/api_keys" >&2
    exit 1
fi

API_BASE="https://pixeldrain.com/api"

RESPONSE="$(curl -s -X POST \
    -u ":${PIXELDRAIN_API_KEY}" \
    -F "file=@${FILE}" \
    "${API_BASE}/file")"

if command -v jq >/dev/null 2>&1; then
    FILE_ID="$(echo "$RESPONSE" | jq -r '.id // empty')"
else
    FILE_ID="$(echo "$RESPONSE" | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi

if [ -z "$FILE_ID" ]; then
    echo "Error: Failed to parse Pixeldrain response:" >&2
    echo "$RESPONSE" >&2
    exit 1
fi

echo "https://pixeldrain.com/u/${FILE_ID}"
