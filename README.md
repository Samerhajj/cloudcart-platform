# CloudCart Platform

An e-commerce storefront for CloudCart, a small business hosting platform for independent sellers. This repository contains the application and the full infrastructure, automation, and operations tooling used to run it in production on AWS.

## What this is

A Flask application (product catalog, cart, checkout) provisioned and deployed entirely as code: AWS infrastructure via Terraform, server configuration via Ansible, containerization via Docker, orchestration via Kubernetes (k3s) and Helm, CI/CD via Jenkins, and observability via Prometheus and Grafana.

## Architecture at a glance

GitHub push leads to Jenkins building, testing, and pushing the image to Docker Hub, then running a Helm upgrade against the k3s cluster, which connects to Postgres running via Docker on the same host.

See docs/architecture.md for the full diagram and explanation.

## Repository structure

See docs/folder-structure.md for a full breakdown of what lives where.

## Running this yourself

This project is designed to be provisioned from scratch on your own AWS account. It requires an AWS account with credentials configured locally, an SSH key pair, and Terraform, Ansible, and Docker installed on your control machine.

### 1. AWS infrastructure

Copy infra/terraform/terraform.tfvars.example to terraform.tfvars and fill in your public IP and EC2 key pair name. Run terraform init, then terraform apply. This provisions an EC2 instance and security group, and outputs the instance's public IP.

### 2. Server configuration and deployment

Terraform automatically writes the instance's public IP into infra/ansible/inventory.ini as part of terraform apply, so no manual editing is needed. Copy group_vars/all.yml.example to group_vars/all.yml and set a real Jenkins admin password. Run ansible-playbook -i inventory.ini playbook.yml. This installs Docker, Kubernetes (k3s), Helm, and Jenkins, and applies the base Kubernetes namespace and service.

### 3. Application secrets

Copy docker/.env.example to .env and fill in real values. Copy kubernetes/secret.yaml.example to secret.yaml and fill in real values, then apply it on the server with kubectl apply -f secret.yaml.

### 4. Deploy the application

From kubernetes/cloudcart-chart, run helm install cloudcart-release . -n cloudcart.

### 5. Jenkins pipeline

Log into Jenkins at http://<instance-ip>:8080 using the admin credentials set in step 2. Add two credentials: ec2-ssh-key (your EC2 key pair, for SSH deployment) and dockerhub-credentials (a Docker Hub username and access token, for pushing images). The cloudcart-pipeline job is created automatically by Ansible and is ready to build.

### 6. Monitoring

Copy kubernetes/grafana-secret-values.yaml.example to grafana-secret-values.yaml and set a real Grafana admin password. On the server, add the Prometheus community Helm repo and run helm install prometheus-stack prometheus-community/kube-prometheus-stack -n cloudcart -f prometheus-values.yaml -f grafana-secret-values.yaml. Grafana is reachable at http://<instance-ip>:30300.

## Documentation

- [Architecture](docs/architecture.md)
- [Folder structure](docs/folder-structure.md)
- [Deployment flow](docs/deployment-flow.md)
- [Challenges](docs/challenges.md)
- [Lessons learned](docs/lessons-learned.md)
- [Future improvements](docs/future-improvements.md)
