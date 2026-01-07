#!/usr/bin/env bash

# Start the Managed ChatKit FastAPI backend in production mode.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ORIGINAL_PWD="${PWD}"

cd "$PROJECT_ROOT"

# Activate virtual environment
if [ ! -d ".venv" ]; then
  echo "Creating virtual env in $PROJECT_ROOT/.venv ..."
  python3.11 -m venv .venv
fi

source .venv/bin/activate

echo "Installing backend deps (editable) ..."
.venv/bin/pip install . >/dev/null

# Load env vars from the repo's .env.local (if present)
ENV_FILE=""
for possible_path in "$PROJECT_ROOT/../.env.local" "$ORIGINAL_PWD/.env.local" "$PROJECT_ROOT/.env.local" ".env.local"; do
  if [ -f "$possible_path" ]; then
    ENV_FILE="$possible_path"
    break
  fi
done

if [ -z "${OPENAI_API_KEY:-}" ] && [ -n "$ENV_FILE" ]; then
  echo "Sourcing environment variables from $ENV_FILE"
  set -a
  . "$ENV_FILE"
  set +a
fi

# Set production environment
export ENVIRONMENT=production
export NODE_ENV=production

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY not set. Set it in your environment or .env.local file."
  exit 1
fi

export PYTHONPATH="$PROJECT_ROOT${PYTHONPATH:+:$PYTHONPATH}"

# Get host and port from environment or use defaults
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
WORKERS="${WORKERS:-4}"

echo "Starting Managed ChatKit backend in production mode on http://${HOST}:${PORT} ..."
exec uvicorn app.main:app --host "$HOST" --port "$PORT" --workers "$WORKERS" --no-access-log
