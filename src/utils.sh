# shellcheck shell=bash

# Enable easier mocking in tests
USER_ID=${UID}
UNIX_NAME=$(uname)
declare -x SWELLABY_DOTFILES_QUIET=${SWELLABY_DOTFILES_QUIET:-false}

readonly MAC_OS="macos"
readonly LINUX_OS="linux"
declare -x OPERATING_SYSTEM=""

declare -x BITNESS=""

# This file should be present on the vast majority of modern versions
# of most major distributions, as well as anything running systemd
declare -x LINUX_DISTRO_OS_IDENTIFICATION_FILE="/etc/os-release"

LINUX_DISTRO=""
declare -ix SNAP_AVAILABLE
readonly UBUNTU_DISTRO="ubuntu"
readonly DEBIAN_DISTRO="debian"
readonly FEDORA_DISTRO="fedora"
readonly RHEL_DISTRO="rhel"
readonly CENTOS_DISTRO="centos"

declare -x LINUX_DISTRO_FAMILY=""
readonly DEBIAN_DISTRO_FAMILY=${DEBIAN_DISTRO}
readonly FEDORA_DISTRO_FAMILY=${FEDORA_DISTRO}

declare -x LINUX_DISTRO_VERSION_ID=""

# Configure package managers.
# Maybe one day these can be added...
# FreeBSD = pkg
# SUSE = zypper
# Arch = pacman
# Gentoo = portage
PACKAGE_MANAGER=""
readonly DEBIAN_PACKAGE_MANAGER="apt"
readonly DEBIAN_INSTALL_SUBCOMMAND="install"
readonly DEBIAN_INSTALLER_SUFFIX="-y --no-install-recommends"
readonly DEBIAN_UPDATE_PACKAGE_LISTS_COMMAND="update"
readonly DEBIAN_UPDATE_PACKAGE_LISTS_SUFFIX="-y"
readonly DEBIAN_REMOVE_SUBCOMMAND="remove"
readonly DEBIAN_REMOVE_SUFFIX="-y"
readonly DEBIAN_PACKAGE_KEY_MANAGEMENT_TOOL="apt-key"
readonly DEBIAN_ADD_SIGNING_KEY_SUBCOMMAND="add"
readonly DEBIAN_PACKAGE_REPOSITORY_MANAGEMENT_TOOL="add-apt-repository"

readonly FEDORA_PACKAGE_MANAGER="dnf"
readonly FEDORA_INSTALL_SUBCOMMAND="install"
readonly FEDORA_INSTALLER_SUFFIX="-y"
readonly FEDORA_REMOVE_SUBCOMMAND="remove"
readonly FEDORA_REMOVE_SUFFIX="-y"
readonly FEDORA_PACKAGE_KEY_MANAGEMENT_TOOL="rpm"
readonly FEDORA_ADD_SIGNING_KEY_SUBCOMMAND="--import"
readonly FEDORA_PACKAGE_REPOSITORY_MANAGEMENT_TOOL="${FEDORA_PACKAGE_MANAGER}"
readonly FEDORA_ADD_PACKAGE_REPOSITORY_SUBCOMMAND="config-manager"
readonly FEDORA_ADD_PACKAGE_REPOSITORY_SUFFIX="--add-repository"

readonly MACOS_PACKAGE_MANAGER="brew"
readonly MACOS_INSTALL_SUBCOMMAND="install"
readonly MACOS_REMOVE_SUBCOMMAND="uninstall"

INSTALLER_PREFIX=""
INSTALLER_SUFFIX=""
INSTALL_SUBCOMMAND=""
declare -x INSTALL_COMMAND=""
declare -x UPDATE_PACKAGE_LISTS_COMMAND=""
declare -x UPDATE_PACKAGE_LISTS_SUFFIX=""
NEEDS_PACKAGE_LIST_UPDATES=false
REMOVE_SUBCOMMAND=""
REMOVE_SUFFIX=""
declare -x REMOVE_COMMAND=""
PACKAGE_REPOSITORY_MANAGEMENT_TOOL=""
ADD_PACKAGE_REPOSITORY_SUBCOMMAND=""
ADD_PACKAGE_REPOSITORY_SUFFIX=""
declare -x ADD_PACKAGE_REPOSITORY_COMMAND=""

function error() {
  echo "[swellaby_dotfiles]: $*" >&2
}

