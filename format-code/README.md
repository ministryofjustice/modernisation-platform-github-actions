# 🔧 Code Formatter (Reusable Workflow)

This is a reusable GitHub Actions workflow that runs [MegaLinter](https://megalinter.io/) to automatically lint and format your codebase. It helps enforce consistent standards and can auto-correct issues.

This workflow runs MegaLinter only. To create pull requests with signed commits containing any fixes, you can chain this workflow with a separate [signed-commit reusable workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions/signed-commit).

---

## ✅ Features

- Powered by [MegaLinter](https://megalinter.io/), the all-in-one code linter and formatter
- **Supports all major languages and formats**, including Terraform, Python, Markdown, JSON, YAML, etc.
- Uses [MegaLinter flavors](https://megalinter.io/flavors/) to optimise speed and relevance
- Fully configurable by consumers via inputs
- Uploads SARIF reports to GitHub Security tab for actionable insights

---

## 🚀 Quick Start

Create a workflow file in your repository, for example `.github/workflows/format-code.yml`:

```yaml
name: Format Code

on:
  pull_request:
    types: [opened, edited, reopened, synchronize]

permissions:
  contents: write
  security-events: write # needed for SARIF upload

jobs:
  format-code:
    uses: ministryofjustice/modernisation-platform-github-actions/.github/workflows/format-code.yml@<ref>
    with:
      flavor: terraform
      ignore_files: "README.md"

  commit-fixes:
    uses: ministryofjustice/modernisation-platform-github-actions/signed-commit@<ref>
    if: ${{ always() }}
    with:
      github_token: ${{ secrets.GITHUB_TOKEN }}
      pr_title: "GitHub Actions Code Formatter workflow"
      pr_body: "This pull request includes updates from the GitHub Actions Code Formatter workflow. Please review the changes and merge if everything looks good."
```

> 🔁 Replace <ref> with a specific commit SHA or tag (e.g. v1.0.0) to ensure stability.
> **Note:** This workflow only runs MegaLinter. To automatically create pull requests with fixes and signed commits, chain this with the [signed-commit reusable workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions) as per above example.

---

## 🧬 MegaLinter Flavors

This workflow supports [MegaLinter Flavors](https://megalinter.io/flavors/) to optimise performance and relevance based on your codebase:

| Flavor      | Description                             |
| ----------- | --------------------------------------- |
| `full`      | ✅ Default — runs all supported linters |
| `terraform` | Optimised for Terraform codebases       |
| `python`    | Optimised for Python projects           |
| `light`     | Minimal linters, fastest linting        |

Override the flavor by setting the `flavor` input:

```yaml
with:
  flavor: python
```

---

## 🧾 Inputs

These inputs let you fine-tune behaviour. All are optional with sensible defaults:

| Name                                         | Default Value                                                               | Description                                                                                                   |
| -------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `flavor`                                     | `full`                                                                      | MegaLinter flavor to use                                                                                      |
| `apply_fixes`                                | `all`                                                                       | What to fix (e.g., `none`, `all`)                                                                             |
| `apply_fixes_event`                          | `all`                                                                       | When to apply fixes (`push`, `pull_request`, `all`)                                                           |
| `apply_fixes_mode`                           | `pull_request`                                                              | How to apply fixes (`commit` or `pull_request`)                                                               |
| `disable_errors`                             | `true`                                                                      | If `true`, warnings do not fail the job                                                                       |
| `email_reporter`                             | `false`                                                                     | If `true`, sends email reports                                                                                |
| `enable_linters`                             | `JSON_PRETTIER,YAML_PRETTIER,TERRAFORM_TERRAFORM_FMT,MARKDOWN_MARKDOWNLINT` | Comma-separated list of linters to enable                                                                     |
| `ignore_files`                               | `""`                                                                        | Regex or glob pattern of files to exclude                                                                     |
| `markdown_markdownlint_filter_regex_exclude` | `""`                                                                        | Regex pattern to exclude specific Markdown files                                                              |
| `report_output_folder`                       | `""`                                                                        | Optional output folder for MegaLinter reports                                                                 |
| `validate_all_codebase`                      | `false`                                                                     | If `true`, lints the entire codebase. If left empty, it defaults to `true` on `push` or `schedule` to `main`. |
| `yaml_prettier_filter_regex_exclude`         | `(.github/*)`                                                               | Regex pattern to exclude YAML files (default excludes GitHub configs)                                         |

> If `validate_all_codebase` is not provided, it defaults to `true` on `push` or `schedule` events to the `main` branch.  
> However, explicitly setting it to `"false"` disables full-codebase validation regardless of the event.

---

## 🔐 Security Notes

- All actions are **pinned to specific commit SHAs** for security and stability.
- SARIF output is uploaded to the GitHub Security tab for visibility into linting issues.
- Pull requests with signed commits should be created using the separate [signed commit workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions).
- Uses GitHub's built-in `GITHUB_TOKEN` for minimal-scoped auth.

---

## 🛠 Example: Custom Python Setup

```yaml
jobs:
  format:
    uses: ministryofjustice/modernisation-platform-github-actions/format-code@0442287e70970e2e732fbfecf17fd362d2d21dee
    with:
      flavor: python
      enable_linters: "PYTHON_PYLINT,MARKDOWN_MARKDOWNLINT"
      apply_fixes_mode: commit
      apply_fixes_event: all
```

---

## 🤝 Contributing

Want to improve this workflow? PRs are welcome for:

- Updated linter configurations
- Additional options or docs
- Bug fixes or enhancements

---

## 📚 Resources

- [MegaLinter Docs](https://megalinter.io/)
- [Flavors Guide](https://megalinter.io/flavors/)
- [SARIF Format](https://docs.github.com/en/code-security/code-scanning/working-with-code-scanning/sarif-support-for-code-scanning)
