# Git Branching Strategy
> Development Workflow, Versioning & Docker Image Tagging Guide

---

## 1. Overview

This document describes the Git branching strategy adopted for all application and service repositories. It covers the full workflow for feature development, release management, bug fixes, hotfixes, versioning via `version.txt`, and Docker image tagging conventions.

---

## 2. Main Branches

Every repository maintains three long-lived branches:

| Branch | Purpose |
|--------|---------|
| `master` | Represents the production-ready state. Only release and hotfix branches are merged here. Every merge triggers a production deployment. |
| `release` | Short-lived branches (e.g., `release/rc-01`) created from develop for QA/Stage/Preprod testing. Merged into master upon approval. |
| `develop` | Main integration branch. All feature branches are merged here. Triggers automated deployment to the dev environment. |

---

## 3. Feature Development Flow

When a developer needs to add a new feature, they follow this workflow:

| Step | Action |
|------|--------|
| `develop` | Developer checks out a feature branch (e.g., `feature/add-user-auth`) |
| `feature/*` | Developer makes commits locally and tests the changes |
| Push upstream | Automated test cases are triggered on the feature branch |
| Tests pass | Developer raises a Pull Request (PR) to merge into develop |
| PR review | Code review completed. Branch must be up to date with develop before merge. |
| PR merged | Merged into develop. Automated deployment triggered to Dev environment. |

### Branch Naming Convention
```
feature/<short-description>
Example: feature/add-user-auth
```

---

## 4. Release Flow

Once features are tested in the dev environment and ready for release, the Release Manager initiates the release process:

| Step | Action |
|------|--------|
| `develop` | Release Manager creates a release branch (e.g., `release/rc-01`) |
| `release/rc-01` | Code is deployed to QA / Stage / Pre-production environments |
| No bugs found | Release branch is merged into master |
| `master` | Automated deployment to Production is triggered |
| `release/rc-01` | Branch is deleted after successful merge |

### Branch Naming Convention
```
release/rc-<version>
Example: release/rc-01, release/rc-02
```

---

## 5. Bug Fix in Release Branch

If a bug is identified during QA/Stage/Preprod testing on an existing release branch:

| Step | Action |
|------|--------|
| `release/rc-01` | Bug identified during testing |
| `release/rc-02` | Release Manager checks out a new release branch from rc-01 |
| Bug fixed | Fix committed, pushed upstream, and deployed to QA/Stage/Preprod |
| Tests pass | Merged into master (Production) and into develop (sync) |
| `release/rc-01` | Previous release branch is deleted |

> **Note:** The develop branch must always be kept in sync with bug fixes applied on the release branch.

---

## 6. Hotfix Flow

A hotfix is required when a critical bug is found in production and needs an immediate fix without waiting for the regular release cycle:

| Step | Action |
|------|--------|
| `master` | Hotfix branch is checked out from master (e.g., `hotfix/fix-login-crash`) |
| `hotfix/*` | Bug is identified, fixed, and tested |
| `master` | Merged into master → Production deployment triggered |
| `release/rc-xx` | Also merged into the current active release branch (sync) |
| `develop` | Also merged into develop to keep all branches in sync |

### Branch Naming Convention
```
hotfix/<short-description>
Example: hotfix/fix-login-crash
```

---

## 7. Versioning Strategy (version.txt)

Every repository maintains a `version.txt` file in the root of the project. This file tracks the current version of the application and is updated at each stage of the branching workflow.

### Version Progression

The version suffix clearly communicates the stage of the code:

| Branch / Stage | Version Format |
|----------------|---------------|
| `feature/*` | `1.1.0-SNAPSHOT` |
| `develop` | `1.1.0-DEV` |
| `release/rc-xx` | `1.1.0-RC` |
| `master` | `1.1.0` |

### Who Updates version.txt?

