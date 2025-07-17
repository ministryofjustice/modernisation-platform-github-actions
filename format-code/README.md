# 🔧 GitHub Actions Code Formatter (Reusable Workflow)

This is a reusable GitHub Actions workflow that runs [MegaLinter](https://megalinter.io/) to automatically lint and format your codebase. It helps enforce consistent standards and can auto-correct issues by raising pull requests.

It runs on a schedule or via manual trigger, and will open a pull request with any fixes it applies.

---

## ✅ Features

- Powered by [MegaLinter](https://megalinter.io/), the all-in-one code linter and formatter
- **Supports all major languages and formats**, including Terraform, Python, Markdown, JSON, YAML, etc.
- Uses [MegaLinter flavors](https://megalinter.io/flavors/) to optimise speed and relevance
- Automatically creates a pull request with signed commits if changes are needed
- Fully configurable by consumers via inputs

---

## 🚀 Quick Start

In your repository, create a workflow like `.github/workflows/format-code.yml`:

```yaml
name: Format Code

on:
  workflow_dispatch:
  schedule:
    - cron: "45 4 * * 1-5"

permissions:
  contents: write
  pull-requests: write

jobs:
  format:
    uses: ministryofjustice/modernisation-platform-github-actions/format-code@0442287e70970e2e732fbfecf17fd362d2d21dee # 3.2.6
    with:
      flavor: terraform
      pr_title: "Code Formatter PR"
      pr_body: "Automated PR created by the reusable Code Formatter workflow."
```

Replace `flavor: terraform` with another flavor if needed (see below).

---

## 🧬 MegaLinter Flavors

This workflow supports [MegaLinter Flavors](https://megalinter.io/flavors/) to optimize performance based on your codebase.

| Flavor      | Description                        |
| ----------- | ---------------------------------- |
| `full`      | ✅ Default — all supported linters |
| `terraform` | Optimised for Terraform codebases  |
| `python`    | Optimised for Python projects      |
| `light`     | Minimal linters, fastest linting   |

You can override the default flavor like so:

```yaml
with:
  flavor: python
```

---

## 🧾 Inputs

These inputs let you fine-tune behaviour. All are optional and have sensible defaults.

| Name                                         | Default Value                                                                             | Description                                                                          |
| -------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `flavor`                                     | `full`                                                                                    | MegaLinter flavor to use (e.g., `terraform`, `python`, `full`)                       |
| `pr_title`                                   | `"GitHub Actions Code Formatter workflow"`                                                | Title of the auto-created pull request                                               |
| `pr_body`                                    | `"This pull request includes updates from the GitHub Actions Code Formatter workflow..."` | Body of the PR                                                                       |
| `apply_fixes`                                | `all`                                                                                     | What to fix (e.g. `none`, `all`)                                                     |
| `apply_fixes_event`                          | `all`                                                                                     | Trigger type to apply fixes (`push`, `pull_request`, `all`)                          |
| `apply_fixes_mode`                           | `pull_request`                                                                            | Apply fixes as `commit` or via `pull_request`                                        |
| `disable_errors`                             | `true`                                                                                    | If `true`, warnings do not fail the job                                              |
| `email_reporter`                             | `false`                                                                                   | If `true`, sends email reports                                                       |
| `enable_linters`                             | `JSON_PRETTIER,YAML_PRETTIER,TERRAFORM_TERRAFORM_FMT,MARKDOWN_MARKDOWNLINT`               | Comma-separated list of linters to enable                                            |
| `validate_all_codebase`                      | `true`                                                                                    | If `true`, lints the entire codebase                                                 |
| `yaml_prettier_filter_regex_exclude`         | `(.github/*)`                                                                             | Regex for YAML files to exclude                                                      |
| `markdown_markdownlint_filter_regex_exclude` | `(terraform/modules/.*/.*.md)`                                                            | Regex for Markdown files to exclude                                                  |
| `report_output_folder`                       | `""`                                                                                      | Optional output folder for MegaLinter reports. Leave empty to disable report output. |

---

## 📁 Required File: `scripts/git-setup.sh`

Your repo must include a `scripts/git-setup.sh` script to configure git (e.g., set user/email, etc.). Example content:

```bash
#!/bin/bash
git config --global user.email "github-actions@github.com"
git config --global user.name "github-actions"
```

This script ensures the PR commit is signed correctly.

---

## 🔐 Security Notes

- All action references are **pinned to specific versions** for stability and security.
- Pull requests are created using a reusable [signed commit workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions) to ensure traceability.
- Uses the GitHub-provided `GITHUB_TOKEN` with limited scoped permissions.

---

## 🛠 Example: Custom Python Setup

```yaml
jobs:
  format:
    uses: ministryofjustice/modernisation-platform-github-actions/format-code@0442287e70970e2e732fbfecf17fd362d2d21dee # 3.2.6
    with:
      flavor: python
      enable_linters: "PYTHON_PYLINT,MARKDOWN_MARKDOWNLINT"
      apply_fixes_mode: commit
      apply_fixes_event: all
```

---

## 🤝 Contributing

If you want to add new defaults, linter configurations, or improvements — open a PR in this repo.

---

## 📚 Resources

- [MegaLinter Docs](https://megalinter.io/)
- [Flavors Guide](https://megalinter.io/flavors/)
- [Signed Commit Action](https://github.com/ministryofjustice/modernisation-platform-github-actions)

---
