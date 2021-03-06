#!/usr/bin/env bats

# shellcheck source=tests/unit/utils/common.sh
source "${BATS_TEST_DIRNAME}/common.sh"

readonly TEST_SUITE_PREFIX=${BASE_TEST_SUITE_PREFIX}initialize::

function setup() {
  source "${UTILS_SOURCE_PATH}"
  setup_os_release_file

  function check_snapd_availability() {
    return 0
  }

  declare -f check_snapd_availability
  mock_error
  mock_info
  mock_getconf_default
}

function teardown() {
  teardown_os_release_file
  rm -f "${STD_OUT_TMP_FILE}" || true
}

function assert_fedora_variables() {
  local distro
  local distro_version_id
  local result
  distro=${1}
  distro_version_id=${2}
  result=${3}

  assert_equal "${result}" 0
  assert_equal "${OPERATING_SYSTEM}" "${LINUX_OS}"
  assert_equal "${LINUX_DISTRO}" "${distro}"
  assert_equal "${LINUX_DISTRO_VERSION_ID}" "${distro_version_id}"
  assert_equal "${LINUX_DISTRO_FAMILY}" "${FEDORA_DISTRO_FAMILY}"
  assert_equal "${PACKAGE_MANAGER}" "${FEDORA_PACKAGE_MANAGER}"
  assert_equal "${INSTALL_SUBCOMMAND}" "${FEDORA_INSTALL_SUBCOMMAND}"
  assert_equal "${INSTALLER_SUFFIX}" "${FEDORA_INSTALLER_SUFFIX}"
  assert_equal "${NEEDS_PACKAGE_LIST_UPDATES}" false
  assert_equal "${REMOVE_SUBCOMMAND}" "${FEDORA_REMOVE_SUBCOMMAND}"
  assert_equal "${REMOVE_SUFFIX}" "${FEDORA_REMOVE_SUFFIX}"
  assert_equal "${PACKAGE_REPOSITORY_MANAGEMENT_TOOL}" "${FEDORA_PACKAGE_REPOSITORY_MANAGEMENT_TOOL}"
  assert_equal "${ADD_PACKAGE_REPOSITORY_SUBCOMMAND}" "${FEDORA_ADD_PACKAGE_REPOSITORY_SUBCOMMAND}"
  assert_equal "${ADD_PACKAGE_REPOSITORY_SUFFIX}" "${FEDORA_ADD_PACKAGE_REPOSITORY_SUFFIX}"
}

function assert_debian_variables() {
  local distro
  local distro_version_id
  local result
  distro=${1}
  distro_version_id=${2}
  result=${3}

  assert_equal "${result}" 0
  assert_equal "${OPERATING_SYSTEM}" "${LINUX_OS}"
  assert_equal "${LINUX_DISTRO}" "${distro}"
  assert_equal "${LINUX_DISTRO_VERSION_ID}" "${distro_version_id}"
  assert_equal "${LINUX_DISTRO_FAMILY}" "${DEBIAN_DISTRO_FAMILY}"
  assert_equal "${PACKAGE_MANAGER}" "${DEBIAN_PACKAGE_MANAGER}"
  assert_equal "${INSTALL_SUBCOMMAND}" "${DEBIAN_INSTALL_SUBCOMMAND}"
  assert_equal "${INSTALLER_SUFFIX}" "${DEBIAN_INSTALLER_SUFFIX}"
  assert_equal "${NEEDS_PACKAGE_LIST_UPDATES}" true
  assert_equal "${UPDATE_PACKAGE_LISTS_COMMAND}" "${DEBIAN_UPDATE_PACKAGE_LISTS_COMMAND}"
  assert_equal "${UPDATE_PACKAGE_LISTS_SUFFIX}" "${DEBIAN_UPDATE_PACKAGE_LISTS_SUFFIX}"
  assert_equal "${REMOVE_SUBCOMMAND}" "${DEBIAN_REMOVE_SUBCOMMAND}"
  assert_equal "${REMOVE_SUFFIX}" "${DEBIAN_REMOVE_SUFFIX}"
  assert_equal "${PACKAGE_REPOSITORY_MANAGEMENT_TOOL}" "${DEBIAN_PACKAGE_REPOSITORY_MANAGEMENT_TOOL}"
  assert_equal "${ADD_PACKAGE_REPOSITORY_SUBCOMMAND}" ""
  assert_equal "${ADD_PACKAGE_REPOSITORY_SUFFIX}" ""
}

