FROM golang:1.27-bookworm

#Install Checkov
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv \
  git \
  jq \
  unzip \
  && rm -rf /var/lib/apt/lists/*

# Create an isolated virtualenv so pip installs don't hit PEP 668
# ("externally-managed-environment") on Debian 12 / bookworm.
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Guard: fail the build early if the base image ever ships < Python 3.10.
RUN python --version \
 && python -c 'import sys; assert sys.version_info >= (3, 10), f"Python 3.10+ required, got {sys.version}"'

COPY requirements.txt /requirements.txt
# hadolint ignore=DL3013
RUN pip install --no-cache-dir --upgrade pip setuptools \
 && pip install --no-cache-dir -r /requirements.txt

#Install tflint
# install_linux.sh was removed upstream (terraform-linters/tflint#2607); install a pinned release binary instead.
ARG TFLINT_VERSION=v0.64.0
RUN curl -sSLo /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip" \
 && unzip /tmp/tflint.zip -d /usr/local/bin \
 && rm /tmp/tflint.zip

COPY entrypoint.sh /entrypoint.sh
COPY tflint-configs /tflint-configs

# hadolint ignore=DL3066
RUN useradd --create-home --shell /usr/sbin/nologin scanner
# hadolint ignore=DL3066
USER scanner

ENTRYPOINT ["/entrypoint.sh"]
