#!/bin/bash

echo
echo "Passed in vars"
echo "INPUT_SCAN_TYPE: $INPUT_SCAN_TYPE"
echo "INPUT_COMMENT_ON_PR: $INPUT_COMMENT_ON_PR"
echo "INPUT_TERRAFORM_WORKING_DIR: $INPUT_TERRAFORM_WORKING_DIR"
echo "INPUT_TFSEC_EXCLUDE: $INPUT_TFSEC_EXCLUDE"
echo "INPUT_TFSEC_VERSION: $INPUT_TFSEC_VERSION"
echo "INPUT_TFSEC_OUTPUT_FORMAT: $INPUT_TFSEC_OUTPUT_FORMAT"
echo "INPUT_TFSEC_OUTPUT_FILE: $INPUT_TFSEC_OUTPUT_FILE"
echo "INPUT_CHECKOV_EXCLUDE: $INPUT_CHECKOV_EXCLUDE"
echo "INPUT_CHECKOV_EXTERNAL_MODULES: $INPUT_CHECKOV_EXTERNAL_MODULES"
echo "INPUT_TFLINT_EXCLUDE: $INPUT_TFLINT_EXCLUDE"
echo "INPUT_TFLINT_CONFIG: $INPUT_TFLINT_CONFIG"
echo "INPUT_TFLINT_CALL_MODULE_TYPE: $INPUT_TFLINT_CALL_MODULE_TYPE"
echo "INPUT_TRIVY_VERSION: $INPUT_TRIVY_VERSION"
echo "INPUT_TRIVY_IGNORE: $INPUT_TRIVY_IGNORE"
echo "INPUT_TRIVY_SEVERITY: $INPUT_TRIVY_SEVERITY"
echo "INPUT_TFSEC_TRIVY: $INPUT_TFSEC_TRIVY"
echo "INPUT_TRIVY_SKIP_DIR: $INPUT_TRIVY_SKIP_DIR"
echo "INPUT_MAIN_BRANCH_NAME: $INPUT_MAIN_BRANCH_NAME"
echo "INPUT_USE_TRIVY_ECR_DATABASE: $INPUT_USE_TRIVY_ECR_DATABASE"
echo

# install tfsec from GitHub (taken from README.md)
if [[ -n "$INPUT_TFSEC_VERSION" && "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
  env GO111MODULE=on go install github.com/aquasecurity/tfsec/cmd/tfsec@"${INPUT_TFSEC_VERSION}"
else
  env GO111MODULE=on go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
fi

# install trivy from github (taken from docs install guide)
if [[ -n "$INPUT_TRIVY_VERSION" && "${INPUT_TFSEC_TRIVY}" == "trivy" ]]; then
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin "${INPUT_TRIVY_VERSION}"
else
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin latest
fi

# use ECR for Trivy databases
if [[ "$INPUT_USE_TRIVY_ECR_DATABASE" == "true" ]]; then
  export TRIVY_DB_REPOSITORY="public.ecr.aws/aquasecurity/trivy-db:2"
  export TRIVY_JAVA_DB_REPOSITORY="public.ecr.aws/aquasecurity/trivy-java-db:1"
fi

line_break() {
  echo
  echo "*****************************"
  echo
}

declare -i tfsec_exitcode=0
declare -i checkov_exitcode=0
declare -i tflint_exitcode=0
declare -i trivy_exitcode=0

# see https://github.com/actions/runner/issues/2033
git config --global --add safe.directory "$GITHUB_WORKSPACE"

# Identify which Terraform folders have changes and need scanning
tf_folders_with_changes=$(git diff --name-only HEAD.."origin/${INPUT_MAIN_BRANCH_NAME}" | awk '{print $1}' | grep '\.tf' | sed 's#/[^/]*$##' | grep -v '\.tf' | uniq)
echo
echo "TF folders with changes"
echo "$tf_folders_with_changes"

# Get a list of all terraform folders in the repo
all_tf_folders=$(find . -type f -name '*.tf' | sed 's#/[^/]*$##' | sed 's/.\///' | sort | uniq)
echo
echo "All TF folders"
echo "$all_tf_folders"

run_trivy() {
  line_break
  echo "Trivy will check the following folders:"
  echo "$1"

  directories=($1)
  for directory in ${directories[@]}; do
    line_break
    echo "Running Trivy in ${directory}"
    terraform_working_dir="${GITHUB_WORKSPACE}/${directory}"

    if [[ "${directory}" != *"templates"* && -d "${terraform_working_dir}" ]]; then
      trivy fs --scanners vuln,misconfig,secret --exit-code 1 \
        --no-progress --ignorefile "${INPUT_TRIVY_IGNORE}" \
        --severity "${INPUT_TRIVY_SEVERITY}" \
        "${terraform_working_dir}"
      trivy_exitcode+=$?
    else
      echo "Skipping folder ${directory}"
    fi
  done
  return $trivy_exitcode
}

run_tfsec() {
  line_break
  echo "TFSEC will check the following folders:"
  echo "$1"

  directories=($1)
  for directory in ${directories[@]}; do
    line_break
    echo "Running TFSEC in ${directory}"
    terraform_working_dir="${GITHUB_WORKSPACE}/${directory}"

    if [[ "${directory}" != *"templates"* && -d "${terraform_working_dir}" ]]; then
      if [[ -n "$INPUT_TFSEC_EXCLUDE" ]]; then
        /go/bin/tfsec "${terraform_working_dir}" --no-colour -e "${INPUT_TFSEC_EXCLUDE}" \
          ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} \
          ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"}
      else
        /go/bin/tfsec "${terraform_working_dir}" --no-colour \
          ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} \
          ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"}
      fi
      tfsec_exitcode+=$?
    else
      echo "Skipping folder ${directory}"
    fi
  done
  return $tfsec_exitcode
}

