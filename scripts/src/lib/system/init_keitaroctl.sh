#!/usr/bin/env bash

LOGS_TO_KEEP=10

init_keitaroctl() {
  init_keitaroctl_dirs_and_links
  init_log
}

init_keitaroctl_dirs_and_links() {
  if [[ ! -d ${KEITAROCTL_ROOT} ]]; then
    if ! create_keitaroctl_dirs_and_links; then
      echo "Can't create keitaro directories" >&2
      exit 1
    fi
  fi
}

create_keitaroctl_dirs_and_links() {
  if [[ "$EUID" == "$ROOT_UID" ]]; then
    mkdir -p ${WORKING_DIR} ${LOG_DIR} ${INVENTORY_DIR} ${KEITAROCTL_BIN_DIR} &&
      ln -s ${ETC_DIR} ${KEITAROCTL_ETC_DIR} &&
      ln -s ${LOG_DIR} ${KEITAROCTL_LOG_DIR} &&
      ln -s ${WORKING_DIR} ${KEITAROCTL_WORKING_DIR}
  else
    mkdir -p ${WORKING_DIR} ${LOG_DIR}
  fi
}

init_log() {
  save_previous_log
  delete_old_logs
  create_log
}

save_previous_log() {
  if [[ -f "${LOG_PATH}" ]]; then
    local log_timestamp=$(date -r "${LOG_PATH}" +"%Y%m%d%H%M%S")
    mv "${LOG_PATH}" "${LOG_PATH}-${log_timestamp}"
  fi
}

delete_old_logs() {
  find "${LOG_DIR}" -name "${LOG_FILENAME}-*" | sort | head -n -${LOGS_TO_KEEP} | xargs rm -f
}

create_log() {
  > ${LOG_PATH}
}