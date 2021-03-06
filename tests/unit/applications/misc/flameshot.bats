#!/usr/bin/env bats

# shellcheck source=tests/unit/applications/misc/common.sh
source "${BATS_TEST_DIRNAME}/common.sh"
# shellcheck source=src/applications/misc/flameshot/flameshot.sh
source "${MISC_DIRECTORY}/flameshot/flameshot.sh"

readonly TEST_SUITE_PREFIX="${APPLICATIONS_MISC_SUITE_PREFIX}::flameshot::install_flameshot::"

function setup() {
  # shellcheck source=src/utils.sh
  source "${UTILS_SOURCE_PATH}"
  mock_install
  mock_error
}

@test "${TEST_SUITE_PREFIX}uses correct args on Linux" {
  OPERATING_SYSTEM="${LINUX_OS}" run install_flameshot
  assert_success
  assert_install_call_args "--application-name Flameshot --debian-family-package-name flameshot --fedora-family-package-name flameshot"
}

@test "${TEST_SUITE_PREFIX}prints error on Mac" {
  OPERATING_SYSTEM="${MAC_OS}" run install_flameshot
  assert_success
  assert_error_call_args "Flameshot installation is not currently supported on Mac"
}
