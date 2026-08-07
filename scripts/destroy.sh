#!/bin/bash
#
# destroy.sh — Tears down all AWS infrastructure created by deploy.sh.
#
# Usage: ./scripts/destroy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

if ! command -v terraform &> /dev/null; then
  echo "ERROR: terraform is not installed or not in PATH." >&2
  exit 1
fi

cd "$REPO_ROOT/infra/terraform"

if [ ! -f "terraform.tfvars" ]; then
  echo "ERROR: terraform.tfvars not found. Nothing to destroy from this machine." >&2
  exit 1
fi

echo "==> The following resources will be destroyed:"
terraform plan -destroy

echo ""
read -r -p "Type 'yes' to permanently destroy this infrastructure: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted. Nothing was destroyed."
  exit 0
fi

echo "==> Destroying infrastructure..."
terraform destroy -auto-approve

echo ""
echo "==> Destroy complete. All AWS resources have been removed."
echo "    Note: docker/.env, infra/terraform/terraform.tfvars, and infra/ansible/group_vars/all.yml"
echo "    were not modified and can be reused for the next deployment."
