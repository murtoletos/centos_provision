#!/usr/bin/env bash

SHELL_NAME=$(basename "$0")

SUCCESS_RESULT=0
TRUE=0
FAILURE_RESULT=1
FALSE=1
ROOT_UID=0

KEITARO_URL="https://keitaro.io"

RELEASE_VERSION='2.12'
DEFAULT_BRANCH="master"
BRANCH="${BRANCH:-${DEFAULT_BRANCH}}"

WEBAPP_ROOT="/var/www/keitaro"

KEITAROCTL_ROOT="/opt/keitaro"
KEITAROCTL_BIN_DIR="${KEITAROCTL_ROOT}/bin"
KEITAROCTL_LOG_DIR="${KEITAROCTL_ROOT}/log"
KEITAROCTL_ETC_DIR="${KEITAROCTL_ROOT}/etc"
KEITAROCTL_WORKING_DIR="${KEITAROCTL_ROOT}/tmp"

ETC_DIR=/etc/keitaro

if [[ "$EUID" == "$ROOT_UID" ]]; then
  WORKING_DIR=/var/tmp/keitaro
  INVENTORY_DIR="${ETC_DIR}/config"
  LOG_DIR=/var/log/keitaro
else
  WORKING_DIR=".keitaro"
  INVENTORY_DIR=".keitaro"
  LOG_DIR="${WORKING_DIR}"
fi
LOG_FILENAME="${TOOL_NAME}.log"
LOG_PATH="${LOG_DIR}/${LOG_FILENAME}"

INVENTORY_PATH="${INVENTORY_DIR}/inventory"
DETECTED_INVENTORY_PATH=""

NGINX_CONFIG_ROOT="/etc/nginx"
NGINX_VHOSTS_DIR="${NGINX_CONFIG_ROOT}/conf.d"
NGINX_KEITARO_CONF="${NGINX_VHOSTS_DIR}/keitaro.conf"

SCRIPT_NAME="keitaroctl-${TOOL_NAME}"

CURRENT_COMMAND_OUTPUT_LOG="current_command.output.log"
CURRENT_COMMAND_ERROR_LOG="current_command.error.log"
CURRENT_COMMAND_SCRIPT_NAME="current_command.sh"

INDENTATION_LENGTH=2
INDENTATION_SPACES=$(printf "%${INDENTATION_LENGTH}s")

KEITAROCTL_ROOT="/opt/keitaro"
KEITAROCTL_BIN_PATH="${KEITAROCTL_ROOT}/bin"

if [[ "${TOOL_NAME}" == "install" ]]; then
  SCRIPT_URL="${KEITARO_URL}/${TOOL_NAME}.sh"
  if ! empty ${@}; then
    SCRIPT_COMMAND="curl -fsSL "$SCRIPT_URL" > run; bash run ${@}"
    TOOL_ARGS="${@}"
  else
    SCRIPT_COMMAND="curl -fsSL "$SCRIPT_URL" > run; bash run"
  fi
else
  if ! empty ${@}; then
    SCRIPT_COMMAND="${SCRIPT_NAME} ${@}"
    TOOL_ARGS="${@}"
  else
    SCRIPT_COMMAND="${SCRIPT_NAME}"
  fi
fi

declare -A VARS
declare -A ARGS
