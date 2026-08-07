#!/bin/bash
#
# destroy.sh — Tears down all AWS infrastructure created by deploy.sh.
#
# What this script does, in order:
#   1. Checks that Terraform is available and a real config exists
#   2. Shows exactly what will be destroyed and asks for typed confirmation
#   3. Destroys the EC2 instance and security group
#   4. Confirms local config files (secrets, tfvars) are untouched, so the
#      next deploy.sh run can reuse them without needing to be re-entered
#
# Usage: ./scripts/destroy.sh

set -euo pipefail
# -e: exit immediately if any command fails
# -u: treat unset variables as an error
# -o pipefail: a pipeline fails if any command in it fails, not just the last one

# Resolve paths relative to this script's location, so it can be run from
# any working directory, not just the repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Step 1: Prerequisite check ---------------------------------------------
if ! command -v terraform &> /dev/null; then
  echo "ERROR: terraform is not installed or not in PATH." >&2
  exit 1
fi

cd "$REPO_ROOT/infra/terraform"

# Without a real terraform.tfvars, Terraform has nothing meaningful to act
# on from this machine, so there's nothing to safely destroy.
if [ ! -f "terraform.tfvars" ]; then
  echo "ERROR: terraform.tfvars not found. Nothing to destroy from this machine." >&2
  exit 1
fi

# --- Step 2: Show the plan and require explicit, typed confirmation --------
# A destructive action like this should never run on a single accidental
# keystroke (e.g. hitting Enter on a y/n prompt). Requiring the full word
# "yes" makes it much harder to trigger by mistake.
echo "==> The following resources will be destroyed:"
terraform plan -destroy

echo ""
read -r -p "Type 'yes' to permanently destroy this infrastructure: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted. Nothing was destroyed."
  exit 0
fi

# --- Step 3: Destroy -----------------------------------------------------
echo "==> Destroying infrastructure..."
terraform destroy -auto-approve

# --- Step 4: Summary -------------------------------------------------------
# terraform.tfvars, docker/.env, and group_vars/all.yml are all local files,
# never managed by Terraform itself, so destroying AWS resources has no
# effect on them. This is worth stating explicitly so it's clear the next
# deploy.sh run won't require re-entering any secrets.
echo ""
echo "==> Destroy complete. All AWS resources have been removed."
echo "    Note: docker/.env, infra/terraform/terraform.tfvars, and infra/ansible/group_vars/all.yml"
echo "    were not modified and can be reused for the next deployment."
