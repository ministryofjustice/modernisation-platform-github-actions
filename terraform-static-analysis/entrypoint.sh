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

# install tfsec from GitHub
if [[ -n "$INPUT_TFSEC_VERSION" && "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
  env GO111MODULE=on go install github.com/aquasecurity/tfsec/cmd/tfsec@"${INPUT_TFSEC_VERSION}"
else
  env GO111MODULE=on go install github.com/aquasecurity/tfsec/cmd/tfsec@latest
fi

# install trivy from github
if [[ -n "$INPUT_TRIVY_VERSION" && "${INPUT_TFSEC_TRIVY}" == "trivy" ]]; then
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin "${INPUT_TRIVY_VERSION}"
else
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin latest
fi

# use ECR for Trivy DBs
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

git config --global --add safe.directory "$GITHUB_WORKSPACE"

tf_folders_with_changes=$(git diff --name-only HEAD.."origin/${INPUT_MAIN_BRANCH_NAME}" | awk '{print $1}' | grep '\.tf' | sed 's#/[^/]*$##' | grep -v '\.tf' | uniq)
echo
echo "TF folders with changes"
echo "$tf_folders_with_changes"

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
    if [[ "${directory}" != *"templates"* ]]; then
      if [ -d "${terraform_working_dir}" ]; then
        trivy fs --scanners vuln,misconfig,secret --exit-code 1 --no-progress --ignorefile "${INPUT_TRIVY_IGNORE}" --severity "${INPUT_TRIVY_SEVERITY}" "${terraform_working_dir}" 2>&1
        trivy_exitcode+=$?
        echo "trivy_exitcode=${trivy_exitcode}"
      else
        echo "Skipping folder ${directory} as it does not exist."
      fi
    else
      echo "Skipping folder as path name contains *templates*"
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
    if [[ "${directory}" != *"templates"* ]]; then
      if [ -d "${terraform_working_dir}" ]; then
        if [[ -n "$INPUT_TFSEC_EXCLUDE" ]]; then
          echo "Excluding checks: ${INPUT_TFSEC_EXCLUDE}"
          /go/bin/tfsec "${terraform_working_dir}" --no-colour -e "${INPUT_TFSEC_EXCLUDE}" ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"} 2>&1
        else
          /go/bin/tfsec "${terraform_working_dir}" --no-colour ${INPUT_TFSEC_OUTPUT_FORMAT:+ -f "$INPUT_TFSEC_OUTPUT_FORMAT"} ${INPUT_TFSEC_OUTPUT_FILE:+ --out "$INPUT_TFSEC_OUTPUT_FILE"} 2>&1
        fi
        tfsec_exitcode+=$?
        echo "tfsec_exitcode=${tfsec_exitcode}"
      else
        echo "Skipping folder ${directory} as it does not exist."
      fi
    else
      echo "Skipping folder as path name contains *templates*"
    fi
  done
  return $tfsec_exitcode
}

run_checkov() {
  line_break
  echo "Checkov will check folders:"
  echo "$1"
  directories=($1)
  for directory in ${directories[@]}; do
    line_break
    echo "Running Checkov in ${directory}"
    terraform_working_dir="${GITHUB_WORKSPACE}/${directory}"
    if [[ "${directory}" != *"templates"* ]]; then
      if [ -d "${terraform_working_dir}" ]; then
        if [[ -n "$INPUT_CHECKOV_EXCLUDE" ]]; then
          checkov -d "$terraform_working_dir" --quiet --skip-check "${INPUT_CHECKOV_EXCLUDE}" --download-external-modules "${INPUT_CHECKOV_EXTERNAL_MODULES}" 2>&1
        else
          checkov -d "$terraform_working_dir" --quiet --download-external-modules "${INPUT_CHECKOV_EXTERNAL_MODULES}" 2>&1
        fi
        checkov_exitcode+=$?
        echo "checkov_exitcode=${checkov_exitcode}"
      else
        echo "Skipping ${directory}"
      fi
    else
      echo "Skipping folder containing *templates*"
    fi
  done
  return $checkov_exitcode
}

run_tflint() {
  line_break
  if [[ -n $INPUT_TFLINT_CONFIG ]]; then
    echo "Using custom tflint config: ${INPUT_TFLINT_CONFIG}"
    tflint_config="/tflint-configs/${INPUT_TFLINT_CONFIG}"
  else
    echo "Using default tflint config"
    tflint_config="/tflint-configs/tflint.default.hcl"
  fi

  echo "Running tflint --init"
  tflint --init --config "$tflint_config"

  echo "tflint will check folders:"
  echo "$1"
  directories=($1)

  for directory in ${directories[@]}; do
    line_break
    echo "Running tflint in ${directory}"
    terraform_working_dir="${GITHUB_WORKSPACE}/${directory}"

    if [[ "${directory}" != *"templates"* ]]; then
      if [ -d "${terraform_working_dir}" ]; then
        if [[ -n "$INPUT_TFLINT_EXCLUDE" ]]; then
          readarray -d , -t tflint_exclusions <<<"$INPUT_TFLINT_EXCLUDE"
          tflint_exclusions_list=("${tflint_exclusions[@]/#/--disable-rule=}")

          tflint --config "$tflint_config" ${tflint_exclusions_list[@]} \
            --chdir "${terraform_working_dir}" \
            --call-module-type "${INPUT_TFLINT_CALL_MODULE_TYPE}" 2>&1
        else
          tflint --config "$tflint_config" \
            --chdir "${terraform_working_dir}" \
            --call-module-type "${INPUT_TFLINT_CALL_MODULE_TYPE}" 2>&1
        fi
      else
        echo "Skipping folder ${directory}"
      fi
    else
      echo "Skipping folder containing *templates*"
    fi

    tflint_exitcode+=$?
    echo "tflint_exitcode=${tflint_exitcode}"
  done

  return $tflint_exitcode
}

case ${INPUT_SCAN_TYPE} in

full)
  line_break
  echo "Starting full scan"
  if [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
    TFSEC_OUTPUT=$(run_tfsec "${all_tf_folders}")
    tfsec_exitcode=$?
  else
    TRIVY_OUTPUT=$(run_trivy "${all_tf_folders}")
    trivy_exitcode=$?
  fi
  CHECKOV_OUTPUT=$(run_checkov "${all_tf_folders}")
  checkov_exitcode=$?
  TFLINT_OUTPUT=$(run_tflint "${all_tf_folders}")
  tflint_exitcode=$?
  ;;

changed)
  line_break
  echo "Starting scan of changed folders"
  if [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
    TFSEC_OUTPUT=$(run_tfsec "${tf_folders_with_changes}")
    tfsec_exitcode=$?
  else
    TRIVY_OUTPUT=$(run_trivy "${tf_folders_with_changes}")
    trivy_exitcode=$?
  fi
  CHECKOV_OUTPUT=$(run_checkov "${tf_folders_with_changes}")
  checkov_exitcode=$?
  TFLINT_OUTPUT=$(run_tflint "${tf_folders_with_changes}")
  tflint_exitcode=$?
  ;;
*)
  line_break
  echo "Starting single folder scan"
  if [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
    TFSEC_OUTPUT=$(run_tfsec "${INPUT_TERRAFORM_WORKING_DIR}")
    tfsec_exitcode=$?
  else
    TRIVY_OUTPUT=$(run_trivy "${INPUT_TERRAFORM_WORKING_DIR}")
    trivy_exitcode=$?
  fi
  CHECKOV_OUTPUT=$(run_checkov "${INPUT_TERRAFORM_WORKING_DIR}")
  checkov_exitcode=$?
  TFLINT_OUTPUT=$(run_tflint "${INPUT_TERRAFORM_WORKING_DIR}")
  tflint_exitcode=$?
  ;;
esac

# Determine statuses
if [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
  TFSEC_STATUS=$([[ $tfsec_exitcode -eq 0 ]] && echo "Success" || echo "Failed")
else
  TRIVY_STATUS=$([[ $trivy_exitcode -eq 0 ]] && echo "Success" || echo "Failed")
fi
CHECKOV_STATUS=$([[ $checkov_exitcode -eq 0 ]] && echo "Success" || echo "Failed")
TFLINT_STATUS=$([[ $tflint_exitcode -eq 0 ]] && echo "Success" || echo "Failed")

#
# 🔥🔥🔥 FIXED: REPLACE DUPLICATE COMMENT CREATION WITH UPSERT LOGIC 🔥🔥🔥
#

if [ "${INPUT_COMMENT_ON_PR}" == "1" ] || [ "${INPUT_COMMENT_ON_PR}" == "true" ]; then
  COMMENT=1
else
  COMMENT=0
fi

if [ "${GITHUB_EVENT_NAME}" == "pull_request" ] && [ -n "${GITHUB_TOKEN}" ] && [ "${COMMENT}" == "1" ]; then

  COMMENT_HEADER="<!-- terraform-static-analysis-comment -->"

  if [[ "${INPUT_TFSEC_TRIVY}" == "tfsec" ]]; then
    INPUT_TFSEC_TRIVY_COMMENT="#### \`TFSEC Scan\` ${TFSEC_STATUS}
<details><summary>Show Output</summary>
\`\`\`hcl
${TFSEC_OUTPUT}
\`\`\`
</details>"
  else
    INPUT_TFSEC_TRIVY_COMMENT="#### \`Trivy Scan\` ${TRIVY_STATUS}
<details><summary>Show Output</summary>
\`\`\`hcl
${TRIVY_OUTPUT}
\`\`\`
</details>"
  fi

  PAYLOAD_COMMENT="${COMMENT_HEADER}
${INPUT_TFSEC_TRIVY_COMMENT}

#### \`Checkov Scan\` ${CHECKOV_STATUS}
<details><summary>Show Output</summary>
\`\`\`hcl
${CHECKOV_OUTPUT}
\`\`\`
</details>

#### \`CTFLint Scan\` ${TFLINT_STATUS}
<details><summary>Show Output</summary>
\`\`\`hcl
${TFLINT_OUTPUT}
\`\`\`
</details>

#### \`Trivy Scan\` ${TRIVY_STATUS}
<details><summary>Show Output</summary>
\`\`\`hcl
${TRIVY_OUTPUT}
\`\`\`
</details>
"

  PAYLOAD_JSON=$(echo "${PAYLOAD_COMMENT}" | jq -R --slurp '{body: .}')
  COMMENTS_URL=$(jq -r .pull_request.comments_url "${GITHUB_EVENT_PATH}")

  EXISTING_COMMENTS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "$COMMENTS_URL")

  EXISTING_COMMENT_ID=$(echo "$EXISTING_COMMENTS" | jq -r \
    ".[] | select(.body | contains(\"${COMMENT_HEADER}\")) | .id")

  if [[ -n "$EXISTING_COMMENT_ID" && "$EXISTING_COMMENT_ID" != "null" ]]; then
    echo "Updating existing PR comment: $EXISTING_COMMENT_ID"

    curl -s -S \
      -X PATCH \
      -H "Authorization: token ${GITHUB_TOKEN}" \
      --header "Content-Type: application/json" \
      --data "${PAYLOAD_JSON}" \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/comments/${EXISTING_COMMENT_ID}" \
      >/dev/null

  else
    echo "Creating new PR comment"

    echo "${PAYLOAD_JSON}" |
      curl -s -S \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        --header "Content-Type: application/json" \
        --data @- \
        "${COMMENTS_URL}" \
        >/dev/null
  fi
fi

line_break
echo "TFSEC exit codes: $tfsec_exitcode"
echo "Trivy exit codes: $trivy_exitcode"
echo "Checkov exit codes: $checkov_exitcode"
echo "tflint exit codes: $tflint_exitcode"

if [ $tfsec_exitcode -gt 0 ] || [ $checkov_exitcode -gt 0 ] || [ $tflint_exitcode -gt 0 ] || [ $trivy_exitcode -gt 0 ]; then
  echo "Exiting with error(s)"
  exit 1
else
  echo "Exiting with no error"
  exit 0
fi