function info() {
  if [ "${SWELLABY_DOTFILES_QUIET}" == "true" ]; then
    return 0
  fi
  echo "[swellaby_dotfiles]: $*" >&1
}

function print_tool_installation_message() {
  info "Installing ${1}..."
}

function tool_installed() {
  local application_name=${1}

  if command -v "${application_name}" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

function check_snapd_availability() {
  tool_installed "snap"
  SNAP_AVAILABLE=$?
  return 0
}

function update_package_lists() {
  if [ "${NEEDS_PACKAGE_LIST_UPDATES}" == true ]; then
    # shellcheck disable=SC2086
    ${INSTALLER_PREFIX} ${PACKAGE_MANAGER} ${UPDATE_PACKAGE_LISTS_COMMAND} ${UPDATE_PACKAGE_LISTS_SUFFIX}
  fi
}

function set_debian_variables() {
  LINUX_DISTRO_FAMILY=${DEBIAN_DISTRO_FAMILY}
  PACKAGE_MANAGER=${DEBIAN_PACKAGE_MANAGER}
  INSTALLER_SUFFIX=${DEBIAN_INSTALLER_SUFFIX}
  INSTALL_SUBCOMMAND=${DEBIAN_INSTALL_SUBCOMMAND}
  NEEDS_PACKAGE_LIST_UPDATES=true
  UPDATE_PACKAGE_LISTS_COMMAND=${DEBIAN_UPDATE_PACKAGE_LISTS_COMMAND}
  UPDATE_PACKAGE_LISTS_SUFFIX=${DEBIAN_UPDATE_PACKAGE_LISTS_SUFFIX}
  REMOVE_SUBCOMMAND=${DEBIAN_REMOVE_SUBCOMMAND}
  REMOVE_SUFFIX=${DEBIAN_REMOVE_SUFFIX}
  PACKAGE_REPOSITORY_MANAGEMENT_TOOL=${DEBIAN_PACKAGE_REPOSITORY_MANAGEMENT_TOOL}
}

function set_fedora_variables() {
  LINUX_DISTRO_FAMILY=${FEDORA_DISTRO_FAMILY}
  PACKAGE_MANAGER=${FEDORA_PACKAGE_MANAGER}
  INSTALLER_SUFFIX=${FEDORA_INSTALLER_SUFFIX}
  INSTALL_SUBCOMMAND=${FEDORA_INSTALL_SUBCOMMAND}
  REMOVE_SUBCOMMAND=${FEDORA_REMOVE_SUBCOMMAND}
  REMOVE_SUFFIX=${FEDORA_REMOVE_SUFFIX}
  PACKAGE_REPOSITORY_MANAGEMENT_TOOL=${FEDORA_PACKAGE_REPOSITORY_MANAGEMENT_TOOL}
  ADD_PACKAGE_REPOSITORY_SUBCOMMAND=${FEDORA_ADD_PACKAGE_REPOSITORY_SUBCOMMAND}
  ADD_PACKAGE_REPOSITORY_SUFFIX=${FEDORA_ADD_PACKAGE_REPOSITORY_SUFFIX}
}

function set_linux_variables() {
  OPERATING_SYSTEM=$LINUX_OS
  if [ ! -f ${LINUX_DISTRO_OS_IDENTIFICATION_FILE} ]; then
    error "Detected Linux OS but did not find '${LINUX_DISTRO_OS_IDENTIFICATION_FILE}' file"
    exit 1
  fi

  function get_os_metadata_by_key_search() {
    local search_key="${1}"
    local search="(?<=${search_key}).+"
    grep -oP "${search}" ${LINUX_DISTRO_OS_IDENTIFICATION_FILE} | tr -d '"'
  }
  LINUX_DISTRO=$(get_os_metadata_by_key_search "^ID=")
  info "Detected Linux distro: '${LINUX_DISTRO}'"
  LINUX_DISTRO_VERSION_ID=$(get_os_metadata_by_key_search "^VERSION_ID=")
  info "Detected Linux distro version id: '${LINUX_DISTRO_VERSION_ID}'"

  if [ ${USER_ID} -ne 0 ]; then
    INSTALLER_PREFIX="sudo"
  fi

  check_snapd_availability

  case ${LINUX_DISTRO} in
    "${DEBIAN_DISTRO}")
      set_debian_variables
      ;;
    "${UBUNTU_DISTRO}")
      set_debian_variables
      ;;
    "${FEDORA_DISTRO}")
      set_fedora_variables
      ;;
    "${RHEL_DISTRO}")
      set_fedora_variables
      ;;
    "${CENTOS_DISTRO}")
      set_fedora_variables
      ;;
    *)
      error "Unsupported distro: '${LINUX_DISTRO}'"
      exit 1
      ;;
  esac
}