| Stage | Who | Action |
|-------|-----|--------|
| New release cycle starts | Release Manager | Updates `version.txt` in develop to next version (e.g., `1.2.0-DEV`) |
| Developer checks out feature branch | Developer | Appends `-SNAPSHOT` to get `1.2.0-SNAPSHOT` |
| Release branch cut | Release Manager | Updates `version.txt` to `1.2.0-RC` |
| Release merged into master | Release Manager | Updates `version.txt` to `1.2.0` (removes suffix) |

> **Note:** The CI pipeline is not involved in updating `version.txt` at any stage — it is entirely manual. CI only acts as a validator to catch any version mistakes.

### Version Check in CI Pipeline

Since feature branches always carry `SNAPSHOT` and develop always carries `DEV`, their versions will **never be equal under normal circumstances** — eliminating version conflicts between parallel feature branches working in the same release cycle.

However, a conflict can occur at the **start of a new release cycle**:

- Release Manager bumps `version.txt` in develop from `1.1.0-DEV` to `1.2.0-DEV`.
- A developer with an existing feature branch checked out from the previous cycle still has `1.1.0-SNAPSHOT`.
- When the developer merges develop into their feature branch, Git raises a **merge conflict on version.txt**.
- The developer must manually resolve the conflict by updating their version to `1.2.0-SNAPSHOT`.

The CI pipeline acts as a safety net in this case:

- The feature branch must be up to date with develop before a PR can be merged (enforced via branch protection rules).
- The CI pipeline checks that the version in `version.txt` on the feature branch is not equal to the version in develop.
- If the versions match (e.g., both are `1.2.0-DEV`), the pipeline raises an error and blocks the merge, asking the developer to correct their version to `1.2.0-SNAPSHOT`.

> **Note:** Requiring the branch to be up to date with develop solves two problems simultaneously — it prevents code overwrites from parallel development AND surfaces version conflicts locally, forcing the developer to consciously update their version before raising a PR.

---

## 8. Docker Image Tagging Convention

Every CI build produces two Docker image tags — a specific immutable tag tied to the commit, and a floating `latest` tag for convenience.

### Tagging Strategy per Stage

| Stage | Specific Tag (Immutable) | Floating Tag |
|-------|--------------------------|--------------|
| `feature/*` | `app:1.1.0-SNAPSHOT-<branch>-<commitid>` | `app:1.1.0-SNAPSHOT-<branch>-latest` |
| `develop` | `app:1.1.0-DEV-<commitid>` | `app:1.1.0-DEV-latest` |
| `release/rc-xx` | `app:1.1.0-RC-<commitid>` | `app:1.1.0-RC-latest` |
| `master` | `app:1.1.0` | `app:latest` |

### Why Branch Name in Feature Tag?

When multiple developers work on different feature branches with the same version (e.g., `1.1.0-SNAPSHOT`), their floating tags would overwrite each other if only the version was used. Including the branch name in the tag scopes it to the branch, ensuring each developer has their own isolated floating tag without any manual coordination.

```
app:1.1.0-SNAPSHOT-add-user-auth-latest       # Dev1's floating tag
app:1.1.0-SNAPSHOT-add-payment-gateway-latest # Dev2's floating tag
```

The branch name is derived automatically by the CI pipeline from the Git branch — no developer input or communication required.

### Image Scans

On every push to a feature branch, after the Docker image is built and pushed, the CI pipeline runs automated security and vulnerability scans on the image. Issues must be resolved before the PR can be merged into develop.

---

## 9. Git Tagging Strategy

Git tags are used to mark specific commits at key points in the release lifecycle. Unlike branch names which move with new commits, a tag always points to the same commit — making them ideal for traceability.

### Tag Progression per Release Cycle

Every release cycle follows a consistent versioning and tagging pattern. Version bumps happen at the **release cycle level**, not per feature — all developers working in a cycle share the same version.

```
Release Cycle 1:
  feature branches  →  1.1.0-SNAPSHOT  (no Git tag)
  develop           →  1.1.0-DEV       → Git tag: v1.1.0-DEV
  release branch    →  1.1.0-RC        → Git tag: v1.1.0-RC
  master            →  1.1.0           → Git tag: v1.1.0

Release Cycle 2:
  feature branches  →  1.2.0-SNAPSHOT  (no Git tag)
  develop           →  1.2.0-DEV       → Git tag: v1.2.0-DEV
  release branch    →  1.2.0-RC        → Git tag: v1.2.0-RC
  master            →  1.2.0           → Git tag: v1.2.0
```

