#!/bin/bash
set -e

# 参数定义
PROFILE=$1
TARGET_OS=$2
ARCH=$3
VERSION=$4

CONFIG_DIR="vtx-config/profiles"
EXT=""

echo ">>> VTX FFmpeg 静态构建系统"
echo ">>> 配置: ${PROFILE} | 系统: ${TARGET_OS} | 架构: ${ARCH}"

# 获取 Git 信息
if command -v git >/dev/null 2>&1; then
    GIT_SHA=$(git rev-parse --short HEAD || echo "unknown")
else
    GIT_SHA="unknown"
fi

# 基础编译选项
COMMON_FLAGS=(
    "--prefix=/dist"
    "--enable-static"
    "--disable-shared"
    "--enable-small"
    "--disable-doc"
    "--pkg-config-flags=--static"
    "--extra-cflags=-Os"
    "--extra-cflags=-DVTX_BUILD_SHA=\\\"${GIT_SHA}\\\""
    "--extra-cflags=-DVTX_BUILD_VERSION=\\\"${VERSION}\\\""
)

# 开启 CCache
if command -v ccache >/dev/null 2>&1; then
    COMMON_FLAGS+=("--cc=ccache gcc" "--cxx=ccache g++")
fi

# Debug 模式特殊处理
if [ "$PROFILE" == "debug" ]; then
    COMMON_FLAGS+=("--enable-debug")
else
    COMMON_FLAGS+=("--disable-debug" "--extra-ldflags=-s")
fi

# 交叉编译匹配逻辑
case "${TARGET_OS}-${ARCH}" in
    linux-x86_64)
        if command -v x86_64-linux-musl-gcc >/dev/null 2>&1; then
            COMMON_FLAGS+=("--arch=x86_64" "--enable-cross-compile" "--cross-prefix=x86_64-linux-musl-")
        fi
        ;;
    linux-arm64)
        COMMON_FLAGS+=("--arch=aarch64" "--enable-cross-compile" "--cross-prefix=aarch64-linux-musl-")
        ;;
    linux-armv7)
        COMMON_FLAGS+=("--arch=arm" "--enable-cross-compile" "--cross-prefix=arm-linux-musleabi-")
        ;;
    linux-mipsel)
        COMMON_FLAGS+=("--arch=mipsel" "--enable-cross-compile" "--cross-prefix=mipsel-linux-musl-")
        COMMON_FLAGS+=("--disable-mipsdsp" "--disable-mipsdspr2")
        ;;
    linux-riscv64)
        COMMON_FLAGS+=("--arch=riscv64" "--enable-cross-compile" "--cross-prefix=riscv64-linux-musl-")
        ;;
    win-x86_64)
        COMMON_FLAGS+=("--arch=x86_64" "--target-os=mingw32" "--enable-cross-compile" "--cross-prefix=x86_64-w64-mingw32-")
        EXT=".exe"
        ;;
esac

# 加载配置
SPECIFIC_FLAGS=$(cat "${CONFIG_DIR}/${PROFILE}.conf" | tr '\n' ' ')

# 执行配置与编译
./configure "${COMMON_FLAGS[@]}" $SPECIFIC_FLAGS
make -j$(nproc)

# 归档产物
mkdir -p dist
[ -f ffmpeg${EXT} ] && cp ffmpeg${EXT} "dist/vtx-ffmpeg-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"
[ -f ffprobe${EXT} ] && cp ffprobe${EXT} "dist/vtx-ffprobe-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"

echo ">>> ✅ 构建成功"