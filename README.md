# VTX FFmpeg Release

![Build Status](https://github.com/Vtxdeo/vtx-ffmpeg-release/actions/workflows/build.yml/badge.svg)
![License](https://img.shields.io/github/license/Vtxdeo/vtx-ffmpeg-release)
![Release](https://img.shields.io/github/v/release/Vtxdeo/vtx-ffmpeg-release)

> **Tailored FFmpeg Static Binaries for "Device No Lower Limit" Philosophy.**

This repository provides automated, reproducible, and highly customized **static builds** of FFmpeg. Designed for the `vtx-core` ecosystem, it focuses on extreme size optimization and absolute portability across Linux distributions (Alpine, Debian, OpenWrt, etc.).

## Key Features

- **Zero Dependency**: Statically linked with `musl libc`. Runs on any Linux kernel without external libraries.
- **Extreme Size Optimization**: Aggressively stripped binaries via custom profiles.
- **Multi-Architecture**: Supports `x86_64` (and `aarch64`/`armv7` planned).
- **Automated Workflow**: Built transparently using GitHub Actions.

## Profiles

We now offer **14 specialized profiles** organized into 5 categories, moving beyond simple size constraints to target specific application scenarios.

**Quick Summary:**

* **General Purpose**: `nano`, `micro`, `mini`, `full` (Balanced for general use)
* **Ingest & IO**: `stream`, `indexer`, `audio` (Protocol & demuxer focused)
* **Processing**: `remux`, `transcode`, `animator` (Pipeline optimization)
* **Delivery**: `vod`, `archive` (Distribution & Storage)
* **Specialized**: `debug`, `legacy` (Maintenance & Compatibility)

> 📘 **Detailed Documentation**
>
> Please refer to the **[Profile Manifesto](docs/PROFILES.md)** for a comprehensive matrix of capabilities, codecs, and target use cases.

## Usage

### Download
Go to the [Releases Page](../../releases) and download the binary matching your architecture and profile.

### Integration (Manual)
```bash
# Example: Deploying Nano profile on a router
wget [https://github.com/Vtxdeo/vtx-ffmpeg-release/releases/latest/download/vtx-ffprobe-x86_64-nano](https://github.com/Vtxdeo/vtx-ffmpeg-release/releases/latest/download/vtx-ffprobe-x86_64-nano)
chmod +x vtx-ffprobe-x86_64-nano
mv vtx-ffprobe-x86_64-nano /usr/local/bin/ffprobe

```

### Integration (vtx-core)

`vtx-core` will automatically detect these binaries if placed in the configured media path. No installation required.

## Building Locally

If you want to build these binaries yourself using Docker:

```bash
# 1. Clone the repo
git clone [https://github.com/Vtxdeo/vtx-ffmpeg-release.git](https://github.com/Vtxdeo/vtx-ffmpeg-release.git)
cd vtx-ffmpeg-release

# 2. Run build script (requires Alpine environment or Docker)
docker run -it -v $(pwd):/workspace -w /workspace alpine:latest sh

# Inside Docker:
apk add build-base perl pkgconf yasm nasm git linux-headers bash coreutils file
./scripts/build.sh nano x86_64

```

## License & Legal

**Build Scripts**: The build scripts and configurations in this repository are released under the [MIT License](https://www.google.com/search?q=LICENSE).

**Binaries**: The released binaries contain software from the FFmpeg project and other third-party libraries.

* Binaries are statically linked.
* Depending on the profile (e.g., if `transcode` or `full` is used), the binaries may be subject to various open source licenses including **GPL v3**.
* Please consult the `LICENSE` output of the specific binary (`ffmpeg -L`) for exact licensing terms.

**Disclaimer**: This project is not affiliated with the FFmpeg project. FFmpeg is a trademark of Fabrice Bellard.