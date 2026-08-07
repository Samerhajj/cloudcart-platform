#!/bin/bash
#
# deploy.sh — Provisions AWS infrastructure and configures the CloudCart server.
# Wraps the Terraform and Ansible steps described in README.md into one command.
#
# What this script does, in order:
#   1. Checks that required tools and config files exist
#   2. Provisions the EC2 instance and security group via Terraform
#   3. Waits until the new instance actually accepts SSH connections
#   4. Runs the Ansible playbook to install Docker, k3s, Helm, Jenkins,
#      and deploy the application
#   5. Prints the resulting URLs and any steps still requiring manual setup
#
# Usage: ./scripts/deploy.sh

set -euo pipefail
# -e: exit immediately if any command fails, rather than continuing silently
# -u: treat unset variables as an error, catching typos early
# -o pipefail: a pipeline fails if any command in it fails, not just the last one

# Resolve paths relative to this script's location, so it can be run from
# any working directory, not just the repo root.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Step 1: Prerequisite checks -------------------------------------------
# Fail fast and clearly if a required tool is missing, rather than letting
# a later command fail with a confusing error.
echo "==> Checking prerequisites..."
for cmd in terraform ansible-playbook aws; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not installed or not in PATH." >&2
    exit 1
  fi
done

# terraform.tfvars and docker/.env contain real, user-specific values
# (public IP, key pair name, secrets) that are never committed to Git.
# Check they exist before doing anything, since Terraform/Ansible would
# otherwise fail partway through with a less obvious error.
if [ ! -f "$REPO_ROOT/infra/terraform/terraform.tfvars" ]; then
  echo "ERROR: infra/terraform/terraform.tfvars not found." >&2
  echo "Copy terraform.tfvars.example to terraform.tfvars and fill in real values first." >&2
  exit 1
fi

if [ ! -f "$REPO_ROOT/docker/.env" ]; then
  echo "ERROR: docker/.env not found." >&2
  echo "Copy docker/.env.example to .env and fill in real values first." >&2
  exit 1
fi

# --- Step 2: Provision infrastructure ---------------------------------------
echo "==> Provisioning AWS infrastructure with Terraform..."
cd "$REPO_ROOT/infra/terraform"
terraform init
terraform apply -auto-approve
# terraform apply also writes infra/ansible/inventory.ini automatically
# (see the local_file resource in outputs.tf), so Ansible always targets
# the instance actually created here, not a stale IP.

# --- Step 3: Wait for the instance to actually be ready ---------------------
# A fixed sleep is unreliable, since boot time varies. Instead, poll SSH
# directly until the instance responds, up to ~3 minutes, before handing
# off to Ansible.
echo "==> Waiting for the instance to be reachable via SSH..."
INSTANCE_IP=$(terraform output -raw instance_public_ip)
for i in $(seq 1 20); do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/aws-keys/cloudcart-keypair.pem ubuntu@"$INSTANCE_IP" "echo ready" &> /dev/null; then
    echo "==> Instance is reachable."
    break
  fi
  echo "    Still waiting... ($i/20)"
  sleep 10
done

# --- Step 4: Configure the server and deploy the application ---------------
echo "==> Configuring the server with Ansible..."
cd "$REPO_ROOT/infra/ansible"

# group_vars/all.yml holds the real Jenkins admin password, git-ignored
# same as the other secret files checked above.
if [ ! -f "group_vars/all.yml" ]; then
  echo "ERROR: infra/ansible/group_vars/all.yml not found." >&2
  echo "Copy group_vars/all.yml.example to all.yml and set a real Jenkins password first." >&2
  exit 1
fi

# Installs Docker, k3s, Helm, and Jenkins; creates the Kubernetes secret
# from docker/.env; and installs the application via Helm.
ansible-playbook -i inventory.ini playbook.yml

INSTANCE_IP=$(cd "$REPO_ROOT/infra/terraform" && terraform output -raw instance_public_ip)

# --- Step 5: Summary ---------------------------------------------------------
echo ""
echo "==> Deployment complete."
echo "    Application: http://${INSTANCE_IP}:30500/products"
echo "    Jenkins:     http://${INSTANCE_IP}:8080"
echo ""
echo "    Remaining manual steps (see README.md):"
echo "    - Add the dockerhub-credentials Jenkins credential"
echo "    - Confirm the GitHub webhook trigger is enabled (it should be, by default)"
echo "    - Install the monitoring stack (Prometheus/Grafana)"
