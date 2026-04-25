#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-valgrind-linux"
LOG_FILE="${ROOT_DIR}/valgrind-definitive.log"

cd "${ROOT_DIR}"

if ! command -v cmake >/dev/null 2>&1; then
	echo "cmake not found"
	exit 1
fi

if ! command -v valgrind >/dev/null 2>&1; then
	echo "valgrind not found"
	exit 1
fi

cmake --preset valgrind-linux
cmake --build --preset valgrind-linux

VALGRIND_BIN="${BUILD_DIR}/tfs"
if [[ ! -x "${VALGRIND_BIN}" ]]; then
	echo "Valgrind build binary not found: ${VALGRIND_BIN}"
	exit 1
fi

echo "Running Valgrind without mimalloc. Log: ${LOG_FILE}"
valgrind \
	--tool=memcheck \
	--leak-check=full \
	--show-leak-kinds=definite \
	--track-origins=yes \
	--num-callers=50 \
	--leak-resolution=high \
	--error-limit=no \
	--expensive-definedness-checks=yes \
	--partial-loads-ok=yes \
	--log-file="${LOG_FILE}" \
	--error-exitcode=99 \
	"${VALGRIND_BIN}"
