#!/usr/bin/env bash

stage1(){
  debug "Starting stage 1: initial script setup"
  setup_vars
  parse_options "$@"
  set_ui_lang
}
