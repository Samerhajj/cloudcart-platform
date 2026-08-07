# Future Improvements

Changes that would be worth making if this were a real, ongoing production system rather than a learning project.

## Infrastructure

- Use a custom VPC with explicit public/private subnet separation instead of the account's default VPC, isolating the database and internal services from direct internet exposure.
- Attach an Elastic IP to the EC2 instance, so stopping and starting it does not change its public IP and require updating Ansible's inventory, Jenkins' deploy parameter, and the Grafana/app URLs by hand.
- Separate the database onto its own instance or a managed service (e.g. RDS), rather than running Postgres via Docker Compose on the same host as everything else.
- Split Jenkins and the monitoring stack onto a dedicated instance, separate from the application's runtime environment, once resource contention between them becomes a limiting factor.

## Secrets management

- Replace the current pattern of git-ignored local files (`.env`, `terraform.tfvars`, `group_vars/all.yml`, Kubernetes secret manifests) with a dedicated secrets manager (AWS Secrets Manager, HashiCorp Vault, or Kubernetes Sealed Secrets), removing the need for any real credential to exist as a plain file on disk at all.
- Use Ansible Vault for the values currently stored in git-ignored local files, so a correctly encrypted version of those files could be committed and shared safely.

## CI/CD

- Automate the final Prometheus/Grafana Helm installation into Ansible, once its resource behavior has been fully validated under realistic load; currently this step is intentionally manual after two resource-exhaustion incidents during testing.
- Have Jenkins deploy from the same repository checkout Ansible uses, rather than maintaining two separate clones of the repository on the same server.
- Add real automated tests (unit tests for the Flask routes, not just the current smoke test) as a distinct pipeline stage.
- Automate Jenkins pipeline job creation and Grafana dashboard provisioning through a single, consistent mechanism rather than the two different approaches currently used (Jenkins REST API with a Groovy-generated token; Helm values for Grafana).

## Kubernetes

- Move the database into the cluster as a StatefulSet with a PersistentVolumeClaim, rather than reaching out to a Docker container running directly on the host via its private IP.
- Replace the NodePort Services (application, Grafana) with an Ingress controller, allowing both to be reached through standard ports with proper hostnames instead of high-numbered NodePorts.
- Add a HorizontalPodAutoscaler once there is a genuine need to scale beyond the current fixed replica count.

## Monitoring

- Configure real Alertmanager routing (email or Slack) rather than running it with no destinations configured.
- Increase Prometheus's metrics retention period once running on hardware with enough headroom to support it comfortably.

## Application

- Add a proper automated test suite.
- Move the shopping cart from session-based cookies to a persisted, database-backed cart, allowing it to survive across devices and sessions.