@test "${TEST_SUITE_PREFIX}mac bootstrapped correctly" {
  UNIX_NAME="Darwin" initialize

  assert_equal $? 0
  assert_equal "${OPERATING_SYSTEM}" "${MAC_OS}"
  assert_equal "${PACKAGE_MANAGER}" "${MACOS_PACKAGE_MANAGER}"
  assert_equal "${INSTALL_SUBCOMMAND}" "${MACOS_INSTALL_SUBCOMMAND}"
  assert_equal "${INSTALLER_PREFIX}" ""
  assert_equal "${INSTALLER_SUFFIX}" ""
  assert_equal "${INSTALL_COMMAND}" " ${MACOS_PACKAGE_MANAGER} ${MACOS_INSTALL_SUBCOMMAND} "
  assert_equal "${NEEDS_PACKAGE_LIST_UPDATES}" false
  assert_equal "${REMOVE_SUBCOMMAND}" "${MACOS_REMOVE_SUBCOMMAND}"
}

@test "${TEST_SUITE_PREFIX}windows errors correctly" {
  exp_err="Unsupported OS. Are you on Windows using Git Bash or Cygwin?"

  UNIX_NAME="MINGW" run initialize

  assert_failure
  assert_error_call_args "${exp_err}"
}

@test "${TEST_SUITE_PREFIX}linux install errors correctly without identification file" {
  rm "${OS_RELEASE_TMP_FILE}"
  exp_err="Detected Linux OS but did not find '${OS_RELEASE_TMP_FILE}' file"

  LINUX_DISTRO_OS_IDENTIFICATION_FILE="${OS_RELEASE_TMP_FILE}" run initialize
  assert_failure
  assert_error_call_args "${exp_err}"
}

@test "${TEST_SUITE_PREFIX}centos bootstrapped correctly" {
  mock_grep_distro "${CENTOS_DISTRO}" "7"
  initialize

  assert_fedora_variables "${CENTOS_DISTRO}" "7" $?
}

@test "${TEST_SUITE_PREFIX}rhel bootstrapped correctly" {
  mock_grep_distro "${RHEL_DISTRO}" "8"
  initialize

  assert_fedora_variables "${RHEL_DISTRO}" "8" $?
}

@test "${TEST_SUITE_PREFIX}fedora bootstrapped correctly" {
  mock_grep_distro "${FEDORA_DISTRO}" "23"
  initialize

  assert_fedora_variables "${FEDORA_DISTRO}" "23" $?
}

@test "${TEST_SUITE_PREFIX}ubuntu bootstrapped correctly" {
  mock_grep_distro "${UBUNTU_DISTRO}" "20.04"
  initialize

  assert_debian_variables "${UBUNTU_DISTRO}" "20.04" $?
}

@test "${TEST_SUITE_PREFIX}debian bootstrapped correctly" {
  mock_grep_distro "${DEBIAN_DISTRO}" "10"
  initialize

  assert_debian_variables "${DEBIAN_DISTRO}" "10" $?
}

@test "${TEST_SUITE_PREFIX}unsupported distro errors correctly" {
  distro="super new kinda fake distro"
  mock_grep_distro "${distro}"
  run initialize
  assert_equal "$status" 1
  assert_info_call_args "Detected Linux distro: '${distro}'"
  assert_error_call_args "Unsupported distro: '${distro}'"
}

@test "${TEST_SUITE_PREFIX}linux commands prefix set correctly with root" {
  mock_grep_distro "${DEBIAN_DISTRO}"
  USER_ID=0 initialize

  assert_equal "${INSTALLER_PREFIX}" ""
  assert_equal "${INSTALL_COMMAND}" " ${DEBIAN_PACKAGE_MANAGER} ${DEBIAN_INSTALL_SUBCOMMAND} ${DEBIAN_INSTALLER_SUFFIX}"
  assert_equal "${REMOVE_COMMAND}" " ${DEBIAN_PACKAGE_MANAGER} ${DEBIAN_REMOVE_SUBCOMMAND} ${DEBIAN_REMOVE_SUFFIX}"
  assert_equal "${ADD_PACKAGE_REPOSITORY_COMMAND}" " ${PACKAGE_REPOSITORY_MANAGEMENT_TOOL}  "
}