### Git Tag to Docker Image Mapping

Git tags drive Docker image tags, creating a single source of truth. Given a Docker image tag, anyone can immediately find the exact commit that produced it using `git checkout <tag>`.

| Git Tag | Docker Image Tags |
|---------|------------------|
| `v1.1.0-DEV` | `app:v1.1.0-DEV`, `app:v1.1.0-DEV-latest` |
| `v1.1.0-RC` | `app:v1.1.0-RC`, `app:v1.1.0-RC-latest` |
| `v1.1.0` | `app:v1.1.0`, `app:latest` |

### Who Creates Git Tags?

All Git tags are created **manually** by the Release Manager at each stage.

---

## 10. Post-Release Checklist

Once a release is successfully merged into master and deployed to production, the following steps must be completed manually by the Release Manager to prepare for the next release cycle:

| Step | Action | Who |
|------|--------|-----|
| 1 | Create release branch from develop (`release/rc-01`) | Release Manager |
| 2 | After release merges into master, merge master back into develop to keep it in sync | Release Manager |
| 3 | Update `version.txt` in develop to the next release version (e.g., `1.1.0-DEV` → `1.2.0-DEV`) | Release Manager |

> **Note:** Step 3 signals the start of the next release cycle. All developers checking out new feature branches after this point will pick up the new version automatically.

---

## 11. Deployment Architecture

> **Stack:** Kubernetes (K8s) | GitHub Actions | Rolling Update Strategy

### Environments Overview

| Environment | Branch | Purpose | Triggered By |
|-------------|--------|---------|--------------|
| `feature-test` | `feature/*` | Developer tests feature branch image in isolated K8s namespace | Developer (manual trigger) |
| `dev` | `develop` | Integration testing after merge to develop | Automatic on merge to develop |
| `stage / preprod` | `release/rc-xx` | QA testing on release branch | Automatic on release branch push |
| `production` | `master` | Live environment | Automatic on merge to master |

### Developer Namespaces (Feature Testing)

To enable developers to test their feature branch images in a production-like environment without contention, each developer gets a dedicated Kubernetes namespace on the shared cluster. This is a lightweight alternative to full ephemeral environments and is a widely adopted pattern in the industry (used by companies like Spotify, Shopify, and Netflix).

- Each developer has their own isolated K8s namespace on the shared cluster.
- Developer deploys their feature branch image (`app:1.1.0-SNAPSHOT-<branch>-latest`) to their namespace via a manual GitHub Actions trigger.
- Resource limits are enforced per namespace using K8s `ResourceQuotas` to control costs.
- Namespaces are lightweight — no significant resource overhead when idle.

> **Pending Decisions:** The following details are to be finalized:
> - Namespace naming convention
> - Lifecycle / cleanup policy
> - Resource limits per namespace
> - Dependency management (shared vs isolated services)

---

## 12. Branch Protection & CI/CD Summary

### Branch Protection Rules

- `master`, `develop`, and `release/*` branches must have branch protection enabled.
- Direct pushes to protected branches are blocked — all changes must go through Pull Requests.
- PRs require at least one code review approval before merging.
- Feature branches must be up to date with develop before merging is allowed.
- All CI status checks (tests, version check, image scans) must pass before merging.

### CI/CD Triggers Summary

| Branch / Event | CI/CD Trigger | Environment |
|----------------|--------------|-------------|
| `feature/*` push | Automated tests + image build + scan | None (test only) |
| Merge to `develop` | CI + version update + Docker build + deploy | Dev |
| `release/rc-xx` push | CI + version update + Docker build + deploy | QA / Stage / Preprod |
| Merge to `master` | CI + version finalize + Docker build + deploy | Production |
| `hotfix/*` merge to master | CI + Docker build + deploy | Production |
