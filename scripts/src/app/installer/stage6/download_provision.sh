#!/usr/bin/env bash

download_provision(){
  debug "Download provision"
  release_url="https://github.com/apliteni/centos_provision/archive/${BRANCH}.tar.gz"
  curl -fsSL https://github.com/apliteni/centos_provision/archive/INST-189.tar.gz | tar xz
  curl -fsSL https://files.keitaro.io/scripts/builds/INST-189/playbook.zip | tar xz
  run_command "curl -fsSLO ${release_url} | unzip"
}
