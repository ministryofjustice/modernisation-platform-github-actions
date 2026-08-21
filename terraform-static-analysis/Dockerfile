FROM golang:1.27rc3-bookworm

#Install Checkov
RUN apt-get update && apt-get install -y \
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
RUN pip install --upgrade pip setuptools \
 && pip install -r /requirements.txt

#Install tflint
RUN curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

COPY entrypoint.sh /entrypoint.sh
COPY tflint-configs /tflint-configs
ENTRYPOINT ["/entrypoint.sh"]
