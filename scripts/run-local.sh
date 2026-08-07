#!/bin/bash
#
# run-local.sh — Runs CloudCart entirely on the local machine via Docker Compose.
# Useful for local development and testing without touching any AWS infrastructure.
#
# What this script does, in order:
#   1. Checks that Docker is available
#   2. Checks that docker/.env exists with real values
#   3. Brings up the app and database with Docker Compose
#   4. Waits for the app to respond, then prints the local URL
#
# Usage: ./scripts/run-local.sh

set -euo pipefail
# -e: exit immediately if any command fails
# -u: treat unset variables as an error
# -o pipefail: a pipeline fails if any command in it fails, not just the last one

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Step 1: Prerequisite check ---------------------------------------------
if ! command -v docker &> /dev/null; then
  echo "ERROR: docker is not installed or not in PATH." >&2
  exit 1
fi

# --- Step 2: Confirm secrets exist ------------------------------------------
# docker/.env holds real values (FLASK_SECRET_KEY, DB credentials), never
# committed to Git. Fail clearly rather than let Compose start with blanks.
if [ ! -f "$REPO_ROOT/docker/.env" ]; then
  echo "ERROR: docker/.env not found." >&2
  echo "Copy docker/.env.example to .env and fill in real values first." >&2
  exit 1
fi

# --- Step 3: Bring up the stack ---------------------------------------------
echo "==> Starting CloudCart locally with Docker Compose..."
cd "$REPO_ROOT/docker"
docker compose up -d --build

# --- Step 4: Wait for the app to actually respond ---------------------------
echo "==> Waiting for the application to be ready..."
for i in $(seq 1 15); do
  if curl -sf http://localhost:5000/ &> /dev/null; then
    echo "==> Application is ready."
    break
  fi
  echo "    Still waiting... ($i/15)"
  sleep 3
done

# --- Step 5: Summary ---------------------------------------------------------
echo ""
echo "==> CloudCart is running locally."
echo "    Application: http://localhost:5000/products"
echo ""
echo "    To stop it: docker compose -f docker/docker-compose.yml down"
