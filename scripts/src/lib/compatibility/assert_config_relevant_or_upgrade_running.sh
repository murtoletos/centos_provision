#!/usr/bin/env bash


assert_config_relevant_or_upgrade_running(){
  debug 'Ensure configs has been genereated by relevant installer'
  if isset "$SKIP_CHECKS"; then
    debug "SKIP: actual check of installer version in ${INVENTORY_PATH} disabled"
  else
    installed_version=$(detect_installed_version)
    if [[ "${RELEASE_VERSION}" == "${installed_version}" ]]; then
      debug "Configs has been generated by recent version of installer ${RELEASE_VERSION}"
    elif [[ "${ANSIBLE_TAGS}" =~ upgrade ]]; then
      debug "Upgrade mode detected. Upgrading ${installed_version} -> ${RELEASE_VERSION}"
    else
      fail "$(translate 'errors.upgrade_server')"
    fi
  fi
}
