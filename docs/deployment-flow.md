# Deployment Flow

A high-level description of how code moves from a developer's machine to a running, publicly-accessible application. This describes the flow and reasoning, not the exact commands.

## 1. Local development

Application code is written and tested locally. Docker Compose brings up the full stack (Flask app + Postgres) with a single command, letting a developer verify changes work end-to-end before pushing anything.

## 2. Version control

Changes are committed to a feature branch and merged into main via a pull request. This keeps the commit history readable and gives every change a reviewable, documented entry point, even on a solo project.

## 3. Continuous integration

A push to main triggers a webhook that notifies Jenkins. Jenkins checks out the latest code and runs it through four stages:

- Build: the Docker image is built fresh from the current code.
- Test: the freshly built image is started as a temporary container and smoke-tested with a health check request, proving the container actually starts and serves traffic before anything is deployed.
- Push: the tested image is tagged and pushed to Docker Hub, making it available to be pulled by the cluster.
- Deploy: Jenkins connects to the EC2 instance over SSH and runs a Helm upgrade against the existing release, which tells Kubernetes to roll out the new image.

## 4. Rolling deployment

Kubernetes replaces the running pods gradually rather than all at once: a new pod is started, and only once it is healthy does an old pod get terminated. This means the application stays available throughout a deployment rather than having a moment where no pods are serving traffic.

## 5. Infrastructure changes

Infrastructure itself (the EC2 instance, networking, security group rules) is provisioned separately from the application, via Terraform. Server configuration (installing Docker, Kubernetes, Jenkins, setting up swap) is handled by Ansible, run against the provisioned instance. These are deliberately separate from the application's CI/CD pipeline, since they change far less often and carry more risk if automated carelessly.

## 6. Observability

Prometheus continuously scrapes metrics from the cluster and the underlying node. Grafana visualizes those metrics in dashboards, giving a live view of resource usage, pod health, and application behavior without needing to SSH into the server to check.

## Why this separation

Splitting infrastructure provisioning (Terraform), server configuration (Ansible), and application deployment (Jenkins + Helm) into three distinct tools and workflows means each piece can be understood, tested, and changed independently. A change to the application's code never needs to touch Terraform; a change to the EC2 instance's size never needs to touch the Jenkinsfile.
