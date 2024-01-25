#!/usr/bin/env bash

# ==============================================================================
# Shell-logger install script.
# Based on 'shell-logger' project by rcmdnk (https://github.com/rcmdnk/shell-logger).
# ==============================================================================

# cSpell: disable
# shellcheck shell=bash
# shellcheck source=/dev/null
# shellcheck disable=SC2317

#set -x

INSTALL_SCRIPTS=(
  "https://github.com/JoonasOnatsu/shell-logger/raw/master/shell-logger.sh"
)
INSTALL_FORCE=false
INSTALL_PREFIX=
INSTALL_SCRATCHDIR=

#--------------------------------------
# Helper functions.
#--------------------------------------

function install_help() {
  cat >&2 << 'EOF'
Usage: ${BASH_SOURCE[0]} [OPTIONS] <directory>

Any unknown arguments are discarded.

Options:
    --help, -h     Show this help message and exit.
    --prefix, -p   Script install path prefix.
    --force, -f    Force overwriting existing file(s).
EOF
}

function install_log() {
  printf '%s: %s\n' "${BASH_SOURCE[0]}" "$*" >&2
}

function install_exit {
  [[ $? -ne 0 ]] && install_log "'shell-logger' installation failed!"
  #set +x
  [[ -d ${INSTALL_SCRATCHDIR} ]] && command rm -rf "${INSTALL_SCRATCHDIR}"
  unset INSTALL_SCRIPTS
  unset INSTALL_FORCE
  unset INSTALL_PREFIX
  unset INSTALL_SCRATCHDIR
  unset INSTALL_SUDO
  unset -f install_help
  unset -f install_log
  unset -f install_exit
}
trap install_exit EXIT

#--------------------------------------
# Installation.
#--------------------------------------

# Set default INSTALL_PREFIX, and create scratch directory.
if [[ -n ${XDG_CONFIG_HOME} ]]; then
  INSTALL_PREFIX="${XDG_CONFIG_HOME}/bash/shell-logger"
else
  INSTALL_PREFIX="${HOME}/.config/bash/shell-logger"
fi

INSTALL_SCRATCHDIR="$(command mktemp -d -t tmp.XXXXXXXXXX)"

# Parse arguments, if any.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help | -h | -\?)
      install_help
      exit 0
      ;;
    --force | -f)
      INSTALL_FORCE=true
      ;;
    --prefix | -p)
      if [[ -d $2 ]]; then
        INSTALL_PREFIX="$(command readlink -f "$2" || command realpath "$2")"
        shift
      fi
      ;;
    *)
      # Ignore unknowns.
      ;;
  esac
  shift
done

# Start the installation
cat <<- EOF


###############################################################################
###                         shell-logger installer                          ###
###############################################################################

This is the installation script for 'shell-logger', installation directory is:
"${INSTALL_PREFIX}"


EOF

testfile="${INSTALL_PREFIX}/.install.test"
max_tries=3
try_count=1
test_success=false

# Check if we can write to the destination directory if it exists,
# or try to create the directory.
while [[ ${test_success} == false ]] && [[ ${try_count} -le ${max_tries} ]]; do

  # If the directory exists, try writing into it, otherwise try to create it.
  if [[ -d ${INSTALL_PREFIX} ]]; then
    install_log "testing for write permissions into directory \"${INSTALL_PREFIX}\"..."
    touch "${testfile}" > /dev/null && test_success=true
  else
    install_log "trying to create directory \"${INSTALL_PREFIX}\"..."
    command mkdir -p "${INSTALL_PREFIX}" > /dev/null && test_success=true
  fi

  if [[ ${test_success} == true ]]; then
    command rm -f "${testfile}" > /dev/null
  else
    install_log "write permission/directory create test [${try_count}/${max_tries}] failed!"
    try_count=$((try_count + 1))
    sleep 1

    install_log "trying again with sudo permissions..."
    sudo -v
  fi
done

# Crash and burn if we don't have a directory to install the scripts into.
if [[ ${test_success} == false ]]; then
  install_log "cannot create/write to installation directory \"${INSTALL_PREFIX}\"!"
  exit 2
fi

# How to download?
download_cmd=
if command -v curl > /dev/null 2>&1; then
  download_cmd="command curl -fsSL -o"
elif command -v wget > /dev/null 2>&1; then
  download_cmd="command wget -qO"
else
  install_log "cannot find 'curl' or 'wget' to download files!"
  exit 2
fi

# Install the script(s).
install_log "downloading and installing 'shell-logger' scripts..."
for script in "${INSTALL_SCRIPTS[@]}"; do

  script_basename="${script##*/}"
  script_tmp="${INSTALL_SCRATCHDIR}/${script_basename}"
  script_dest="${INSTALL_PREFIX}/${script_basename}"

  install_log "installing \"${script}\"..."

  # Try the script installation a hew times
  # to rule out any transient errors (e.g. network timeouts).
  max_tries=3
  try_count=1
  install_success=false

  while [[ ${install_success} == false ]] && [[ ${try_count} -le ${max_tries} ]]; do

    # Download each script into a temporary file first.
    eval "${download_cmd} ${script_tmp} ${script}"
    if [[ ! -f ${script_tmp} ]]; then
      install_log "download attempt [${try_count}/${max_tries}] of \"${script}\" failed!\n"
      try_count=$((try_count + 1))
      sleep 1
      continue
    fi

    # If the destination file exists, and INSTALL_FORCE is false, bail out.
    if [[ -f ${script_dest} ]] && [[ ${INSTALL_FORCE} == false ]]; then
      install_log "cannot overwrite existing file \"${script_dest}\"!"
      exit 2
    # Crash and burn if we cannot move the file to destination successfully.
    elif ! command mv "${script_tmp}" "${script_dest}"; then
      install_log "moving file \"${script_tmp}\" to \"${script_dest}\" failed!"
      exit 2
    else
      # Ensure that the file has correct permissions.
      if ! command chmod 0755 "${script_dest}"; then
        install_log "settting permissions for \"${script_dest}\" failed!"
        exit 2
      fi

      install_success=true
      install_log "successfully installed \"${script}\""
    fi
  done

  # Crash and burn if file install failed.
  if [[ ${test_success} == false ]]; then
    install_log "installing \"${script}\" failed!"
    exit 2
  fi
done

cat <<- EOF


###############################################################################
###                         shell-logger installer                          ###
###############################################################################

                            INSTALLATION COMPLETE!

To use the 'shell-logger', you must source the shell-logger script in your
shell initialzation file (e.g ~/.bashrc/~.zshrc):

source "${INSTALL_PREFIX}/shell-logger.sh"


EOF

exit 0
