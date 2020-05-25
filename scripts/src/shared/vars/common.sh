#!/usr/bin/env bash

SHELL_NAME=$(basename "$0")

SUCCESS_RESULT=0
TRUE=0
FAILURE_RESULT=1
FALSE=1
ROOT_UID=0

KEITARO_URL="https://keitaro.io"

RELEASE_VERSION='dev'
BRANCH="${BRANCH:-master}"
DEFAULT_PLAYBOOK_URL="https://files.keitaro.io/scripts/latest/playbook.zip"
LATEST_RELEASE_VERSION_URL="https://files.keitaro.io/scripts/latest/VERSION"

WEBROOT_PATH="/var/www/keitaro"

if [[ "$EUID" == "$ROOT_UID" ]]; then
  WORKING_DIR="${HOME}/.keitaro"
  INVENTORY_DIR="/etc/keitaro/config"
else
  WORKING_DIR=".keitaro"
  INVENTORY_DIR=".keitaro"
fi

INVENTORY_PATH="${INVENTORY_DIR}/inventory"
DETECTED_INVENTORY_PATH=""

NGINX_ROOT_PATH="/etc/nginx"
NGINX_VHOSTS_DIR="${NGINX_ROOT_PATH}/conf.d"
NGINX_KEITARO_CONF="${NGINX_VHOSTS_DIR}/keitaro.conf"

SCRIPT_NAME="${TOOL_NAME}.sh"
SCRIPT_URL="${KEITARO_URL}/${TOOL_NAME}.sh"
SCRIPT_LOG="${TOOL_NAME}.log"

CURRENT_COMMAND_OUTPUT_LOG="current_command.output.log"
CURRENT_COMMAND_ERROR_LOG="current_command.error.log"
CURRENT_COMMAND_SCRIPT_NAME="current_command.sh"

INDENTATION_LENGTH=2
INDENTATION_SPACES=$(printf "%${INDENTATION_LENGTH}s")

if ! empty ${@}; then
  SCRIPT_COMMAND="curl -fsSL "$SCRIPT_URL" > run; bash run ${@}"
  TOOL_ARGS="${@}"
else
  SCRIPT_COMMAND="curl -fsSL "$SCRIPT_URL" > run; bash run"
fi

declare -A VARS
declare -A ARGS
