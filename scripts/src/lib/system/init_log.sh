#!/usr/bin/env bash

LOGS_TO_KEEP=10

init_log() {
  save_previous_log
  delete_old_logs
  > ${SCRIPT_LOG}
}

save_previous_log() {
  if [[ -f "${SCRIPT_LOG}" ]]; then
    local datetime_of_script_log=$(date -r "${SCRIPT_LOG}" +"%Y%m%d%H%M%S")
    mv "${SCRIPT_LOG}" "${WORKING_DIR}/${SCRIPT_LOG}-${datetime_of_script_log}"
  fi
}

delete_old_logs() {
  for old_log in $(find "${WORKING_DIR}" -name "${SCRIPT_LOG}-*" | sort | head -n-${LOGS_TO_KEEP}); do
    debug "Deleting old log ${old_log}"
    rm -f "${old_log}"
  done
}
