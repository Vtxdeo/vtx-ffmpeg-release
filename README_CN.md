# VTX FFmpeg Release

![Build Status](https://github.com/Vtxdeo/vtx-ffmpeg-release/actions/workflows/build.yml/badge.svg)
![License](https://img.shields.io/github/license/Vtxdeo/vtx-ffmpeg-release)
![Release](https://img.shields.io/github/v/release/Vtxdeo/vtx-ffmpeg-release)

**专为“无设备下限”理念量身定制的 FFmpeg 静态二进制构建。**

本项目提供经过自动化、可重现并高度定制化的**静态构建** FFmpeg，专为 `vtx-core` 生态系统设计，旨在极限优化二进制文件体积并确保跨不同 Linux 发行版（包括 Alpine、Debian、OpenWrt 等）具备绝对的可移植性。

## 主要特点

* **零依赖**：使用 `musl libc` 静态链接，无需外部库支持，可在任何 Linux 内核上运行。
* **极限体积优化**：通过自定义配置剥离多余功能，最大化减少二进制文件体积。
* **多架构支持**：当前支持 `x86_64`，未来计划支持 `aarch64` 和 `armv7`。
* **自动化工作流**：通过 GitHub Actions 完成透明的构建过程。

## 构建配置 (Profiles)

我们现在提供 **14 种专业预设**，分为 5 大类，超越了单纯的体积限制，转为针对垂直应用场景进行优化。

**快速概览：**

* **基础通用 (General)**: `nano`, `micro`, `mini`, `full` (体积优先)
* **输入接入 (Ingest)**: `stream`, `indexer`, `audio` (专注协议与读取)
* **核心处理 (Processing)**: `remux`, `transcode`, `animator` (流水线优化)
* **交付归档 (Delivery)**: `vod`, `archive` (分发与冷存)
* **特殊用途 (Specialized)**: `debug`, `legacy` (运维与兼容)

> 📘 **详细文档**
>
> 请查阅 **[预设场景清单](docs/PROFILES.md)** 以获取所有预设的能力矩阵、编码支持及适用场景的详细说明。

## 使用指南

### 下载

请访问 [发布页面](../../releases)，下载适合您架构和配置文件的二进制文件。

### 集成方式（手动）

```bash
# 示例：在路由器上部署 Nano 配置文件
wget [https://github.com/Vtxdeo/vtx-ffmpeg-release/releases/latest/download/vtx-ffprobe-x86_64-nano](https://github.com/YourUsername/vtx-ffmpeg-release/releases/latest/download/vtx-ffprobe-x86_64-nano)
chmod +x vtx-ffprobe-x86_64-nano
mv vtx-ffprobe-x86_64-nano /usr/local/bin/ffprobe

```

### 集成方式 (vtx-core)

如果将二进制文件放置在配置的媒体路径下，`vtx-core` 将自动检测并使用这些二进制文件，无需额外安装。

## 本地构建

如果您希望在本地自行构建这些二进制文件，可以通过 Docker 进行构建：

```bash
# 1. 克隆仓库
git clone [https://github.com/Vtxdeo/vtx-ffmpeg-release.git](https://github.com/Vtxdeo/vtx-ffmpeg-release.git)
cd vtx-ffmpeg-release

# 2. 运行构建脚本（需要 Alpine 环境或 Docker）
docker run -it -v $(pwd):/workspace -w /workspace alpine:latest sh

# 在 Docker 内：
apk add build-base perl pkgconf yasm nasm git linux-headers bash coreutils file
./scripts/build.sh nano x86_64

```

## 许可证与法律

**构建脚本**：本仓库中的构建脚本和配置文件采用 [MIT 许可证](https://www.google.com/search?q=LICENSE) 发布。

**二进制文件**：发布的二进制文件包含来自 FFmpeg 项目及其他第三方库的开源软件。

* 二进制文件已静态链接。
* 根据不同配置文件（例如使用了 `transcode` 或 `full`），这些二进制文件可能会受到 **GPL v3 许可证** 等开源协议的约束。
* 请查阅具体二进制文件的 `LICENSE` 输出（使用 `ffmpeg -L` 命令）以了解详细的许可证条款。

**免责声明**：本项目与 FFmpeg 项目无关，FFmpeg 是 Fabrice Bellard 的商标。