function set_macos_variables() {
  OPERATING_SYSTEM=${MAC_OS}
  PACKAGE_MANAGER=${MACOS_PACKAGE_MANAGER}
  INSTALL_SUBCOMMAND=${MACOS_INSTALL_SUBCOMMAND}
  SNAP_AVAILABLE=0
  REMOVE_SUBCOMMAND=${MACOS_REMOVE_SUBCOMMAND}
}

function install_snap() {
  local snap_name
  local snap_prefix

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n | --snap-name)
        snap_name="${2}"
        shift
        ;;
      -p | --snap-prefix)
        snap_prefix="${2}"
        shift
        ;;
      *)
        error "Invalid 'install_snap' arg: '${1}'. This is a bug!"
        exit 1
        ;;
    esac
    shift
  done

  if [ -z "${snap_name}" ]; then
    error "No snap name provided to 'install_snap'. This is a bug!"
    return 1
  fi

  # shellcheck disable=SC2086
  ${INSTALLER_PREFIX} snap install ${snap_prefix} "${snap_name}"
}

function install_package() {
  local package_name
  local package_prefix

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n | --package-name)
        package_name="${2}"
        shift
        ;;
      -p | --package-prefix)
        package_prefix="${2}"
        shift
        ;;
      *)
        error "Invalid 'install_package' arg: '${1}'. This is a bug!"
        exit 1
        ;;
    esac
    shift
  done

  if [ -z "${package_name}" ]; then
    error "No package name provided to 'install_package'. This is a bug!"
    return 1
  fi

  # shellcheck disable=SC2086
  ${INSTALL_COMMAND} ${package_prefix} ${package_name}
}

function remove_package() {
  local package_name
  local package_prefix

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -n | --package-name)
        package_name="${2}"
        shift
        ;;
      -p | --package-prefix)
        package_prefix="${2}"
        shift
        ;;
      *)
        error "Invalid 'remove_package' arg: '${1}'. This is a bug!"
        exit 1
        ;;
    esac
    shift
  done

  if [ -z "${package_name}" ]; then
    error "No package name provided to 'remove_package'. This is a bug!"
    return 1
  fi

  # shellcheck disable=SC2086
  ${REMOVE_COMMAND} ${package_prefix} ${package_name}
}

