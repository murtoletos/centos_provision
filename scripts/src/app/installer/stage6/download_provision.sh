#!/usr/bin/env bash

download_provision(){
  debug "Download provision"
  release_url="https://files.keitaro.io/scripts/${BRANCH}/playbook.tar.gz"
  run_command "curl -fsSL ${release_url} | tar xz"
}
