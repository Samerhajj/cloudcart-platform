# Challenges

Specific problems encountered during this project, how they were diagnosed, and how they were resolved.

## 1. SSH lockout risk during Linux hardening

While hardening SSH access on the initial Linux server, I paused before disabling password authentication because no SSH key pair existed on the machine yet. Generating and testing the key pair first, then disabling password auth only after confirming key-based login worked in a separate session, avoided a full lockout that would have required console access to recover from.

## 2. Region mismatch on EC2 key pair

The first `terraform apply` failed with `InvalidKeyPair.NotFound`, even though the key pair had been created in the AWS Console moments earlier. Diagnosed by running `aws ec2 describe-key-pairs --region eu-west-1`, which returned an empty list, confirming the key pair had been created while the console was defaulting to a different region. Recreated the key pair explicitly in the correct region and the instance provisioned successfully.

## 3. Docker repository failing with NO_PUBKEY after Ansible automation

Ansible's `apt_key` and `apt_repository` modules produced a malformed Docker repository configuration, causing `apt update` to reject the repository entirely (`NO_PUBKEY`) even though the same steps worked correctly when run manually. Diagnosed by comparing the actual file written to `/etc/apt/sources.list.d/docker.list` against a known-working manual configuration. Resolved by replacing both modules with the exact `gpg --dearmor` and repository-file commands already proven to work by hand, wrapped in proper idempotency checks.

## 4. Jenkins GPG key rejected despite matching fingerprint

After automating Jenkins' installation, `apt update` rejected the Jenkins repository with `NO_PUBKEY`, even though manually inspecting the key file showed the correct fingerprint. Cross-referenced against Jenkins' official installation documentation and found that Jenkins had rotated its signing key in December 2025; the URL used in automation (`jenkins.io-2023.key`) was outdated. Additionally, the documented method downloads the key directly via `get_url` without piping it through `gpg --dearmor`, which the earlier approach had done unnecessarily, subtly corrupting the key format. Fixed by matching the official method exactly.

## 5. Ansible privilege escalation failure installing Jenkins plugins

A task using `become_user: jenkins` to install Jenkins plugins failed with a permissions error unrelated to file ownership: `Failed to set permissions on the temporary files Ansible needs to create when becoming an unprivileged user`. Resolved by running the command as root via `sudo` directly inside the shell command instead of using Ansible's `become_user` mechanism, avoiding the specific privilege-switching pattern that was failing.

## 6. Jenkins CSRF crumb rejected on automated job creation

Automating Jenkins' pipeline job creation via its REST API consistently failed with `403 No valid crumb was included in the request`, despite fetching a fresh crumb immediately before each request. Jenkins' own logs pointed directly at the fix: crumb-based authentication is not reliable for scripted requests and API tokens should be used instead, since token-authenticated requests bypass CSRF validation. Generated an API token via the same Groovy init script used to create the admin account, and used it in place of the password for all subsequent API calls.

## 7. CPU exhaustion on t3.micro

Jenkins builds intermittently took over an hour or timed out entirely. Diagnosed via `uptime`, which showed a load average above 23 on a single-vCPU instance, and `free -h`, which showed active swap usage. Confirmed `t3.small` was Free Tier eligible for this account via `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true`, and upgraded via Terraform. Build times after the upgrade dropped to approximately 40 seconds.

## 8. Disk exhaustion after adding Kubernetes

After installing k3s, the root volume reached 95% usage (`df -h` showing 437MB free of 7.6GB), risking failures across Docker, Jenkins, and Postgres. Increased the EBS root volume from 8GB to 30GB via Terraform, and applied the change in-place using `growpart` and `resize2fs`, avoiding a full instance recreation and preserving all existing Jenkins and Kubernetes state.

## 9. Repository ownership conflicts between Ansible, Jenkins, and manual SSH sessions

`git` operations against the deployed repository intermittently failed with `insufficient permission for adding an object to repository database`. Diagnosed by inspecting file ownership inside `.git/objects` and finding a mix of `root` and `ubuntu` ownership, caused by an Ansible task inheriting root privileges from the playbook-level `become: yes` default. Fixed by explicitly setting `become_user: ubuntu` on the task, and verified the fix by deleting the repository entirely and confirming a fresh clone produced consistent ownership.


## 10. Resource ceiling reached running the full monitoring stack

Installing the complete `kube-prometheus-stack` (Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter) alongside Jenkins, k3s, Docker, and Postgres on `t3.small` caused the instance to become fully unresponsive, with load average exceeding 8-9 and swap completely exhausted. This confirmed a genuine resource ceiling rather than a configuration bug: `ps aux` showed k3s's own control plane process alone consuming over 670MB RSS. Trimmed the monitoring stack's resource requests/limits and disabled non-essential components (Alertmanager, kube-state-metrics) in a values file, though full validation of the trimmed configuration was deferred to a later session to avoid further destabilizing a system that was still recovering from a reboot.
