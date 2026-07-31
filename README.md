# CloudCart Platform

Internal e-commerce storefront platform for CloudCart, a small online store
provider serving independent sellers.

This repository contains the application code and the infrastructure,
automation, and operations tooling that runs it — built as part of
productionizing CloudCart's Flask storefront application.

## Structure
- app/ — Flask application source
- docker/ — Dockerfile(s) and Compose definitions
- infra/terraform/ — AWS infrastructure as code
- infra/ansible/ — server configuration playbooks
- ci-cd/ — Jenkins pipeline definitions
- kubernetes/helm-chart/ — Kubernetes manifests and Helm chart
- monitoring/ — Prometheus and Grafana configuration
- docs/ — architecture, decisions, and operational documentation