run_checkov() {
  line_break
  echo "Checkov will check the following folders:"
  echo "$1"

  directories=($1)
  for directory in ${directories[@]}; do
    line_break
    echo "Running Checkov in ${directory}"
    terraform_working_dir="${GITHUB_WORKSPACE}/${directory}"

    if [[ "${directory}" != *"templates"* && -d "${terraform_working_dir}" ]]; then
      if [[ -n "$INPUT_CHECKOV_EXCLUDE" ]]; then
        checkov --quiet -d "$terraform_working_dir" --skip-check "${INPUT_CHECKOV_EXCLUDE}" \
          --download-external-modules "${INPUT_CHECKOV_EXTERNAL_MODULES}"
      else
        checkov --quiet -d "$terraform_working_dir" \
          --download-external-modules "${INPUT_CHECKOV_EXTERNAL_MODULES}"
      fi
      checkov_exitcode+=$?
    else
      echo "Skipping folder ${directory}"
    fi
  done
  return $checkov_exitcode
}

run_tflint() {
  line_break

  if [[ -n $INPUT_TFLINT_CONFIG ]]; then
    echo "Setting custom config ${INPUT_TFLINT_CONFIG}"
    tflint_config="/tflint-configs/${INPUT_TFLINT_CONFIG}"
  else
    echo "Using default config"
    tflint_config="/tflint-configs/tflint.default.hcl"
  fi

  tflint --init --config "$tflint_config"

  echo "tflint checking:"
  echo "$1"

  directories=($1)
  for directory in ${directories[@]}; do
    line_break
    echo "Running tflint in ${directory}"
    terraform_working_dir="${GITHUB_WORKSPACE}/${directory}"

    if [[ "${directory}" != *"templates"* && -d "${terraform_working_dir}" ]]; then
      if [[ -n "$INPUT_TFLINT_EXCLUDE" ]]; then
        readarray -d , -t tflint_exclusions <<<"$INPUT_TFLINT_EXCLUDE"
        tflint_exclusions_list=("${tflint_exclusions[@]/#/--disable-rule=}")
        tflint --config "$tflint_config" \
          ${tflint_exclusions_list[@]} \
          --chdir "${terraform_working_dir}" \
          --call-module-type "${INPUT_TFLINT_CALL_MODULE_TYPE}"
      else
        tflint --config "$tflint_config" \
          --chdir "${terraform_working_dir}" \
          --call-module-type "${INPUT_TFLINT_CALL_MODULE_TYPE}"
      fi
    else
      echo "Skipping folder ${directory}"
    fi
    tflint_exitcode+=$?
  done
  return $tflint_exitcode
}

### SCAN TYPE
case ${INPUT_SCAN_TYPE} in
full)
  [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]] && TFSEC_OUTPUT=$(run_tfsec "${all_tf_folders}")
  [[ "${INPUT_TFSEC_TRIVY}" == "trivy" ]] && TRIVY_OUTPUT=$(run_trivy "${all_tf_folders}")
  CHECKOV_OUTPUT=$(run_checkov "${all_tf_folders}")
  TFLINT_OUTPUT=$(run_tflint "${all_tf_folders}")
  ;;
changed)
  [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]] && TFSEC_OUTPUT=$(run_tfsec "${tf_folders_with_changes}")
  [[ "${INPUT_TFSEC_TRIVY}" == "trivy" ]] && TRIVY_OUTPUT=$(run_trivy "${tf_folders_with_changes}")
  CHECKOV_OUTPUT=$(run_checkov "${tf_folders_with_changes}")
  TFLINT_OUTPUT=$(run_tflint "${tf_folders_with_changes}")
  ;;
