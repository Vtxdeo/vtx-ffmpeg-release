#!/bin/bash
set -e

# Updated profile list:
# nano / micro / mini / full
# stream / indexer / audio
# remux / transcode / animator
# vod / archive
# debug / legacy
PROFILE=$1
TARGET_OS=$2  # 目标操作系统: linux / win
ARCH=$3       # x86_64 / arm64 / armv7 / mipsel / riscv64
VERSION=$4    # 版本号

CONFIG_DIR="vtx-config/profiles"
EXT=""

echo ">>> 开始构建过程"
echo ">>> 配置文件: ${PROFILE}"
echo ">>> 目标操作系统: ${TARGET_OS} / 架构: ${ARCH}"
echo ">>> 版本号: ${VERSION}"

# 获取当前 Git Commit SHA (用于注入构建元数据)
if command -v git >/dev/null 2>&1; then
    GIT_SHA=$(git rev-parse --short HEAD || echo "unknown")
else
    GIT_SHA="unknown"
fi
echo ">>> 构建 Commit SHA: ${GIT_SHA}"

# 基础通用参数
COMMON_FLAGS=(
    "--prefix=/dist"
    "--enable-static"
    "--disable-shared"
    "--enable-small"
    "--disable-doc"
    "--disable-htmlpages"
    "--disable-manpages"
    "--disable-podpages"
    "--disable-txtpages"
    "--pkg-config-flags=--static"
    "--extra-cflags=-Os"
    # 将版本和 Commit SHA 注入到 CFLAGS，这样运行 ffmpeg 时会在 banner 中显示
    "--extra-cflags=-DVTX_BUILD_SHA=\\\"${GIT_SHA}\\\""
    "--extra-cflags=-DVTX_BUILD_VERSION=\\\"${VERSION}\\\""
)

if command -v ccache >/dev/null 2>&1; then
    echo ">>> 启用 CCache"
    COMMON_FLAGS+=("--cc=ccache gcc" "--cxx=ccache g++")
fi

# === 特殊预设处理 ===
if [ "$PROFILE" == "debug" ]; then
    echo ">>> ⚠️ DEBUG 模式: 禁用 Strip，保留调试符号"
    COMMON_FLAGS+=("--enable-debug")
else
    COMMON_FLAGS+=("--disable-debug")
    COMMON_FLAGS+=("--extra-ldflags=-s")
fi

# === 3. 交叉编译配置 ===
case "${TARGET_OS}-${ARCH}" in
    linux-x86_64)
        # 本地编译，无需前缀
        ;;
    linux-arm64)
        COMMON_FLAGS+=("--arch=aarch64" "--enable-cross-compile" "--cross-prefix=aarch64-linux-musl-")
        ;;
    linux-armv7)
        COMMON_FLAGS+=("--arch=arm" "--enable-cross-compile" "--cross-prefix=arm-linux-musleabi-")
        ;;
    linux-mipsel)
        COMMON_FLAGS+=("--arch=mipsel" "--enable-cross-compile" "--cross-prefix=mipsel-linux-musl-")
        # MIPS 架构需禁用 DSP 指令以提高兼容性
        COMMON_FLAGS+=("--disable-mipsdsp" "--disable-mipsdspr2")
        ;;
    linux-riscv64)
        COMMON_FLAGS+=("--arch=riscv64" "--enable-cross-compile" "--cross-prefix=riscv64-linux-musl-")
        ;;
    win-x86_64)
        COMMON_FLAGS+=("--arch=x86_64" "--target-os=mingw32" "--enable-cross-compile" "--cross-prefix=x86_64-w64-mingw32-")
        EXT=".exe"
        ;;
    *)
        echo "❌ 错误: 不支持的目标组合: ${TARGET_OS}-${ARCH}"
        exit 1
        ;;
esac

if [ ! -f "${CONFIG_DIR}/${PROFILE}.conf" ]; then
    echo "❌ 错误: 配置文件未找到: ${CONFIG_DIR}/${PROFILE}.conf"
    exit 1
fi
SPECIFIC_FLAGS=$(cat "${CONFIG_DIR}/${PROFILE}.conf" | tr '\n' ' ')

echo ">>> 配置 FFmpeg..."
echo ">>> 配置命令: ./configure ${COMMON_FLAGS[@]} ${SPECIFIC_FLAGS}"
./configure "${COMMON_FLAGS[@]}" $SPECIFIC_FLAGS
echo ">>> 编译中..."
make -j$(nproc)
echo ">>> 打包产物..."
mkdir -p dist

OUT_FFMPEG="vtx-ffmpeg-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"
OUT_FFPROBE="vtx-ffprobe-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"

if [ -f ffmpeg${EXT} ]; then
    cp ffmpeg${EXT} "dist/${OUT_FFMPEG}"
    echo ">>> 生成文件: ${OUT_FFMPEG}"
fi

if [ -f ffprobe${EXT} ]; then
    cp ffprobe${EXT} "dist/${OUT_FFPROBE}"
    echo ">>> 生成文件: ${OUT_FFPROBE}"
fi

echo ">>> ✅ 构建过程完成"