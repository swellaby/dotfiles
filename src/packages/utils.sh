# shellcheck shell=bash

# Enable easier mocking in tests
USER_ID=${UID}
unix_name=$(uname)

readonly MAC_OS="macos"
readonly LINUX_OS="linux"
declare -x OPERATING_SYSTEM=""

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

readonly FEDORA_PACKAGE_MANAGER="dnf"
readonly FEDORA_INSTALL_SUBCOMMAND="install"
readonly FEDORA_INSTALLER_SUFFIX="-y"

readonly MACOS_PACKAGE_MANAGER="brew"
readonly MACOS_INSTALL_SUBCOMMAND="install"

INSTALLER_PREFIX=""
INSTALLER_SUFFIX=""
INSTALL_SUBCOMMAND=""
declare -x INSTALL_COMMAND=""

function error() {
  echo "[swellaby_dotfiles]: $*" >&2
}

function info() {
  echo "[swellaby_dotfiles]: $*" >&1
}

function tool_installed() {
  local tool_name=${1}

  command -v ${tool_name} >/dev/null 2>&1
}

function check_snapd_availability() {
  SNAP_AVAILABLE=$(tool_installed "snap")
}

function set_debian_variables() {
  LINUX_DISTRO_FAMILY=${DEBIAN_DISTRO_FAMILY}
  PACKAGE_MANAGER=${DEBIAN_PACKAGE_MANAGER}
  INSTALLER_SUFFIX=${DEBIAN_INSTALLER_SUFFIX}
  INSTALL_SUBCOMMAND=${DEBIAN_INSTALL_SUBCOMMAND}
}

function set_fedora_variables() {
  LINUX_DISTRO_FAMILY=${FEDORA_DISTRO_FAMILY}
  PACKAGE_MANAGER=${FEDORA_PACKAGE_MANAGER}
  INSTALLER_SUFFIX=${FEDORA_INSTALLER_SUFFIX}
  INSTALL_SUBCOMMAND=${FEDORA_INSTALL_SUBCOMMAND}
}

function set_linux_variables() {
  OPERATING_SYSTEM=$LINUX_OS
  if [ ! -f ${LINUX_DISTRO_OS_IDENTIFICATION_FILE} ]; then
    error "Detected Linux OS but did not find '${LINUX_DISTRO_OS_IDENTIFICATION_FILE}' file"
    exit 1
  fi

  local id
  id=$(grep -oP '(?<=^ID=).+' ${LINUX_DISTRO_OS_IDENTIFICATION_FILE} | tr -d '"')
  LINUX_DISTRO=$id
  info "Detected Linux distro: '${LINUX_DISTRO}'"

  if [ ${USER_ID} -ne 0 ]; then
    INSTALLER_PREFIX="sudo"
  fi

  check_snapd_availability

  case $id in
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

function install() {
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
    case $1 in
      -pfs | --prefer-snap)
        prefer_snap=true
        ;;
      -ffpn | --fedora-family-package-name)
        fedora_family_package_name="${2}"
        shift
        ;;
      -dfpn | --debian-family-package-name)
        debian_family_package_name="${2}"
        shift
        ;;
      -p | --package-prefix)
        package_prefix="${2}"
        shift
        ;;
      -s | --snap-name)
        snap_name="${2}"
        shift
        ;;
      -sp | --snap-prefix)
        snap_prefix="${2}"
        shift
        ;;
      -m | --mac-package-name)
        mac_package_name="${2}"
        shift
        ;;
      -mp | --mac_package-prefix)
        mac_package_prefix="${2}"
        shift
        ;;
      *)
        error "Invalid 'install' arg: '${1}'. This is a bug!"
        exit 1
        ;;
    esac
    shift
  done

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
        error "Attempted but failed to install Snap: '${snap_name}'"
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
      error "On ${LINUX_DISTRO} but package name was not provided for platform. This is likely a bug."
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
      error "On Mac OS but package name was not provided for Mac OS platform. This is likely a bug."
      # We may want to consider exiting here at some point down the road. For now
      # it's most likely a case of "not yet implemented" that shouldn't necessarily
      # crash the whole script though.
    else
      # shellcheck disable=SC2046
      install_package -n "${mac_package_name}"$([ -z "${mac_package_prefix}" ] && echo "" || echo " -p ${mac_package_prefix}")
    fi
  else
    error "Unable to install package on ${LINUX_DISTRO} because it is an unsupported platform. This is a bug!"
  fi
}

function initialize() {
  if [ "${unix_name}" == "Darwin" ]; then
    set_macos_variables
  elif [ "${unix_name}" == "Linux" ]; then
    set_linux_variables
  else
    error "Unsupported OS. Are you on Windows using Git Bash or Cygwin?"
    exit 1
  fi

  INSTALL_COMMAND="${INSTALLER_PREFIX} ${PACKAGE_MANAGER} ${INSTALL_SUBCOMMAND} ${INSTALLER_SUFFIX}"

  readonly unix_name
  readonly OPERATING_SYSTEM
  readonly LINUX_DISTRO_OS_IDENTIFICATION_FILE
  readonly LINUX_DISTRO
  readonly LINUX_DISTRO_FAMILY
  readonly INSTALLER_PREFIX
  readonly INSTALLER_SUFFIX
  readonly PACKAGE_MANAGER
  readonly INSTALL_COMMAND
  readonly INSTALL_SUBCOMMAND
  readonly SNAP_AVAILABLE
}

# Don't auto initialize during when sourced for running tests
# https://github.com/bats-core/bats-core#special-variables
if [[ -z ${BATS_TEST_NAME} ]]; then
  initialize
  unset set_debian_variables
  unset set_fedora_variables
  unset set_linux_variables
  unset set_macos_variables
  unset initialize
fi
