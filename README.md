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

1. An AWS account, with an IAM user that has EC2, security group, and S3 permissions. Configure the AWS CLI with that user's credentials by running `aws configure` and providing the Access Key ID, Secret Access Key, and your preferred region.
2. An EC2 key pair created in the AWS Console (EC2 -> Network & Security -> Key Pairs -> Create key pair, format .pem), downloaded and saved locally, for example to `~/.ssh/aws-keys/your-keypair.pem`. Set its permissions with `chmod 400 ~/.ssh/aws-keys/your-keypair.pem`.
3. Terraform, Ansible, and the AWS CLI installed locally.
4. Your current public IP address, for example from `curl https://checkip.amazonaws.com`, used to restrict SSH access to only you.

### 1. Provision AWS infrastructure (on your local machine)

Navigate to infra/terraform. Copy terraform.tfvars.example to terraform.tfvars.

Edit terraform.tfvars and set my_ip to your public IP in CIDR notation (e.g. 123.45.67.89/32) and key_pair_name to the name of the EC2 key pair created above.

Run terraform init, then terraform apply. This creates the EC2 instance and security group, and automatically writes the instance's public IP into infra/ansible/inventory.ini.

### 2. Configure the server (run from your local machine)

Navigate to infra/ansible. The inventory.ini file was already generated in the previous step and points at your new instance.

Copy group_vars/all.yml.example to group_vars/all.yml, and set a real Jenkins admin password.

Run ansible-playbook -i inventory.ini playbook.yml. This command runs on your local machine but connects to the EC2 instance over SSH and configures it: installing Docker, Kubernetes (k3s), Helm, and Jenkins, and applying the base Kubernetes namespace and service. This step takes several minutes.

### 3. Set application secrets (on your local machine, before running Ansible)

Copy docker/.env.example to .env in the docker/ folder and fill in real values: a random string for FLASK_SECRET_KEY, and a database name, user, and password of your choice for DB_NAME, DB_USER, and DB_PASSWORD. This must be done before running ansible-playbook in step 2, since Ansible copies this file to the server and uses its values to create the Kubernetes secret and deploy the application automatically.

### 4. Application deployment

No manual action needed here: the ansible-playbook run in step 2 already created the Kubernetes secret from the .env values and installed the application via Helm. Confirm it deployed correctly by checking http://<instance-ip>:30500/products once step 2 completes.


### 5. Configure the Jenkins pipeline (in your browser)

Open http://<instance-ip>:8080 and log in with the admin username and password set in group_vars/all.yml. The cloudcart-pipeline job already exists, created automatically during server configuration, but needs two credentials added before it can build and deploy successfully: go to Manage Jenkins -> Credentials -> (global) -> Add Credentials, and add:

ec2-ssh-key: kind SSH Username with private key, username ubuntu, private key pasted directly from your EC2 key pair file. This lets the pipeline deploy over SSH.

dockerhub-credentials: kind Username with password, using a Docker Hub username and an access token (not your account password). This lets the pipeline push built images.

Update the IMAGE_NAME variable near the top of ci-cd/Jenkinsfile to match your own Docker Hub username before running the pipeline.

Update the DEPLOY_HOST parameter's defaultValue in ci-cd/Jenkinsfile to match your instance's current public IP. This value is not automatically kept in sync: if the instance is ever stopped and started again, or destroyed and recreated, its public IP changes and this value must be updated manually, either by editing the Jenkinsfile or by entering the correct IP in the Build with Parameters form each time the pipeline is triggered.

In your GitHub repository, go to Settings -> Webhooks -> Add webhook. Set the Payload URL to http://<instance-ip>:8080/github-webhook/, content type to application/json, and select "Just the push event". This makes Jenkins build automatically on every push to main, rather than requiring a manual trigger.

### 6. Set up monitoring (on the EC2 server)

On the server, from kubernetes/, copy grafana-secret-values.yaml.example to grafana-secret-values.yaml and set a real Grafana admin password.

Add the Prometheus community Helm repository: helm repo add prometheus-community https://prometheus-community.github.io/helm-charts, then helm repo update.

Install the monitoring stack: helm install prometheus-stack prometheus-community/kube-prometheus-stack -n cloudcart -f prometheus-values.yaml -f grafana-secret-values.yaml.

Grafana is reachable at http://<instance-ip>:30300, logging in as admin with the password set above.

### Accessing the application

Once deployed, the application is reachable at http://<instance-ip>:30500/products.

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
