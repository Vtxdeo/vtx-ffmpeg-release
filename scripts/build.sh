#!/bin/bash
set -e

# 参数获取
PROFILE=$1
ARCH=$2
CONFIG_DIR="vtx-config/profiles"

# 检查配置文件是否存在
if [ ! -f "${CONFIG_DIR}/${PROFILE}.conf" ]; then
    echo "Error: 配置文件未找到：${CONFIG_DIR}/${PROFILE}.conf"
    exit 1
fi

echo ">>> 开始构建过程"
echo ">>> 配置文件: ${PROFILE}"
echo ">>> 架构: ${ARCH}"

# 定义通用优化参数
# 目标：静态链接，去除调试信息，尽可能缩小体积
COMMON_FLAGS=(
    "--prefix=/dist"
    "--enable-static"
    "--disable-shared"
    "--disable-debug"
    "--enable-small"
    "--disable-doc"
    "--disable-htmlpages"
    "--disable-manpages"
    "--disable-podpages"
    "--disable-txtpages"
    "--pkg-config-flags=--static"
    "--extra-cflags=-Os"   # 优化编译器体积
    "--extra-ldflags=-s"   # 优化链接器体积
)

# 2. 读取 Profile 特有参数
SPECIFIC_FLAGS=$(cat "${CONFIG_DIR}/${PROFILE}.conf" | tr '\n' ' ')

echo ">>> 正在配置 FFmpeg..."
# 打印配置命令，便于调试
echo "./configure --arch=${ARCH} ${COMMON_FLAGS[*]} ${SPECIFIC_FLAGS}"

# 3. 执行配置过程
./configure --arch="${ARCH}" "${COMMON_FLAGS[@]}" $SPECIFIC_FLAGS

echo ">>> 开始编译 (此过程可能需要一些时间)..."
# 使用所有核心进行编译
make -j$(nproc)

echo ">>> 正在剥离二进制文件..."
# 强制执行 strip 操作，进一步减少文件体积
strip ffmpeg 2>/dev/null || true
strip ffprobe 2>/dev/null || true

echo ">>> 构建完成！"