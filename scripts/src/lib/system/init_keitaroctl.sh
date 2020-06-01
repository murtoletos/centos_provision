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

init_log() {
  save_previous_log
  delete_old_logs
  > ${SCRIPT_LOG}
}

create_keitaroctl_dirs_and_links() {
  if [[ "$EUID" == "$ROOT_UID" ]]; then
    mkdir -p ${INVENTORY_DIR} ${LOG_DIR} ${WORKING_DIR} ${KEITAROCTL_BIN_DIR} &&
      ln -s ${ETC_DIR} ${KEITAROCTL_CONFIG_DIR} &&
      ln -s ${LOG_DIR} ${KEITAROCTL_LOG_DIR} &&
      ln -s ${WORKING_DIR} ${KEITAROCTL_WORKING_DIR}
  else
    mkdir -p "${WORKING_DIR}"
    LOG_DIR="${WORKING_DIR}"
  fi
}

save_previous_log() {
  if [[ -f "${SCRIPT_LOG}" ]]; then
    local datetime_of_script_log=$(date -r "${SCRIPT_LOG}" +"%Y%m%d%H%M%S")
    mv "${SCRIPT_LOG}" "${LOG_DIR}/${SCRIPT_LOG}-${datetime_of_script_log}"
  fi
}

delete_old_logs() {
  for old_log in $(find "${LOG_DIR}" -name "${SCRIPT_LOG}-*" | sort | head -n-${LOGS_TO_KEEP}); do
    debug "Deleting old log ${old_log}"
    rm -f "${old_log}"
  done
}
