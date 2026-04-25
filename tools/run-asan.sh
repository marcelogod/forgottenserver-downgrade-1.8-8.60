#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-asan-linux"
LOG_PREFIX="${ROOT_DIR}/asan"

cd "${ROOT_DIR}"

if ! command -v cmake >/dev/null 2>&1; then
	echo "cmake not found"
	exit 1
fi

cmake --preset asan-linux
cmake --build --preset asan-linux

ASAN_BIN="${BUILD_DIR}/tfs"
if [[ ! -x "${ASAN_BIN}" ]]; then
	echo "ASan build binary not found: ${ASAN_BIN}"
	exit 1
fi

# Keep string interceptors in the default/compatible mode. libmysqlclient can
# trip strict string checks during mysql_real_connect before the server starts.
export ASAN_OPTIONS="abort_on_error=1:detect_leaks=1:detect_stack_use_after_return=1:check_initialization_order=1:strict_init_order=1:strict_string_checks=0:log_path=${LOG_PREFIX}"
export UBSAN_OPTIONS="print_stacktrace=1:halt_on_error=1:log_path=${LOG_PREFIX}-ubsan"

echo "Running AddressSanitizer without mimalloc."
echo "ASan logs will be written as ${LOG_PREFIX}.<pid> if an error is detected."
"${ASAN_BIN}"
