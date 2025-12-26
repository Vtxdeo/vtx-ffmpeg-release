#!/bin/bash
set -e

# Parameter definitions
PROFILE=$1    # Configuration profile, possible values: nano / micro / mini / full
TARGET_OS=$2  # Target operating system: linux / win
ARCH=$3       # Target architecture: x86_64 / arm64 / armv7 / mipsel / riscv64
VERSION=$4    # Version number: v0.0.x

CONFIG_DIR="vtx-config/profiles"
EXT=""

echo ">>> VTX FFmpeg Static Build System"
echo ">>> Profile: ${PROFILE} | OS: ${TARGET_OS} | Architecture: ${ARCH}"

# Get Git information
if command -v git >/dev/null 2>&1; then
    GIT_SHA=$(git rev-parse --short HEAD || echo "unknown")
else
    GIT_SHA="unknown"
fi

# Construct version identifier (e.g., vtx-v0.0.8-a5e16b0)
VTX_IDENTITY="vtx-${VERSION}-${GIT_SHA}"
echo ">>> Version Identifier: ${VTX_IDENTITY}"

# Base build options
COMMON_FLAGS=(
    "--prefix=/dist"
    "--enable-static"
    "--disable-shared"
    "--enable-small"
    "--disable-doc"
    "--pkg-config-flags=--static"
    "--extra-cflags=-Os"

    # === Version Injection ===
    # 1. Make ffmpeg -version display the VTX identifier
    "--extra-version=${VTX_IDENTITY}"
    # 2. Define macros for internal code use
    "--extra-cflags=-DVTX_BUILD_SHA=\\\"${GIT_SHA}\\\""
    "--extra-cflags=-DVTX_BUILD_VERSION=\\\"${VERSION}\\\""
)

# Special handling for Debug mode
if [ "$PROFILE" == "debug" ]; then
    echo ">>> DEBUG Mode: Retaining debug symbols"
    COMMON_FLAGS+=("--enable-debug")
else
    COMMON_FLAGS+=("--disable-debug" "--extra-ldflags=-s")
fi

# === Cross-compilation and architecture matching ===
case "${TARGET_OS}-${ARCH}" in
    linux-x86_64)
        # Prefer detecting Musl compiler
        if command -v x86_64-linux-musl-gcc >/dev/null 2>&1; then
            echo ">>> Using x86_64-linux-musl-gcc for static build"
            COMMON_FLAGS+=("--arch=x86_64" "--target-os=linux" "--enable-cross-compile" "--cross-prefix=x86_64-linux-musl-")
        else
            echo ">>> Musl compiler not found, using host GCC (Glibc)"
            COMMON_FLAGS+=("--arch=x86_64" "--target-os=linux")
        fi
        ;;
    linux-arm64)
        COMMON_FLAGS+=("--arch=aarch64" "--target-os=linux" "--enable-cross-compile" "--cross-prefix=aarch64-linux-musl-")
        ;;
    linux-armv7)
        COMMON_FLAGS+=("--arch=arm" "--target-os=linux" "--enable-cross-compile" "--cross-prefix=arm-linux-musleabi-")
        ;;
    linux-mipsel)
        COMMON_FLAGS+=("--arch=mipsel" "--target-os=linux" "--enable-cross-compile" "--cross-prefix=mipsel-linux-musl-")
        COMMON_FLAGS+=("--cpu=mips32r2" "--extra-cflags=-march=mips32r2")
        COMMON_FLAGS+=("--disable-mipsdsp" "--disable-mipsdspr2")
        ;;
    linux-riscv64)
        COMMON_FLAGS+=("--arch=riscv64" "--target-os=linux" "--enable-cross-compile" "--cross-prefix=riscv64-linux-musl-")
        ;;
    win-x86_64)
        COMMON_FLAGS+=("--arch=x86_64" "--target-os=mingw32" "--enable-cross-compile" "--cross-prefix=x86_64-w64-mingw32-")
        EXT=".exe"
        ;;
    *)
        echo "❌ Error: Unsupported target combination: ${TARGET_OS}-${ARCH}"
        exit 1
        ;;
esac

# Configuration file check
if [ ! -f "${CONFIG_DIR}/${PROFILE}.conf" ]; then
    echo "❌ Error: Configuration file not found: ${CONFIG_DIR}/${PROFILE}.conf"
    exit 1
fi

# Load configuration
SPECIFIC_FLAGS=$(cat "${CONFIG_DIR}/${PROFILE}.conf" | tr '\n' ' ')

echo ">>> Configuring FFmpeg..."
# Print the command for debugging purposes
echo ">>> ./configure ${COMMON_FLAGS[@]} ${SPECIFIC_FLAGS}"

# Perform the build
./configure "${COMMON_FLAGS[@]}" $SPECIFIC_FLAGS
make -j$(nproc)

# Archive the build artifacts
mkdir -p dist
OUT_FFMPEG="vtx-ffmpeg-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"
OUT_FFPROBE="vtx-ffprobe-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"

# If ffmpeg is generated
if [ -f ffmpeg${EXT} ]; then
    cp ffmpeg${EXT} "dist/${OUT_FFMPEG}"
    echo ">>> Generated: ${OUT_FFMPEG}"
fi

# If ffprobe is generated
if [ -f ffprobe${EXT} ]; then
    cp ffprobe${EXT} "dist/${OUT_FFPROBE}"
    echo ">>> Generated: ${OUT_FFPROBE}"
fi

echo ">>> ✅ Build Successful"