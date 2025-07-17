# 🔧 Code Formatter (Reusable Workflow)

This is a reusable GitHub Actions workflow that runs [MegaLinter](https://megalinter.io/) to automatically lint and format your codebase. It helps enforce consistent standards and can auto-correct issues.

This workflow runs MegaLinter only. To create pull requests with signed commits containing any fixes, you can chain this workflow with a separate [signed-commit reusable workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions/signed-commit).

---

## ✅ Features

- Powered by [MegaLinter](https://megalinter.io/), the all-in-one code linter and formatter
- **Supports all major languages and formats**, including Terraform, Python, Markdown, JSON, YAML, etc.
- Uses [MegaLinter flavors](https://megalinter.io/flavors/) to optimise speed and relevance
- Fully configurable by consumers via inputs

---

## 🚀 Quick Start

Create a workflow file in your repository, for example `.github/workflows/format-code.yml`:

```yaml
name: "Format Code: ensure code formatting guidelines are met"

on:
  workflow_dispatch:
  schedule:
    - cron: "45 4 * * 1-5"

permissions:
  contents: write

jobs:
  format:
    uses: ministryofjustice/modernisation-platform-github-actions/format-code@v3.2.6
    with:
      flavor: terraform
```

> **Note:** This workflow only runs MegaLinter. To automatically create pull requests with fixes and signed commits, chain this with the [signed-commit reusable workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions).

---

## 🧬 MegaLinter Flavors

This workflow supports [MegaLinter Flavors](https://megalinter.io/flavors/) to optimise performance and relevance based on your codebase:

| Flavor      | Description                             |
| ----------- | --------------------------------------- |
| `full`      | ✅ Default — runs all supported linters |
| `terraform` | Optimised for Terraform codebases       |
| `python`    | Optimised for Python projects           |
| `light`     | Minimal linters, fastest linting        |

You can override the default flavor like so:

```yaml
with:
  flavor: python
```

---

## 🧾 Inputs

These inputs let you fine-tune behaviour. All are optional with sensible defaults:

| Name                                         | Default Value                                                               | Description                                                                          |
| -------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `flavor`                                     | `full`                                                                      | MegaLinter flavor to use (e.g., `terraform`, `python`, `full`)                       |
| `apply_fixes`                                | `all`                                                                       | What to fix (e.g., `none`, `all`)                                                    |
| `apply_fixes_event`                          | `all`                                                                       | Trigger type to apply fixes (`push`, `pull_request`, `all`)                          |
| `apply_fixes_mode`                           | `pull_request`                                                              | Apply fixes as `commit` or via `pull_request`                                        |
| `disable_errors`                             | `true`                                                                      | If `true`, warnings do not fail the job                                              |
| `email_reporter`                             | `false`                                                                     | If `true`, sends email reports                                                       |
| `enable_linters`                             | `JSON_PRETTIER,YAML_PRETTIER,TERRAFORM_TERRAFORM_FMT,MARKDOWN_MARKDOWNLINT` | Comma-separated list of linters to enable                                            |
| `validate_all_codebase`                      | `true`                                                                      | If `true`, lints the entire codebase                                                 |
| `yaml_prettier_filter_regex_exclude`         | `(.github/*)`                                                               | Regex for YAML files to exclude                                                      |
| `markdown_markdownlint_filter_regex_exclude` | `(terraform/modules/.*/.*.md)`                                              | Regex for Markdown files to exclude                                                  |
| `report_output_folder`                       | `""`                                                                        | Optional output folder for MegaLinter reports. Leave empty to disable report output. |
| `ignore_files`                               | `""`                                                                        | Optional regex or glob patterns of files to exclude                                  |

---

## 🔐 Security Notes

- All action references are **pinned to specific versions** for stability and security.
- Pull requests with signed commits are created using a separate reusable [signed commit workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions).
- Uses the GitHub-provided `GITHUB_TOKEN` with limited scoped permissions.

---

## 🛠 Example: Custom Python Setup

```yaml
jobs:
  format:
    uses: ministryofjustice/modernisation-platform-github-actions/format-code@v3.2.6
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
