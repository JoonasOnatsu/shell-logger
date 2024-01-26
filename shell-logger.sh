#!/usr/bin/env bash

# ==============================================================================
# Logger for shell scripts.
# Based on 'shell-logger' project by rcmdnk (https://github.com/rcmdnk/shell-logger).
# ==============================================================================

# cSpell: disable
# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2317,SC2312,SC2155

LOGGER_NAME="shell-logger"
LOGGER_VERSION="v0.3.0"
LOGGER_DATE="26/Jan/2024"

# WIP:
# https://tldp.org/LDP/abs/html/fto.html
# https://opensource.com/article/22/7/print-stack-trace-bash-scripts
# https://stackoverflow.com/questions/25492953/bash-how-to-get-the-call-chain-on-errors
# https://docwhat.org/tracebacks-in-bash
# https://gist.github.com/Alphadelta14/0d9175767b406a6d3d402099f134d816
# https://gist.github.com/Asher256/4c68119705ffa11adb7446f297a7beae

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

# Log level numeric values.
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_NOTICE=2
LOG_LEVEL_WARNING=3
LOG_LEVEL_ERROR=4

# Log level text representations.
LOGGER_LEVELS=("DEBUG" "INFO" "NOTICE" "WARNING" "ERROR")

# Default settings.
LOGGER_DATE_FORMAT=${LOGGER_DATE_FORMAT:-'%Y/%m/%d %H:%M:%S'}
LOGGER_LEVEL=${LOGGER_LEVEL:-0}
LOGGER_STDERR_LEVEL=${LOGGER_STDERR_LEVEL:-4}
LOGGER_COLOR=${LOGGER_COLOR:-auto}

LOGGER_COLORS=("${LOGGER_DEBUG_COLOR:-"3;32"}")  # Italic green
LOGGER_COLORS+=("${LOGGER_INFO_COLOR:-"95"}")    # Bright Magenta
LOGGER_COLORS+=("${LOGGER_NOTICE_COLOR:-"96"}")  # Bright Cyan
LOGGER_COLORS+=("${LOGGER_WARNING_COLOR:-"93"}") # Bright Yellow
LOGGER_COLORS+=("${LOGGER_ERROR_COLOR:-"91"}")   # Bright Red

#LOGGER_ERROR_RETURN_CODE=${LOGGER_ERROR_RETURN_CODE:-100}
#LOGGER_ERROR_TRACE=${LOGGER_ERROR_TRACE:-true}

# Functions.
function _logger_version() {
  printf '%s %s %s\n' "${LOGGER_NAME}" "${LOGGER_VERSION}" "${LOGGER_DATE}"
}

