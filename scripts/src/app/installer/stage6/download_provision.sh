#!/usr/bin/env bash

download_provision(){
  debug "Download playbook.zip"

  url="${PLAYBOOK_URL:-$DEFAULT_PLAYBOOK_URL}"
  run_command "curl -fsSL ${url} && unzip -qo playbook.zip && ls"
}
