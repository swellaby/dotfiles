#!/usr/bin/env bash

readonly CURRENT_DIR=$(dirname "${BASH_SOURCE[0]}")

source "${CURRENT_DIR}/../../../utils.sh"
source "${CURRENT_DIR}/vscode.sh"

install_default_vscode_extensions