@test "${TEST_SUITE_PREFIX}linux commands prefix set correctly without root" {
  mock_grep_distro "${FEDORA_DISTRO}"
  USER_ID=1 initialize
  assert_equal "${INSTALLER_PREFIX}" "sudo"
  assert_equal "${INSTALL_COMMAND}" "sudo ${FEDORA_PACKAGE_MANAGER} ${FEDORA_INSTALL_SUBCOMMAND} ${FEDORA_INSTALLER_SUFFIX}"
  assert_equal "${REMOVE_COMMAND}" "sudo ${FEDORA_PACKAGE_MANAGER} ${FEDORA_REMOVE_SUBCOMMAND} ${FEDORA_REMOVE_SUFFIX}"
  assert_equal "${ADD_PACKAGE_REPOSITORY_COMMAND}" "sudo ${FEDORA_PACKAGE_REPOSITORY_MANAGEMENT_TOOL} ${FEDORA_ADD_PACKAGE_REPOSITORY_SUBCOMMAND} ${FEDORA_ADD_PACKAGE_REPOSITORY_SUFFIX}"
}

@test "${TEST_SUITE_PREFIX}bitness set correctly on Mac" {
  mock_getconf_default "64"
  UNIX_NAME="Darwin" initialize
  # shellcheck disable=SC2153
  assert_equal "${BITNESS}" "64"
}

@test "${TEST_SUITE_PREFIX}bitness set correctly on Linux" {
  mock_getconf_default "32"
  mock_grep_distro "${FEDORA_DISTRO}"
  UNIX_NAME="Linux" initialize
  assert_equal "${BITNESS}" "32"
}

@test "${TEST_SUITE_PREFIX}bitness detected correctly" {
  mock_getconf true
  mock_grep_distro "${DEBIAN_DISTRO}"
  UNIX_NAME="Linux" run initialize
  assert_getconf_call_args "LONG_BIT"
}

@test "${TEST_SUITE_PREFIX}global defaults set correctly" {
  assert_equal "${USER_ID}" "${UID}"
  assert_equal "${UNIX_NAME}" "$(uname)"
  assert_equal "${MAC_OS}" "macos"
  assert_equal "${LINUX_OS}" "linux"
  assert_equal "${UBUNTU_DISTRO}" "ubuntu"
  assert_equal "${DEBIAN_DISTRO}" "debian"
  assert_equal "${FEDORA_DISTRO}" "fedora"
  assert_equal "${RHEL_DISTRO}" "rhel"
  assert_equal "${CENTOS_DISTRO}" "centos"
  assert_equal "${DEBIAN_DISTRO_FAMILY}" "debian"
  assert_equal "${FEDORA_DISTRO_FAMILY}" "fedora"

  assert_equal "${DEBIAN_PACKAGE_MANAGER}" "apt"
  assert_equal "${DEBIAN_INSTALL_SUBCOMMAND}" "install"
  assert_equal "${DEBIAN_INSTALLER_SUFFIX}" "-y --no-install-recommends"
  assert_equal "${DEBIAN_REMOVE_SUBCOMMAND}" "remove"
  assert_equal "${DEBIAN_REMOVE_SUFFIX}" "-y"
  assert_equal "${DEBIAN_PACKAGE_REPOSITORY_MANAGEMENT_TOOL}" "add-apt-repository"
  assert_equal "${FEDORA_PACKAGE_MANAGER}" "dnf"
  assert_equal "${FEDORA_INSTALL_SUBCOMMAND}" "install"
  assert_equal "${FEDORA_INSTALLER_SUFFIX}" "-y"
  assert_equal "${FEDORA_REMOVE_SUBCOMMAND}" "remove"
  assert_equal "${FEDORA_REMOVE_SUFFIX}" "-y"
  assert_equal "${FEDORA_PACKAGE_REPOSITORY_MANAGEMENT_TOOL}" "dnf"
  assert_equal "${FEDORA_ADD_PACKAGE_REPOSITORY_SUBCOMMAND}" "config-manager"
  assert_equal "${FEDORA_ADD_PACKAGE_REPOSITORY_SUFFIX}" "--add-repository"
  assert_equal "${MACOS_PACKAGE_MANAGER}" "brew"
  assert_equal "${MACOS_INSTALL_SUBCOMMAND}" "install"
  assert_equal "${MACOS_REMOVE_SUBCOMMAND}" "uninstall"
}
