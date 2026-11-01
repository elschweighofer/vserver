#!/usr/bin/env bash
# CI entry point, written in plain shell so no third-party actions are needed.
#
#   terraform.sh install   download and verify the pinned Terraform
#   terraform.sh validate  format and config checks, no credentials or infra
#   terraform.sh plan      read-only plan, never changes infra or takes a lock
#   terraform.sh apply     apply, then fail if anything is still out of sync
set -euo pipefail

TF_VERSION="1.17.1"
TF_SHA256="4638628058e71a55212b1c563712eac03b902128f40740f3dc8174df12135061" # linux_amd64

export TF_IN_AUTOMATION=1
export TF_INPUT=0

install() {
  local dir zip="terraform_${TF_VERSION}_linux_amd64.zip"
  dir="$(mktemp -d)"
  curl -fsSL --retry 3 -o "$dir/$zip" \
    "https://releases.hashicorp.com/terraform/${TF_VERSION}/${zip}"
  echo "$TF_SHA256  $dir/$zip" | sha256sum --check --strict
  unzip -q "$dir/$zip" terraform -d "$dir"
  echo "$dir" >>"$GITHUB_PATH"
  "$dir/terraform" version
}

validate() {
  terraform fmt -check -recursive -diff
  terraform init -backend=false
  terraform validate
}

plan() {
  terraform init
  terraform plan -lock=false
}

apply() {
  terraform init
  terraform plan -out=tfplan
  terraform apply tfplan
  terraform plan -detailed-exitcode
}

case "${1:-}" in
  install | validate | plan | apply) "$1" ;;
  *)
    echo "usage: $0 {install|validate|plan|apply}" >&2
    exit 2
    ;;
esac