function install() {
  local application_name
  local prefer_snap
  local fedora_family_package_name
  local debian_family_package_name
  local package_prefix
  local snap_name
  local snap_prefix
  local mac_package_name
  local mac_package_prefix

  if [ $# -eq 0 ]; then
    error "No args passed to 'install' but at a minimum a snap or package name must be provided. This is a bug!"
    exit 1
  fi

  prefer_snap=false

  while [[ "$#" -gt 0 ]]; do
    # Assume a default shift of two since most arguments are
    # options with values. Override this to `1` for any flags
    local -i shift_count=2
    case $1 in
      -a | --application-name)
        application_name="${2}"
        ;;
      -pfs | --prefer-snap)
        prefer_snap=true
        shift_count=1
        ;;
      -ffpn | --fedora-family-package-name)
        fedora_family_package_name="${2}"
        ;;
      -dfpn | --debian-family-package-name)
        debian_family_package_name="${2}"
        ;;
      -p | --package-prefix)
        package_prefix="${2}"
        ;;
      -s | --snap-name)
        snap_name="${2}"
        ;;
      -sp | --snap-prefix)
        snap_prefix="${2}"
        ;;
      -m | --mac-package-name)
        mac_package_name="${2}"
        ;;
      -mp | --mac-package-prefix)
        mac_package_prefix="${2}"
        ;;
      *)
        error "Invalid 'install' arg: '${1}'. This is a bug!"
        exit 1
        ;;
    esac
    shift $shift_count
  done

  if [ -z "${application_name}" ]; then
    error "No arg value was provided for '--application-name'. This is a bug!"
    exit 1
  fi

  # First try to use Snapcraft provided the caller has indicated,
  # and it is available with requisite parameters. Otherwise fall back
  # to the platform package manager.
  if [ "${prefer_snap}" == true ]; then
    if [ ${SNAP_AVAILABLE} -ne 0 ]; then
      error "Snap install preferred but Snap not available. This is a bug!"
    else
      # shellcheck disable=SC2046
      install_snap -n "${snap_name}"$([ -z "${snap_prefix}" ] && echo "" || echo " -p ${snap_prefix}")
      # shellcheck disable=SC2181
      if [ $? -eq 0 ]; then
        return 0
      else
        error "Attempted but failed to install tool: '${application_name}' with Snap"
        error "Falling back to package manager"
      fi
    fi
  fi

  # Just to encapsulate some common argument checking, no need to be public
  # so function is defined within the containing install function.
  function install_linux_package() {
    local package="${1}"
    local prefix="${2}"
    if [ -z "${package}" ]; then
      error "On ${LINUX_DISTRO} but package name for '${application_name}' was not provided for platform. This is likely a bug."
      # We may want to consider exiting here at some point down the road. For now
      # it's most likely a case of "not yet implemented" that shouldn't necessarily
      # crash the whole script though.
    else
      # shellcheck disable=SC2046
      install_package -n "${package}"$([ -z "${prefix}" ] && echo "" || echo " -p ${prefix}")
    fi
  }

  if [ "${LINUX_DISTRO_FAMILY}" == "${DEBIAN_DISTRO_FAMILY}" ]; then
    install_linux_package "${debian_family_package_name}" "${package_prefix}"
  elif [ "${LINUX_DISTRO_FAMILY}" == "${FEDORA_DISTRO_FAMILY}" ]; then
    install_linux_package "${fedora_family_package_name}" "${package_prefix}"
  elif [ "${OPERATING_SYSTEM}" == "${MAC_OS}" ]; then
    if [ -z "${mac_package_name}" ]; then
      error "On Mac OS but package name was not provided for '${application_name}' for Mac OS platform. This is likely a bug."
      # We may want to consider exiting here at some point down the road. For now
      # it's most likely a case of "not yet implemented" that shouldn't necessarily
      # crash the whole script though.
    else
      # shellcheck disable=SC2046
      install_package -n "${mac_package_name}"$([ -z "${mac_package_prefix}" ] && echo "" || echo " -p ${mac_package_prefix}")
    fi
  else
    error "Unable to install '${application_name}' on ${LINUX_DISTRO} because it is an unsupported platform. This is a bug!"
  fi
}

function add_remote_signing_key() {
  if [ "${OPERATING_SYSTEM}" == "${MAC_OS}" ]; then
    error "Package signing keys are not supported on MacOS. This is a bug!"
    return 1
  fi

  local key_url

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -u | --key-url)
        key_url="${2}"
        shift 2
        ;;
      *)
        error "Invalid 'add_remote_signing_key' arg: '${1}'. This is a bug!"
        exit 1
        ;;
    esac
  done

  if [ -z "${key_url}" ]; then
    error "No url for signing key provided to 'add_remote_signing_key'. This is a bug!"
    return 1
  fi

  if [ "${LINUX_DISTRO_FAMILY}" == "${DEBIAN_DISTRO_FAMILY}" ]; then
    if ! tool_installed "curl"; then
      if ! install_package -n "curl"; then
        error "curl was not found and attempt to install failed."
        return 1
      fi
    fi

    # shellcheck disable=SC2086
    curl -fsSL "${key_url}" |
      ${INSTALLER_PREFIX} ${DEBIAN_PACKAGE_KEY_MANAGEMENT_TOOL} \
        ${DEBIAN_ADD_SIGNING_KEY_SUBCOMMAND} -
  elif [ "${LINUX_DISTRO_FAMILY}" == "${FEDORA_DISTRO_FAMILY}" ]; then
    # shellcheck disable=SC2086
    ${INSTALLER_PREFIX} ${FEDORA_PACKAGE_KEY_MANAGEMENT_TOOL} \
      ${FEDORA_ADD_SIGNING_KEY_SUBCOMMAND} "${key_url}"
  else
    error "Tried to install a package signing key on an supported distro: '${LINUX_DISTRO}'. This is likely a bug."
    return 1
  fi
}

