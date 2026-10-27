#!/usr/bin/env bash
# Mint a limited LiteLLM virtual key for one client/app.
#
# Usage:   ./new-key.sh <alias> [rpm] [max_parallel] [days] [models]
# Example: ./new-key.sh opencode-laptop 30 2 90 local
#          ./new-key.sh openwebui 60 3 30 local,nemotron-3.5-super-vl
#
# Defaults: 30 req/min, 2 concurrent requests, 90 days, model "local".
# Optional env: TPM (tokens/min, default 100000), LITELLM_URL (override target).
#
# Reads LITELLM_MASTER_KEY and LITELLM_BIND from ./.env and talks to LiteLLM on the
# local/LAN port, never through the public tunnel (admin routes aren't exposed there).
set -euo pipefail
cd "$(dirname "$0")"

ALIAS="${1:?usage: $0 <alias> [rpm] [max_parallel] [days] [models]}"
RPM="${2:-30}"
PAR="${3:-2}"
DAYS="${4:-90}"
MODELS="${5:-local}"
TPM="${TPM:-100000}"

envval() { grep -E "^$1=" .env | tail -n1 | cut -d= -f2- | tr -d '"'"'"; }
MASTER="$(envval LITELLM_MASTER_KEY)"
BIND="$(envval LITELLM_BIND)"
URL="${LITELLM_URL:-http://${BIND:-127.0.0.1}:4000}"
[ -n "$MASTER" ] || { echo "LITELLM_MASTER_KEY not found in .env" >&2; exit 1; }

MODELS_JSON="\"$(echo "$MODELS" | sed 's/,/","/g')\""

curl -fsS -X POST "$URL/key/generate" \
  -H "Authorization: Bearer $MASTER" \
  -H "Content-Type: application/json" \
  -d "{
    \"key_alias\": \"$ALIAS\",
    \"models\": [$MODELS_JSON],
    \"rpm_limit\": $RPM,
    \"tpm_limit\": $TPM,
    \"max_parallel_requests\": $PAR,
    \"duration\": \"${DAYS}d\"
  }"
echo
