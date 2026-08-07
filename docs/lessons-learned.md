# Lessons Learned

## Verify before trusting a tool's reported success

Several times during this project, a command reported success (`ok`, `changed`, a 200 response) while the underlying result was still wrong — Ansible's `become_user` masking a real permission error, a Docker repository accepted by `apt update` but silently failing signature checks, a Jenkins API call returning a status we had explicitly allowed as acceptable. The habit that consistently caught these was checking the actual resulting state directly (reading the file that was written, querying the resource that was supposedly created) rather than trusting the tool's own summary of what happened.

## Idempotency has to be designed in, not assumed

Several early Ansible tasks (plugin installation, job creation) were written without proper idempotency checks and caused real problems on re-runs — redundant, resource-heavy downloads on every playbook execution, contributing directly to one of the CPU exhaustion incidents. Adding explicit `stat`/`command` checks before acting, consistently, was the fix, but it should have been the default from the start rather than something retrofitted after a failure.

## Manual, one-time setup steps are an acceptable and honest trade-off for secrets

Every credential in this project (SSH keys, database passwords, Docker Hub tokens, the Flask secret key) follows the same pattern: a committed `.example` template and a real, git-ignored file created manually. This is not a gap in automation — deliberately keeping secret provisioning manual, while automating everything else, is the correct boundary, and it is one worth being able to explain clearly rather than apologizing for.

## Infrastructure sizing is a real engineering decision, not a one-time setting

This project hit genuine, measurable resource limits three separate times (CPU on t3.micro, disk space after adding Kubernetes, and combined memory pressure after adding a full monitoring stack), each with its own distinct evidence and its own distinct fix. Matching instance size to actual workload, verified with real numbers rather than assumption, was as much a part of this project as writing the Terraform or Ansible code itself.


## Two independent copies of a repository need explicit synchronization

Running Ansible and Jenkins against the same server, but through two separate checkouts of the same repository, meant that a merge on GitHub did not automatically become "live" anywhere until each copy was explicitly pulled. This was a repeated, avoidable source of confusion throughout the project, and understanding it clearly — rather than assuming any one push was automatically reflected everywhere — was necessary before that confusion actually stopped happening.
