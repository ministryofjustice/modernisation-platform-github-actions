# Code Quality reusable workflow

A single, opinionated, reusable workflow providing the Modernisation Platform baseline for
**linting**, **SAST** and **SCA**. It replaces the mixture of MegaLinter invocations, custom
scripts and per-repository security workflows across the estate.

## What it runs

| Category             | Tooling                                                                                                                                                      |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Linting / formatting | MegaLinter: `ACTION_ACTIONLINT`, `BASH_SHELLCHECK`, `JSON_PRETTIER`, `MARKDOWN_MARKDOWNLINT`, `TERRAFORM_TERRAFORM_FMT`, `TERRAFORM_TFLINT`, `YAML_PRETTIER` |
| SAST                 | MegaLinter: `REPOSITORY_CHECKOV`, `REPOSITORY_SEMGREP`, plus optional CodeQL                                                                                 |
| Secrets              | MegaLinter: `REPOSITORY_BETTERLEAKS`                                                                                                                         |
| SCA                  | MegaLinter: `REPOSITORY_GRYPE`, plus `actions/dependency-review-action` on pull requests                                                                     |
| Runner security      | `step-security/harden-runner` in audit mode on public repositories                                                                                           |

Findings are uploaded as SARIF to the repository's GitHub Security tab, and the full MegaLinter
report is attached to the run as an artifact.

Trivy is deliberately not part of the baseline. Grype covers dependency vulnerabilities and Checkov
covers IaC misconfiguration.

### Why MegaLinter rather than Super-Linter

Super-Linter is lint-only: it bundles no SAST, SCA or secret scanning, so it can cover one of the
three things this workflow needs to provide. It is also sequential rather than parallel, has fewer
linters, limited auto-fix, and no aggregated SARIF or pull request comment reporters. Its
advantages are that it is GitHub-maintained and MIT licensed, against MegaLinter's AGPL-3.0; using
an AGPL tool as a CI step places no obligation on the code being scanned.

### Why the `all` MegaLinter image

MegaLinter flavours are strict subsets of the default `all` image, which carries every linter
(124 in the current docs versus 55 in the `terraform` flavour). Using `all` means no linter is unavailable to any
repository and the same workflow works for Terraform, Go, Python and documentation repos alike. The
cost is a larger image pull, not reduced capability.

### Automatic fixes

On pull requests the workflow applies formatter-only fixes and commits them back to the branch as a
signed commit. Only `JSON_PRETTIER`, `MARKDOWN_MARKDOWNLINT`, `TERRAFORM_TERRAFORM_FMT` and
`YAML_PRETTIER` are permitted to write, so no logic-changing linter can rewrite code. Set
`apply_fixes: false` to report only.

YAML files under `.github/` are excluded from Prettier fixes, matching the existing `format-code`
action and avoiding workflow file changes from the auto-fix commit path.

Fixes are skipped for pull requests raised from forks, as the token cannot write to the head branch.

MegaLinter cannot produce signed commits. Its own `APPLY_FIXES_MODE: commit` pushes an unsigned
commit and its documentation steers you towards a Personal Access Token, which it also warns against.
MegaLinter therefore only writes the fixes into the workspace, and the
[`signed-commit`](../signed-commit/README.md) action pushes them as a verified commit using the
built-in `GITHUB_TOKEN`.

### CodeQL

CodeQL runs by default. Languages are detected from checked-out repository files, plus
`actions` when the repository contains workflows, and mapped to CodeQL language identifiers. If no
supported language is found — as is the case for Terraform-only repositories, since CodeQL has no
HCL support — the analysis job is skipped rather than failed.

Set `codeql_languages` to pin the languages explicitly, or `enable_codeql: false` to turn it off.

### Harden Runner

Each job starts with `step-security/harden-runner` in audit mode for public repositories, matching
the Analytical Platform reusable CodeQL workflow pattern. Audit mode records outbound network calls
without blocking them, so the baseline can be observed safely before any future egress policy is
tightened.

Set `enable_harden_runner: false` to turn it off.

## Replacing the existing workflows

The goal is one workflow that covers the jobs the existing workflows do, not a merge of their
implementations. Each existing workflow is assessed against what MegaLinter already provides, and
retired once the coverage is confirmed equivalent.

| Existing                             | Covered by                                         | Assessment                                                                                                                          |
| ------------------------------------ | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `format-code` + `signed-commit`      | This workflow's MegaLinter run and auto-fix commit | Equivalent. Retire once repositories are migrated.                                                                                  |
| Bespoke `code-scanning` / MegaLinter | This workflow                                      | Equivalent. Retire once repositories are migrated.                                                                                  |
| `dependency-review`                  | The `dependency-review` job                        | Equivalent. Retire once repositories are migrated.                                                                                  |
| `terraform-static-analysis`          | `REPOSITORY_CHECKOV` and `TERRAFORM_TFLINT`        | Overlapping. Confirm the per-folder scan types, cloud specific tflint configs and PR comment output are not needed before retiring. |

## Usage

```yaml
name: Code Quality

on:
  pull_request:
    types: [opened, edited, reopened, synchronize]
  push:
    branches: [main]
  schedule:
    - cron: "0 6 * * 1"

permissions: {}

jobs:
  code-quality:
    permissions:
      actions: read
      contents: write
      issues: write
      pull-requests: write
      security-events: write
    uses: ministryofjustice/modernisation-platform-github-actions/.github/workflows/reusable-code-quality.yml@<commit-sha> # vX.Y.Z
```

## Inputs

| Name                                 | Default         | Description                                                                              |
| ------------------------------------ | --------------- | ---------------------------------------------------------------------------------------- |
| `enable_linters`                     | `""`            | Comma separated linters to add to the baseline.                                          |
| `disable_linters`                    | `""`            | Comma separated linters to remove from the baseline.                                     |
| `filter_regex_exclude`               | `""`            | Regex of paths to exclude from linting and SAST.                                         |
| `validate_all_codebase`              | `""`            | `true`/`false`. Defaults to full scans on `main` and schedules, changed files otherwise. |
| `megalinter_config`                  | `""`            | Path to a repository specific `.mega-linter.yml`.                                        |
| `checkov_arguments`                  | `""`            | Additional Checkov CLI arguments.                                                       |
| `tflint_arguments`                   | `""`            | Additional tflint CLI arguments.                                                        |
| `apply_fixes`                        | `true`          | Commit safe formatting fixes back to the pull request branch.                            |
| `enable_dependency_review`           | `true`          | Run dependency review on pull requests.                                                  |
| `dependency_review_fail_on_severity` | `high`          | `low`, `moderate`, `high` or `critical`.                                                 |
| `codeql_languages`                   | `""`            | JSON array of languages, e.g. `'["go","python"]'`. Overrides auto-detection.             |
| `enable_codeql`                      | `true`          | Run CodeQL against the detected languages.                                               |
| `enable_harden_runner`               | `true`          | Run harden-runner in audit mode on public repositories.                                  |
| `runs_on`                            | `ubuntu-latest` | Runner label.                                                                            |

## Permissions

The caller must grant the permissions the workflow needs, as reusable workflows can only ever
narrow what the caller has:

- `contents: write` — checkout and commit formatting fixes (`contents: read` is enough with `apply_fixes: false`)
- `actions: read` — CodeQL analysis metadata
- `issues: write` — MegaLinter pull request fix comments
- `security-events: write` — SARIF upload
- `pull-requests: write` — dependency review PR summary
