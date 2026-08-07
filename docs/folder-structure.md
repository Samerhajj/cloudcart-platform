# Folder Structure

A guide to where things live in this repository.

cloudcart-platform/
├── app/                        # Flask application source code
│   ├── app.py                  # Routes: health check, products, cart, checkout
│   ├── models.py                # Postgres queries (product catalog)
│   ├── db.py                    # Database connection handling
│   ├── requirements.txt
│   └── templates/               # Jinja2 HTML templates
│
├── Dockerfile                   # Builds the Flask app image
├── .dockerignore
│
├── docker/
│   ├── docker-compose.yml       # Local/host Postgres + app stack
│   ├── .env.example              # Template for required environment variables
│   ├── .env                      # Real values (git-ignored)
│   └── init-db/init.sql          # Seeds the products table
│
├── infra/
│   ├── terraform/                # AWS infrastructure as code
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── ec2.tf
│   │   ├── security_groups.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars.example
│   │   └── terraform.tfvars      # Real values (git-ignored)
│   │
│   └── ansible/                  # Server configuration and app deployment
│       ├── inventory.ini
│       ├── playbook.yml
│       ├── group_vars/
│       │   ├── all.yml.example
│       │   └── all.yml           # Real values (git-ignored)
│       └── roles/
│           ├── system-setup/     # Swap file configuration
│           ├── docker/           # Docker Engine + Compose installation
│           ├── k3s/              # Kubernetes, Helm, namespace/service setup
│           ├── jenkins/          # Jenkins install, admin account, pipeline job
│           └── deploy_app/       # Clones repo, deploys via Docker Compose
│
├── kubernetes/
│   ├── namespace.yaml
│   ├── deployment.yaml           # Original plain manifest (superseded by Helm chart)
│   ├── service.yaml
│   ├── secret.yaml.example
│   ├── secret.yaml               # Real values (git-ignored)
│   ├── prometheus-values.yaml    # Helm values for kube-prometheus-stack
│   ├── grafana-secret-values.yaml.example
│   ├── grafana-secret-values.yaml # Real values (git-ignored)
│   └── cloudcart-chart/          # Helm chart for the application
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── ci-cd/
│   └── Jenkinsfile               # Pipeline: checkout, build, test, push, deploy
│
├── docs/                         # This documentation
└── README.md

## Why this structure

- Application code, infrastructure code, and CI/CD definitions are kept in separate top-level folders, so anyone opening the repo can immediately tell where a given concern lives.
- Every category of secret (.env, terraform.tfvars, group_vars/all.yml, secret.yaml, grafana-secret-values.yaml) follows the same pattern: a committed .example template, and a real, git-ignored file created locally by whoever runs the project.
- kubernetes/deployment.yaml and service.yaml remain in the repo even though the Helm chart supersedes them, since they document the manual kubectl apply path used earlier in the project and are referenced by the k3s Ansible role for the namespace and service.
