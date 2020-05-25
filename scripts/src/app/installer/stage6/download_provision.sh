#!/usr/bin/env bash

download_provision(){
  debug "Download playbook.zip"

  run_command "yum install -y unzip"

  url="${PLAYBOOK_URL:-$DEFAULT_PLAYBOOK_URL}"
  run_command "curl -fsSL ${url} > playbook.zip && unzip -qo playbook.zip && rm playbook.zip"
}
