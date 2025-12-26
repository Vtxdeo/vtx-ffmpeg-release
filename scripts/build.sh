#!/bin/bash
set -e

# 参数定义
PROFILE=$1    # 配置文件，可能的值: nano / micro / mini / full
TARGET_OS=$2  # 目标操作系统: linux / win
ARCH=$3       # 目标架构: x86_64 / arm64 / armv7 / mipsel / riscv64
VERSION=$4    # 版本号: v0.0.x

CONFIG_DIR="vtx-config/profiles"
EXT=""

echo ">>> 开始构建 VTX FFmpeg 静态构建系统"
echo ">>> 配置: ${PROFILE} | 目标操作系统: ${TARGET_OS} | 架构: ${ARCH}"

# 获取 Git 提交信息
if command -v git >/dev/null 2>&1; then
    GIT_SHA=$(git rev-parse --short HEAD || echo "unknown")
else
    GIT_SHA="unknown"
fi

# 构造版本标识 (例如: vtx-v0.0.8-a5e16b0)
VTX_IDENTITY="vtx-${VERSION}-${GIT_SHA}"
echo ">>> 版本标识: ${VTX_IDENTITY}"

# 基础编译选项
COMMON_FLAGS=(
    "--prefix=/dist"
    "--enable-static"
    "--disable-shared"
    "--enable-small"
    "--disable-doc"
    "--pkg-config-flags=--static"
    "--extra-cflags=-Os"

    # 版本信息注入
    "--extra-version=${VTX_IDENTITY}"
    "--extra-cflags=-DVTX_BUILD_SHA=\\\"${GIT_SHA}\\\""
    "--extra-cflags=-DVTX_BUILD_VERSION=\\\"${VERSION}\\\""
)

# Debug 模式特殊处理
if [ "$PROFILE" == "debug" ]; then
    echo ">>> DEBUG 模式: 保留调试符号"
    COMMON_FLAGS+=("--enable-debug")
else
    COMMON_FLAGS+=("--disable-debug" "--extra-ldflags=-s")
fi

# === 交叉编译与架构匹配 ===
case "${TARGET_OS}-${ARCH}" in
    linux-x86_64)
        # 优先检测 Musl 编译器
        if command -v x86_64-linux-musl-gcc >/dev/null 2>&1; then
            echo ">>> 使用 x86_64-linux-musl-gcc 进行静态构建"
            COMMON_FLAGS+=("--arch=x86_64" "--target-os=linux" "--enable-cross-compile" "--cross-prefix=x86_64-linux-musl-")
        else
            echo ">>> 未检测到 Musl 编译器，使用宿主 GCC (Glibc)"
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
        echo "❌ 错误: 不支持的目标组合: ${TARGET_OS}-${ARCH}"
        exit 1
        ;;
esac

# 配置文件检查
if [ ! -f "${CONFIG_DIR}/${PROFILE}.conf" ]; then
    echo "❌ 错误: 配置文件未找到: ${CONFIG_DIR}/${PROFILE}.conf"
    exit 1
fi

# 加载特定配置
SPECIFIC_FLAGS=$(cat "${CONFIG_DIR}/${PROFILE}.conf" | tr '\n' ' ')

# 配置 FFmpeg
echo ">>> 配置 FFmpeg..."
# 打印配置命令用于调试
echo ">>> ./configure ${COMMON_FLAGS[@]} ${SPECIFIC_FLAGS}"

# 执行配置与编译
./configure "${COMMON_FLAGS[@]}" $SPECIFIC_FLAGS
make -j$(nproc)

# 归档产物
mkdir -p dist
OUT_FFMPEG="vtx-ffmpeg-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"
OUT_FFPROBE="vtx-ffprobe-${VERSION}-${TARGET_OS}-${ARCH}-${PROFILE}${EXT}"

# 如果生成了 ffmpeg
if [ -f ffmpeg${EXT} ]; then
    cp ffmpeg${EXT} "dist/${OUT_FFMPEG}"
    echo ">>> 生成: ${OUT_FFMPEG}"
fi

# 如果生成了 ffprobe
if [ -f ffprobe${EXT} ]; then
    cp ffprobe${EXT} "dist/${OUT_FFPROBE}"
    echo ">>> 生成: ${OUT_FFPROBE}"
fi

echo ">>> ✅ 构建成功"
