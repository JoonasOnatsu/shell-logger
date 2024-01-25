#!/usr/bin/env bash

# ==============================================================================
# Logger for shell scripts.
# Based on 'shell-logger' project by rcmdnk (https://github.com/rcmdnk/shell-logger).
# ==============================================================================

# cSpell: disable
# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2317,SC2312,SC2155

_LOGGER_NAME="shell-logger"
_LOGGER_VERSION="v0.2.0"
_LOGGER_DATE="04/Feb/2019"

# MIT License
#
# Copyright (c) 2017 rcmdnk
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Default variables.
LOGGER_DATE_FORMAT=${LOGGER_DATE_FORMAT:-'%Y/%m/%d %H:%M:%S'}

# 0 -> debug
# 1 -> info
# 2 -> notice
# 3 -> warning
# 4 -> error
LOGGER_LEVEL=${LOGGER_LEVEL:-1}
LOGGER_STDERR_LEVEL=${LOGGER_STDERR_LEVEL:-4}
LOGGER_DEBUG_COLOR=${LOGGER_DEBUG_COLOR:-"3"}
LOGGER_INFO_COLOR=${LOGGER_INFO_COLOR:-""}
LOGGER_NOTICE_COLOR=${LOGGER_NOTICE_COLOR:-"36"}
LOGGER_WARNING_COLOR=${LOGGER_WARNING_COLOR:-"33"}
LOGGER_ERROR_COLOR=${LOGGER_ERROR_COLOR:-"31"}
LOGGER_COLOR=${LOGGER_COLOR:-auto}
LOGGER_COLORS=("${LOGGER_DEBUG_COLOR}" "${LOGGER_INFO_COLOR}" "${LOGGER_NOTICE_COLOR}" "${LOGGER_WARNING_COLOR}" "${LOGGER_ERROR_COLOR}")
if [[ ${LOGGER_LEVELS-} == "" ]]; then
  LOGGER_LEVELS=("DEBUG" "INFO" "NOTICE" "WARNING" "ERROR")
fi
LOGGER_SHOW_TIME=${LOGGER_SHOW_TIME:-true}
LOGGER_SHOW_FILE=${LOGGER_SHOW_FILE:-true}
LOGGER_SHOW_LEVEL=${LOGGER_SHOW_LEVEL:-true}
LOGGER_ERROR_RETURN_CODE=${LOGGER_ERROR_RETURN_CODE:-100}
LOGGER_ERROR_TRACE=${LOGGER_ERROR_TRACE:-true}

# Other global variables.
_LOGGER_WRAP=0

# Functions.
function _logger_version() {
  printf '%s %s %s\n' "${_LOGGER_NAME}" "${_LOGGER_VERSION}" "${_LOGGER_DATE}"
}