*)
  [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]] && TFSEC_OUTPUT=$(run_tfsec "${INPUT_TERRAFORM_WORKING_DIR}")
  [[ "${INPUT_TFSEC_TRIVY}" == "trivy" ]] && TRIVY_OUTPUT=$(run_trivy "${INPUT_TERRAFORM_WORKING_DIR}")
  CHECKOV_OUTPUT=$(run_checkov "${INPUT_TERRAFORM_WORKING_DIR}")
  TFLINT_OUTPUT=$(run_tflint "${INPUT_TERRAFORM_WORKING_DIR}")
  ;;
esac

### DETERMINE STATUSES
[[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]] && TFSEC_STATUS=$([[ $tfsec_exitcode -eq 0 ]] && echo "Success" || echo "Failed")
[[ "${INPUT_TFSEC_TRIVY}" == "trivy" ]] && TRIVY_STATUS=$([[ $trivy_exitcode -eq 0 ]] && echo "Success" || echo "Failed")

CHECKOV_STATUS=$([[ $checkov_exitcode -eq 0 ]] && echo "Success" || echo "Failed")
TFLINT_STATUS=$([[ $tflint_exitcode -eq 0 ]] && echo "Success" || echo "Failed")

### OUTPUT CLEANUP FUNCTION
clean_output() {
  echo "$1" \
    | sed 's/\x1b\[[0-9;]*m//g' \
    | sed 's/[[:blank:]]*$//' \
    | sed 's/\r//'
}

TFSEC_CLEAN=$(clean_output "${TFSEC_OUTPUT}")
TRIVY_CLEAN=$(clean_output "${TRIVY_OUTPUT}")
CHECKOV_CLEAN=$(clean_output "${CHECKOV_OUTPUT}")
TFLINT_CLEAN=$(clean_output "${TFLINT_OUTPUT}")

### PR COMMENT HEADER MARKER
COMMENT_HEADER="<!-- terraform-static-analysis-comment -->"

### BUILD COMMENT BLOCK
if [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
  TOOL_BLOCK="#### \`TFSEC Scan\` ${TFSEC_STATUS}
<details><summary>Show Output</summary>

\`\`\`hcl
${TFSEC_CLEAN}
\`\`\`

</details>"
else
  TOOL_BLOCK="#### \`Trivy Scan\` ${TRIVY_STATUS}
<details><summary>Show Output</summary>

\`\`\`hcl
${TRIVY_CLEAN}
\`\`\`

</details>"
fi

PAYLOAD_COMMENT="${COMMENT_HEADER}

${TOOL_BLOCK}

---

#### \`Checkov Scan\` ${CHECKOV_STATUS}
<details><summary>Show Output</summary>

\`\`\`hcl
${CHECKOV_CLEAN}
\`\`\`

</details>

---

#### \`TFLint Scan\` ${TFLINT_STATUS}
<details><summary>Show Output</summary>

\`\`\`hcl
${TFLINT_CLEAN}
\`\`\`

</details>
"

### POST COMMENT TO PR
if [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then

  COMMENTS_URL=$(jq -r .pull_request.comments_url "${GITHUB_EVENT_PATH}")
  EXISTING_COMMENTS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$COMMENTS_URL")

  EXISTING_COMMENT_ID=$(echo "$EXISTING_COMMENTS" | jq -r \
    ".[] | select(.body | contains(\"${COMMENT_HEADER}\")) | .id")

  # Delete old comment
  if [[ -n "$EXISTING_COMMENT_ID" && "$EXISTING_COMMENT_ID" != "null" ]]; then
    curl -s -S \
      -X DELETE \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/comments/${EXISTING_COMMENT_ID}" \
      >/dev/null
  fi

  # Create fresh comment
  PAYLOAD_JSON=$(echo "${PAYLOAD_COMMENT}" | jq -R --slurp '{body: .}')
  echo "${PAYLOAD_JSON}" |
    curl -s -S \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      --header "Content-Type: application/json" \
      --data @- \
      "${COMMENTS_URL}" >/dev/null
fi

### EXIT CODE
echo "TFSEC exit: $tfsec_exitcode"
echo "Checkov exit: $checkov_exitcode"
echo "TFLint exit: $tflint_exitcode"
echo "Trivy exit: $trivy_exitcode"

if [ $tfsec_exitcode -gt 0 ] || [ $checkov_exitcode -gt 0 ] || [ $tflint_exitcode -gt 0 ] || [ $trivy_exitcode -gt 0 ]; then
  exit 1
else
  exit 0
fi
