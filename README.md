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

Everything below assumes two machines: your own local machine (where you run Terraform and Ansible), and the EC2 instance Terraform creates (where the application, Kubernetes cluster, and Jenkins actually run). Each step below states which machine it runs on.

### Prerequisites (on your local machine)

1. An AWS account. Create an IAM user for this project (AWS Console -> IAM -> Users -> Create user), attach permissions for EC2, Security Groups, and S3, and generate an Access Key ID and Secret Access Key for it. Configure the AWS CLI with these credentials by running `aws configure`.
2. An EC2 key pair created in the AWS Console (EC2 -> Network & Security -> Key Pairs -> Create key pair, format .pem). Double-check the region selector in the top-right of the console matches the region this project uses (eu-west-1 by default) before creating it -- creating the key pair in the wrong region is a common mistake that causes `terraform apply` to fail with `InvalidKeyPair.NotFound`. Download the key, save it locally, for example to `~/.ssh/aws-keys/your-keypair.pem`, and set its permissions with `chmod 400 ~/.ssh/aws-keys/your-keypair.pem`.
3. A Docker Hub account (hub.docker.com), with a public repository created for this project (e.g. `your-username/cloudcart-app`), and an access token generated under Account Settings -> Security -> Personal Access Tokens.
4. Terraform, Ansible, and the AWS CLI installed locally.
5. Your current public IP address, for example from `curl https://checkip.amazonaws.com`, used to restrict SSH access to only you.

### 1. Provision AWS infrastructure (on your local machine)

Navigate to `infra/terraform`. Copy `terraform.tfvars.example` to `terraform.tfvars`.

Edit `terraform.tfvars` and set `my_ip` to your public IP in CIDR notation (e.g. `123.45.67.89/32`) and `key_pair_name` to the exact name of the EC2 key pair created above.

Run `terraform init`, then `terraform apply`. This creates the EC2 instance and security group, and automatically writes the instance's public IP into `infra/ansible/inventory.ini`.

### 2. Set application secrets (on your local machine, before running Ansible)

Copy `docker/.env.example` to `.env` in the `docker/` folder and fill in real values: a random string for `FLASK_SECRET_KEY`, and a database name, user, and password of your choice for `DB_NAME`, `DB_USER`, and `DB_PASSWORD`. This must be done before the next step, since Ansible copies this file to the server and uses its values to create the Kubernetes secret and deploy the application automatically.

### 3. Configure the server and deploy the application (run from your local machine)

Navigate to `infra/ansible`. `inventory.ini` was already generated in step 1 and points at your new instance.

Copy `group_vars/all.yml.example` to `group_vars/all.yml`, and set a real Jenkins admin password.

Run `ansible-playbook -i inventory.ini playbook.yml`. This command runs on your local machine but connects to the EC2 instance over SSH and configures it: installing Docker, Kubernetes (k3s), Helm, and Jenkins; applying the base Kubernetes namespace and service; creating the Kubernetes secret from your `.env` values; and installing the application via Helm. This step takes several minutes.

Once it completes, confirm the application deployed correctly by visiting `http://<instance-ip>:30500/products`.

### 4. Configure the Jenkins pipeline (in your browser)

Open `http://<instance-ip>:8080` and log in with the admin username and password set in step 3. The `cloudcart-pipeline` job already exists, created automatically during server configuration, and its GitHub webhook trigger is enabled by default -- but it needs one credential added before it can build and push images successfully: go to Manage Jenkins -> Credentials -> (global) -> Add Credentials, and add `dockerhub-credentials`: kind Username with password, using your Docker Hub username and the access token generated in the prerequisites (not your account password).

Update the `IMAGE_NAME` variable near the top of `ci-cd/Jenkinsfile` to match your own Docker Hub username and repository before running the pipeline, then commit and push that change.

In your GitHub repository, go to Settings -> Webhooks -> Add webhook. Set the Payload URL to `http://<instance-ip>:8080/github-webhook/`, content type to `application/json`, and select "Just the push event". This makes Jenkins build automatically on every push to `main`.

### 5. Set up monitoring (on the EC2 server)

This step is intentionally manual rather than automated: installing the full monitoring stack alongside Jenkins, k3s, Docker, and Postgres is resource-intensive on a `t3.small` instance, and automating it caused real instability during development (see docs/challenges.md). Expect the instance to be under heavy load for a few minutes after installation.

SSH into the instance. From `kubernetes/`, copy `grafana-secret-values.yaml.example` to `grafana-secret-values.yaml` and set a real Grafana admin password.

Add the Prometheus community Helm repository: `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`, then `helm repo update`.

Install the monitoring stack: `helm install prometheus-stack prometheus-community/kube-prometheus-stack -n cloudcart -f prometheus-values.yaml -f grafana-secret-values.yaml`.

Grafana is reachable at `http://<instance-ip>:30300`, logging in as `admin` with the password set above.

### Accessing the application

Once deployed, the application is reachable at `http://<instance-ip>:30500/products`.

### Running locally instead (no AWS required)

To run the application and database locally with Docker Compose, without touching AWS at all: complete step 2 above (set up `docker/.env`), then run `./scripts/run-local.sh`. The application will be reachable at `http://localhost:5000/products`.

### Tearing down

To destroy all AWS resources created by this project, run `./scripts/destroy.sh` from the repository root. It will show exactly what will be destroyed and require typed confirmation before proceeding.

## Documentation

- [Architecture](docs/architecture.md)
- [Folder structure](docs/folder-structure.md)
- [Deployment flow](docs/deployment-flow.md)
- [Challenges](docs/challenges.md)
- [Lessons learned](docs/lessons-learned.md)
- [Future improvements](docs/future-improvements.md)

## Screenshots

Evidence of the working system, captured during a genuine from-scratch deployment test.

- **Jenkins dashboard** — [docs/screenshots/jenkinsDash.png](docs/screenshots/jenkinsDash.png)
- **Successful pipeline run** (Checkout, Build, Test, Push, Deploy) — [docs/screenshots/jenkinsPipeLineSuccess.png](docs/screenshots/jenkinsPipeLineSuccess.png)
- **Jenkins credentials configured** — [docs/screenshots/jenkinsCredentials.png](docs/screenshots/jenkinsCredentials.png)
- **GitHub webhook configuration** — [docs/screenshots/githubWebHook.png](docs/screenshots/githubWebHook.png)
- **Full automated deployment output** (terraform + ansible via deploy.sh) — [docs/screenshots/deployOutput.png](docs/screenshots/deployOutput.png)
- **Kubernetes pods and Helm release running** — [docs/screenshots/kubectl-pods-running.png](docs/screenshots/kubectl-pods-running.png)
- **Grafana dashboard with live metrics** — [docs/screenshots/grafana.png](docs/screenshots/grafana.png)
