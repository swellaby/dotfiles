#!/usr/bin/env bats

# shellcheck source=tests/unit/applications/browser/common.sh
source "${BATS_TEST_DIRNAME}/common.sh"
# shellcheck source=src/applications/browser/firefox/firefox.sh
source "${BROWSER_DIRECTORY}/firefox/firefox.sh"

readonly TEST_SUITE_PREFIX="${APPLICATIONS_BROWSER_SUITE_PREFIX}::firefox::install_firefox::"

@test "${TEST_SUITE_PREFIX}uses correct args" {
  mock_install
  exp_package="firefox"
  run install_firefox
  assert_success
  assert_install_call_args "--application-name Firefox --debian-family-package-name ${exp_package} --fedora-family-package-name ${exp_package} --mac-package-name ${exp_package} --mac-package-prefix --cask"
}