function _get_curr_logger_level() {
  local level=${1:-1}

  # Validate log level setting.
  if ! expr "${level}" : '[0-9]*' > /dev/null; then
    [[ -n ${ZSH_VERSION-} ]] && emulate -L ksh

    local idx=0
    while [[ ${idx} -lt ${#LOGGER_LEVELS[@]} ]]; do
      if [[ ${level} == "${LOGGER_LEVELS[${idx}]}" ]]; then
        level=${idx}
        break
      fi
      ((idx++))
    done
  fi

  printf '%s' "${level}"
}

function _logger_level_str() {
  [[ ${LOGGER_SHOW_LEVEL:-false} == false ]] && return
  local level=${1:-1}

  [[ -n ${ZSH_VERSION-} ]] && emulate -L ksh
  printf '[%s]' "${LOGGER_LEVELS[${level}]}"
}

function _logger_time_str() {
  [[ ${LOGGER_SHOW_TIME:-false} == false ]] && return
  printf '[%s]' "$(date +"${LOGGER_DATE_FORMAT}")"
}

function _logger_file_str() {
  [[ ${LOGGER_SHOW_FILE:-false} == false ]] && return
  local idx=${1:-0}

  if [[ -n ${BASH_VERSION} ]]; then
    printf '[%s]' "${BASH_SOURCE[$((idx + 1))]}:${BASH_LINENO[${idx}]}"
  elif [[ -n ${ZSH_VERSION-} ]]; then
    emulate -L ksh
    printf '[%s]' "${funcfiletrace[${idx}]}"
  fi
}

function _logger() {

  ((_LOGGER_WRAP++)) || true
  local wrap=${_LOGGER_WRAP}
  _LOGGER_WRAP=0

  [[ $# -eq 0 ]] && return
  [[ $1 -lt "$(_get_curr_logger_level "${LOGGER_LEVEL}")" ]] && return

  local level=$1
  shift

  local msg_prefix="$(_logger_time_str)$(_logger_file_str "${wrap}")$(_logger_level_str "${level}")"

  # Add prefix with a space only if prefix not is empty.
  local msg="${msg_prefix:+${msg_prefix} }$*"

  # Escape $ is msg to be able to use eval below without trying to resolve a variable.
  msg="${msg/\$/\\\$}"

  local logger_print=printf
  local logger_outfile=1

  # Output to stderr also after certain level.
  if [[ ${level} -ge ${LOGGER_STDERR_LEVEL} ]]; then
    logger_outfile=2
    logger_print=">&2 printf"
  fi

  if [[ ${LOGGER_COLOR} == "always" ]] || { [[ ${LOGGER_COLOR} == "auto" ]] && [[ -t ${logger_outfile} ]]; }; then
    [[ -n ${ZSH_VERSION-} ]] && emulate -L ksh
    eval "${logger_print} \"\\e[${LOGGER_COLORS[${level}]}m%s\\e[m\\n\"  \"${msg}\""
  else
    eval "${logger_print} \"%s\\n\" \"${msg}\""
  fi
}

function debug() {
  ((_LOGGER_WRAP++)) || true
  _logger 0 "$*"
}

function information() {
  ((_LOGGER_WRAP++)) || true
  _logger 1 "$*"
}
function info() {
  ((_LOGGER_WRAP++)) || true
  information "$*"
}

function notification() {
  ((_LOGGER_WRAP++)) || true
  _logger 2 "$*"
}
function notice() {
  ((_LOGGER_WRAP++)) || true
  notification "$*"
}

function warning() {
  ((_LOGGER_WRAP++)) || true
  _logger 3 "$*"
}
function warn() {
  ((_LOGGER_WRAP++)) || true
  warning "$*"
}

function error() {
  ((_LOGGER_WRAP++)) || true

  if [[ ${LOGGER_ERROR_TRACE:-false} == true ]]; then
    {
      local first=0
      if [[ -n ${BASH_VERSION} ]]; then
        local current_source="$(printf '%s' "${BASH_SOURCE[0]##*/}" | cut -d"." -f1)"
        local func="${FUNCNAME[1]}"
        local idx=$((${#FUNCNAME[@]} - 2))
      elif [[ -n ${ZSH_VERSION-} ]]; then
        emulate -L ksh
        local current_source="$(printf '%s' "${funcfiletrace[0]##*/}" | cut -d":" -f1 | cut -d"." -f1)"
        local func="${funcstack[1]}"
        local idx=$((${#funcstack[@]} - 1))
        local last_source="${funcfiletrace[${idx}]%:*}"
        [[ ${last_source} == "zsh" ]] && ((idx--))
      fi

      if [[ ${current_source} == "shell-logger" ]] && [[ ${func} == err ]]; then
        local first=1
      fi

      if [[ ${idx} -ge ${first} ]]; then
        printf 'Traceback (most recent call last):\n'
      fi

      while [[ ${idx} -ge ${first} ]]; do
        if [[ -n ${BASH_VERSION} ]]; then
          local file="${BASH_SOURCE[$((idx + 1))]}"
          local line="${BASH_LINENO[${idx}]}"
          local func=""

          if [[ ${BASH_LINENO[$((idx + 1))]} -ne 0 ]]; then
            if [[ ${FUNCNAME[$((idx + 1))]} == "source" ]]; then
              func=", in ${BASH_SOURCE[$((idx + 2))]}"
            else
              func=", in ${FUNCNAME[$((idx + 1))]}"
            fi
          fi

          local func_call="${FUNCNAME[${idx}]}"
          if [[ ${func_call} == "source" ]]; then
            func_call="${func_call} ${BASH_SOURCE[${idx}]}"
          else
            func_call="${func_call}()"
          fi
        elif [[ -n ${ZSH_VERSION-} ]]; then
          emulate -L ksh
          local file="${funcfiletrace[${idx}]%:*}"
          local line="${funcfiletrace[${idx}]#*:}"
          local func=""

          if [[ -n ${funcstack[$((idx + 1))]} ]]; then
            if [[ ${funcstack[$((idx + 1))]} == "${funcfiletrace[${idx}]%:*}" ]]; then
              func=", in ${funcfiletrace[$((idx + 1))]%:*}"
            else
              func=", in ${funcstack[$((idx + 1))]}"
            fi
          fi

          local func_call="${funcstack[${idx}]}"
          if [[ ${func_call} == "${funcfiletrace[$((idx - 1))]%:*}" ]]; then
            func_call="source ${funcfiletrace[$((idx - 1))]%:*}"
          else
            func_call="${func_call}()"
          fi
        fi

        printf '  File \"%s\", line %s%s\n' "${file}" "${line}" "${func}"

        if [[ ${idx} -gt ${first} ]]; then
          printf '    %s\n' "${func_call}"
        else
          printf '\n'
        fi

        ((idx--))
      done
    } 1>&2
  fi
  _logger 4 "$*"

  return "${LOGGER_ERROR_RETURN_CODE}"
}
function err() {
  ((_LOGGER_WRAP++)) || true
  error "$*"
}
