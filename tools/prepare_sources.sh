#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
ARCHIVE_NAME="trdp-2.0.3.0.tar.gz"
ARCHIVE_PATH="${PROJECT_ROOT}/${ARCHIVE_NAME}"
VERSION="2.0.3.0"
BUILD_DIR="${PROJECT_ROOT}/build"
SRC_DIR="${BUILD_DIR}/trdp"
PATCH_STAMP="${SRC_DIR}/.patches-applied"

if [[ ! -f "${ARCHIVE_PATH}" ]]; then
    echo "[prepare] Missing ${ARCHIVE_NAME}." >&2
    exit 1
fi

if [[ ! -d "${SRC_DIR}/src" ]]; then
    echo "[prepare] Extracting ${ARCHIVE_NAME}" >&2
    rm -rf "${SRC_DIR}"
    mkdir -p "${BUILD_DIR}"
    tar -xzf "${ARCHIVE_PATH}" -C "${BUILD_DIR}"
    mv "${BUILD_DIR}/trdp-${VERSION}" "${SRC_DIR}"
fi

if [[ ! -f "${PATCH_STAMP}" ]]; then
    shopt -s nullglob
    patches=("${PROJECT_ROOT}/patches"/*.patch)
    for patch in "${patches[@]}"; do
        echo "[prepare] Applying $(basename "${patch}")" >&2
        patch -d "${SRC_DIR}" -p2 -N < "${patch}"
    done
    touch "${PATCH_STAMP}"
fi
