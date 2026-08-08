# Folder Structure

A guide to where things live in this repository.

```text
cloudcart-platform/
├── app/                              # Flask application source code
│   ├── app.py                        # Routes: health check, products, cart, checkout
│   ├── models.py                     # Postgres queries (product catalog)
│   ├── db.py                         # Database connection handling
│   ├── requirements.txt
│   └── templates/                    # Jinja2 HTML templates
│
├── Dockerfile                        # Builds the Flask app image
├── .dockerignore
│
├── docker/
│   ├── docker-compose.yml            # Local/host Postgres + app stack
│   ├── .env.example                  # Template for required environment variables
│   ├── .env                          # Real values (git-ignored)
│   └── init-db/
│       └── init.sql                  # Seeds the products table
│
├── infra/
│   ├── terraform/                    # AWS infrastructure as code
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── ec2.tf
│   │   ├── security_groups.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars.example
│   │   └── terraform.tfvars          # Real values (git-ignored)
│   │
│   └── ansible/                      # Server configuration
│       ├── inventory.ini
│       ├── playbook.yml
│       ├── group_vars/
│       │   ├── all.yml.example
│       │   └── all.yml               # Real values (git-ignored)
│       └── roles/
│           ├── system-setup/         # Swap file configuration
│           ├── docker/               # Docker Engine + Compose installation
│           ├── k3s/                  # Kubernetes and Helm installation
│           └── jenkins/              # Jenkins installation and pipeline setup
│
├── kubernetes/
│   ├── namespace.yaml
│   ├── deployment.yaml               # Original plain manifest (superseded by Helm chart)
│   ├── service.yaml                  # Original plain service manifest
│   ├── secret.yaml.example
│   ├── secret.yaml                   # Real values (git-ignored)
│   ├── prometheus-values.yaml        # Helm values for kube-prometheus-stack
│   ├── grafana-secret-values.yaml.example
│   ├── grafana-secret-values.yaml    # Real values (git-ignored)
│   └── cloudcart-chart/              # Helm chart for the application
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── ci-cd/
│   └── Jenkinsfile                   # Pipeline: checkout, build, test, push, deploy
│
├── docs/                             # Project documentation
└── README.md
```

## Why this structure

* Application code, infrastructure code, and CI/CD definitions are kept in separate top-level folders, so anyone opening the repository can immediately identify where a given concern lives.
* Terraform is responsible for provisioning the AWS infrastructure.
* Ansible is responsible for configuring the server and installing the required infrastructure components such as Docker, k3s, Helm, and Jenkins.
* Jenkins handles the CI/CD pipeline, including checkout, build, test, image publishing, and deployment.
* Kubernetes manifests and the Helm chart are kept under the `kubernetes/` directory.
* The Helm chart is the current deployment method for the application. The original `deployment.yaml` and `service.yaml` files are retained as reference manifests from the earlier manual Kubernetes deployment.
* Docker Compose is kept under `docker/` for local development and for running the application with PostgreSQL outside Kubernetes.
* Every category of secret follows the same pattern: a committed `.example` template and a real, git-ignored file created locally by whoever runs the project.
* Real secret files such as `.env`, `terraform.tfvars`, `group_vars/all.yml`, `secret.yaml`, and `grafana-secret-values.yaml` must never be committed to Git.
