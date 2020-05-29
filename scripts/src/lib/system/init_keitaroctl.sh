#!/usr/bin/env bash

init_keitaroctl() {
  if [[ ! -d ${KEITAROCTL_ROOT} ]]; then
    if ! create_keitaroctl_dirs_and_links; then
      echo "Can't create keitaro directories" >&2
      exit 1
    fi
  fi
}

init_keitaroctl_dirs_and_links() {
  if [[ "$EUID" == "$ROOT_UID" ]]; then
    mkdir -p ${INVENTORY_DIR} ${LOG_DIR} ${WORKING_DIR} ${KEITAROCTL_BIN_DIR} &&
      ln -s ${ETC_DIR} ${KEITAROCTL_CONFIG_DIR} &&
      ln -s ${LOG_DIR} ${KEITAROCTL_LOG_DIR} &&
      ln -s ${WORKING_DIR} ${KEITAROCTL_WORKING_DIR}
  else
    echo "Skip creating dirs"
  fi
}