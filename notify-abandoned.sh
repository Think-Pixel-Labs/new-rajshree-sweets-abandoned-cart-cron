#!/bin/bash
# ─────────────────────────────────────────────────────────────
# NRSPL Abandoned Cart Cron (Railway: AbandonedCartCron)
# Runs every 15 minutes to notify users of abandoned carts
# ─────────────────────────────────────────────────────────────

set -euo pipefail

API_URL="${API_URL:-https://api.newrajshreesweets.com}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "${ADMIN_USERNAME:-}" ] || [ -z "${ADMIN_PASSWORD:-}" ]; then
  echo "[$TIMESTAMP] ERROR: ADMIN_USERNAME and ADMIN_PASSWORD env vars are required"
  exit 1
fi

echo "[$TIMESTAMP] Starting abandoned cart notification check..."

LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "${API_URL}/admin/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\"}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -1)
BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "[$TIMESTAMP] ERROR: Login failed (HTTP $HTTP_CODE): $BODY"
  exit 1
fi

TOKEN=$(echo "$BODY" | jq -r '.data.token // .data // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "[$TIMESTAMP] ERROR: Failed to extract token from login response"
  exit 1
fi

echo "[$TIMESTAMP] Admin login successful"

NOTIFY_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "${API_URL}/admin/carts/notify-abandoned" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d "{}")

HTTP_CODE=$(echo "$NOTIFY_RESPONSE" | tail -1)
BODY=$(echo "$NOTIFY_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
  echo "[$TIMESTAMP] ERROR: Notify failed (HTTP $HTTP_CODE): $BODY"
  exit 1
fi

MESSAGE=$(echo "$BODY" | jq -r '.message')
echo "[$TIMESTAMP] $MESSAGE"
echo "[$TIMESTAMP] Abandoned cart cron completed successfully"