function add_package_repository() {
  if [ "${OPERATING_SYSTEM}" == "${MAC_OS}" ]; then
    error "Adding package repositories is not supported on MacOS. This is a bug!"
    return 1
  fi

  local package_repository

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -r | --package-repository)
        package_repository="${2}"
        shift 2
        ;;
      *)
        error "Invalid 'add_package_repository' arg: '${1}'. This is a bug!"
        exit 1
        ;;
    esac
  done

  if [ -z "${package_repository}" ]; then
    error "No package repository provided to 'add_package_repository'. This is a bug!"
    return 1
  fi

  if [ "${LINUX_DISTRO_FAMILY}" != "${DEBIAN_DISTRO_FAMILY}" ] &&
    [ "${LINUX_DISTRO_FAMILY}" != "${FEDORA_DISTRO_FAMILY}" ]; then
    error "Tried to add a package repository on an supported distro: '${LINUX_DISTRO}'. This is likely a bug."
    return 1
  fi

  if [ "${LINUX_DISTRO_FAMILY}" == "${FEDORA_DISTRO_FAMILY}" ]; then
    # shellcheck disable=SC2086
    if ! ${PACKAGE_REPOSITORY_MANAGEMENT_TOOL} ${ADD_PACKAGE_REPOSITORY_SUBCOMMAND} -h; then
      if ! install_package -n "dnf-plugins-core"; then
        error "dnf config-manager plugin was not found and attempt to install failed."
        return 1
      fi
    fi
  fi

  # shellcheck disable=SC2086
  ${ADD_PACKAGE_REPOSITORY_COMMAND} "${package_repository}"
}

function initialize() {
  if [ "${UNIX_NAME}" == "Darwin" ]; then
    set_macos_variables
  elif [ "${UNIX_NAME}" == "Linux" ]; then
    set_linux_variables
  else
    error "Unsupported OS. Are you on Windows using Git Bash or Cygwin?"
    exit 1
  fi

  BITNESS=$(getconf LONG_BIT)

  INSTALL_COMMAND="${INSTALLER_PREFIX} ${PACKAGE_MANAGER} ${INSTALL_SUBCOMMAND} ${INSTALLER_SUFFIX}"
  REMOVE_COMMAND="${INSTALLER_PREFIX} ${PACKAGE_MANAGER} ${REMOVE_SUBCOMMAND} ${REMOVE_SUFFIX}"
  ADD_PACKAGE_REPOSITORY_COMMAND="${INSTALLER_PREFIX} ${PACKAGE_REPOSITORY_MANAGEMENT_TOOL} ${ADD_PACKAGE_REPOSITORY_SUBCOMMAND} ${ADD_PACKAGE_REPOSITORY_SUFFIX}"

  readonly UNIX_NAME
  readonly OPERATING_SYSTEM
  readonly BITNESS
  readonly LINUX_DISTRO_OS_IDENTIFICATION_FILE
  readonly LINUX_DISTRO
  readonly LINUX_DISTRO_FAMILY
  readonly LINUX_DISTRO_VERSION_ID
  readonly INSTALLER_PREFIX
  readonly INSTALLER_SUFFIX
  readonly PACKAGE_MANAGER
  readonly INSTALL_COMMAND
  readonly INSTALL_SUBCOMMAND
  readonly REMOVE_COMMAND
  readonly REMOVE_SUBCOMMAND
  readonly REMOVE_SUFFIX
  readonly SNAP_AVAILABLE
  readonly UPDATE_PACKAGE_LISTS_COMMAND
  readonly UPDATE_PACKAGE_LISTS_SUFFIX
  readonly NEEDS_PACKAGE_LIST_UPDATES
  readonly SWELLABY_DOTFILES_QUIET
  readonly PACKAGE_REPOSITORY_MANAGEMENT_TOOL
  readonly ADD_PACKAGE_REPOSITORY_SUBCOMMAND
  readonly ADD_PACKAGE_REPOSITORY_SUFFIX
  readonly ADD_PACKAGE_REPOSITORY_COMMAND
}

# Don't auto initialize when sourced for running tests
# https://github.com/bats-core/bats-core#special-variables
if [[ -z ${BATS_TEST_NAME} ]]; then
  initialize
  unset set_debian_variables
  unset set_fedora_variables
  unset set_linux_variables
  unset set_macos_variables
  unset initialize
fi
