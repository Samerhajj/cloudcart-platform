#!/bin/bash
#
# deploy.sh — Provisions AWS infrastructure and configures the CloudCart server.
# Wraps the Terraform and Ansible steps described in README.md into one command.
#
# Usage: ./scripts/deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "==> Checking prerequisites..."
for cmd in terraform ansible-playbook aws; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not installed or not in PATH." >&2
    exit 1
  fi
done

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

echo "==> Provisioning AWS infrastructure with Terraform..."
cd "$REPO_ROOT/infra/terraform"
terraform init
terraform apply -auto-approve

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

echo "==> Configuring the server with Ansible..."
cd "$REPO_ROOT/infra/ansible"

if [ ! -f "group_vars/all.yml" ]; then
  echo "ERROR: infra/ansible/group_vars/all.yml not found." >&2
  echo "Copy group_vars/all.yml.example to all.yml and set a real Jenkins password first." >&2
  exit 1
fi

ansible-playbook -i inventory.ini playbook.yml

INSTANCE_IP=$(cd "$REPO_ROOT/infra/terraform" && terraform output -raw instance_public_ip)

echo ""
echo "==> Deployment complete."
echo "    Application: http://${INSTANCE_IP}:30500/products"
echo "    Jenkins:     http://${INSTANCE_IP}:8080"
echo ""
echo "    Remaining manual steps (see README.md):"
echo "    - Add Jenkins credentials (ec2-ssh-key, dockerhub-credentials)"
echo "    - Set up the GitHub webhook"
echo "    - Install the monitoring stack (Prometheus/Grafana)"