function _logger_use_colors() {

  # Validate input log level.
  if [[ $# -eq 0 ]] || { [[ $1 -lt ${LOG_LEVEL_DEBUG} ]] || [[ $1 -gt ${LOG_LEVEL_ERROR} ]]; }; then
    return 1
  fi

  if [[ ${LOGGER_COLOR} == "always" ]]; then
    return 0
  fi

  if [[ $1 -ge ${LOGGER_STDERR_LEVEL} ]]; then
    # Test if stderr is attached to a terminal.
    if [[ ${LOGGER_COLOR} == "auto" ]] && tty -s < /dev/fd/2 > /dev/null 2>&1; then
      return 0
    else
      return 1
    fi
  else
    # WIP: this doesn't work mostly for some reason, tty responds "not a tty" for stdout?
    # if [[ ${LOGGER_COLOR} == "auto" ]] && tty < /dev/fd/1 2>&1; then
    #  return 0
    # else
    #  return 1
    # fi
    [[ ${LOGGER_COLOR} == "auto" ]] && return 0 || return 1
  fi
}

function _logger_get_color() {

  # Validate input log level.
  if [[ $# -eq 0 ]] || { [[ $1 -lt ${LOG_LEVEL_DEBUG} ]] || [[ $1 -gt ${LOG_LEVEL_ERROR} ]]; }; then
    return 1
  fi

  printf '%s' "${LOGGER_COLORS[$1]}"
}

function _logger_get_printfmt() {

  # Validate input log level.
  if [[ $# -eq 0 ]] || { [[ $1 -lt ${LOG_LEVEL_DEBUG} ]] || [[ $1 -gt ${LOG_LEVEL_ERROR} ]]; }; then
    return 1
  fi

  # Printf format strings need to be escaped for eval.
  if _logger_use_colors "$1"; then
    printf '\\e[%sm %%s: %%s\\e[0m\\n' "$(_logger_get_color "$1")"
  else
    printf '%%s: %%s\\n'
  fi
}

function _logger() {
  [[ -n ${ZSH_VERSION-} ]] && emulate -L ksh

  # Validate input log level.
  if [[ $# -eq 0 ]] || { [[ $1 -lt ${LOG_LEVEL_DEBUG} ]] || [[ $1 -gt ${LOG_LEVEL_ERROR} ]]; }; then
    return
  fi
  [[ $1 -lt ${LOGGER_LEVEL} ]] && return

  local level=${1:-1}
  shift

  # Construct the message prefix.
  local msg_prefix="[$(date +"${LOGGER_DATE_FORMAT}")][${LOGGER_LEVELS[${level}]}]"

  # Output to stderr after set level is reached.
  if [[ ${level} -ge ${LOGGER_STDERR_LEVEL} ]]; then
    # Escape any funnies from the message, to keep eval from exploding.
    eval ">&2 printf \"$(_logger_get_printfmt "${level}")\"  \"${msg_prefix}\" \"$(printf '%q' "$*")\""
  else
    # Escape any funnies from the message, to keep eval from exploding.
    eval "printf \"$(_logger_get_printfmt "${level}")\"  \"${msg_prefix}\" \"$(printf '%q' "$*")\""
  fi
}

function log_debug() {
  _logger "${LOG_LEVEL_DEBUG}" "$*"
}
function log_info() {
  _logger "${LOG_LEVEL_INFO}" "$*"
}
function log_notice() {
  _logger "${LOG_LEVEL_NOTICE}" "$*"
}
function log_warn() {
  _logger "${LOG_LEVEL_WARNING}" "$*"
}
function log_err() {
  _logger "${LOG_LEVEL_ERROR}" "$*"
}

# function log_err() {
#   ((_LOGGER_WRAP++)) || true
#
#   if [[ ${LOGGER_ERROR_TRACE:-false} == true ]]; then
#     {
#       local first=0
#       if [[ -n ${BASH_VERSION} ]]; then
#         local current_source="$(printf '%s' "${BASH_SOURCE[0]##*/}" | cut -d"." -f1)"
#         local func="${FUNCNAME[1]}"
#         local idx=$((${#FUNCNAME[@]} - 2))
#       elif [[ -n ${ZSH_VERSION-} ]]; then
#         emulate -L ksh
#         local current_source="$(printf '%s' "${funcfiletrace[0]##*/}" | cut -d":" -f1 | cut -d"." -f1)"
#         local func="${funcstack[1]}"
#         local idx=$((${#funcstack[@]} - 1))
#         local last_source="${funcfiletrace[${idx}]%:*}"
#         [[ ${last_source} == "zsh" ]] && ((idx--))
#       fi
#
#       if [[ ${current_source} == "shell-logger" ]] && [[ ${func} == err ]]; then
#         local first=1
#       fi
#
#       if [[ ${idx} -ge ${first} ]]; then
#         printf 'Traceback (most recent call last):\n'
#       fi
#
#       while [[ ${idx} -ge ${first} ]]; do
#         if [[ -n ${BASH_VERSION} ]]; then
#           local file="${BASH_SOURCE[$((idx + 1))]}"
#           local line="${BASH_LINENO[${idx}]}"
#           local func=""
#
#           if [[ ${BASH_LINENO[$((idx + 1))]} -ne 0 ]]; then
#             if [[ ${FUNCNAME[$((idx + 1))]} == "source" ]]; then
#               func=", in ${BASH_SOURCE[$((idx + 2))]}"
#             else
#               func=", in ${FUNCNAME[$((idx + 1))]}"
#             fi
#           fi
#
#           local func_call="${FUNCNAME[${idx}]}"
#           if [[ ${func_call} == "source" ]]; then
#             func_call="${func_call} ${BASH_SOURCE[${idx}]}"
#           else
#             func_call="${func_call}()"
#           fi
#         elif [[ -n ${ZSH_VERSION-} ]]; then
#           emulate -L ksh
#           local file="${funcfiletrace[${idx}]%:*}"
#           local line="${funcfiletrace[${idx}]#*:}"
#           local func=""
#
#           if [[ -n ${funcstack[$((idx + 1))]} ]]; then
#             if [[ ${funcstack[$((idx + 1))]} == "${funcfiletrace[${idx}]%:*}" ]]; then
#               func=", in ${funcfiletrace[$((idx + 1))]%:*}"
#             else
#               func=", in ${funcstack[$((idx + 1))]}"
#             fi
#           fi
#
#           local func_call="${funcstack[${idx}]}"
#           if [[ ${func_call} == "${funcfiletrace[$((idx - 1))]%:*}" ]]; then
#             func_call="source ${funcfiletrace[$((idx - 1))]%:*}"
#           else
#             func_call="${func_call}()"
#           fi
#         fi
#
#         printf '  File \"%s\", line %s%s\n' "${file}" "${line}" "${func}"
#
#         if [[ ${idx} -gt ${first} ]]; then
#           printf '    %s\n' "${func_call}"
#         else
#           printf '\n'
#         fi
#
#         ((idx--))
#       done
#     } 1>&2
#   fi
#   _logger "${LOG_LEVEL_ERROR}" "$*"
#
#   return "${LOGGER_ERROR_RETURN_CODE}"
# }
