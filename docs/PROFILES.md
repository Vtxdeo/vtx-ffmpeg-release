# VTX FFmpeg Profile Manifesto

This document details the design purpose, applicable scenarios, and technical boundaries of all build profiles in the VTX FFmpeg Release repository. This list is intended to guide developers and automation tools in selecting the optimal binary version for different hardware and business requirements.

## 1. General Purpose
These profiles are prioritized by **size** and are suitable for general scenarios where functional boundaries are not strictly defined.

| Profile | Target Size | Core Capability | Typical Use Cases |
| :--- | :--- | :--- | :--- |
| **nano** | ~1 MB | **Metadata Extraction**.<br>Contains `ffprobe` only. Supports demuxing of common formats. No transcoding capabilities. | File upload validation, duration detection, initial media library scanning. |
| **micro** | ~5 MB | **Thumbnail Generation**.<br>Includes basic H.264/HEVC decoding + MJPEG/PNG encoding. Supports scaling. | Cover art generation services on Raspberry Pi Zero or low-end NAS. |
| **mini** | ~15 MB | **General Media Processing**.<br>Includes common filters and audio encoders. Balances size and functionality. | Personal cloud storage, lightweight transcoding tasks, home labs. |
| **full** | >50 MB | **Full Feature Set**.<br>Enables all compilation options, filters, and non-free protocols. | Desktop applications, high-performance servers, development environments. |

## 2. Ingest & IO
These profiles focus on the "acquisition" and "identification" of media streams, typically running on the network edge or gateway devices with limited computing power.

| Profile | Core Capability | Key Components | Typical Use Cases |
| :--- | :--- | :--- | :--- |
| **stream** | **Stream Forwarding**.<br>Focused on protocol support with minimal CPU usage. | Protocols: `rtmp`, `rtsp`, `hls`<br>Filters: Optimized for `copy` mode | Live streaming boxes, security camera integration, drone feed forwarding. |
| **indexer** | **Universal Indexing**.<br>Extreme demuxing compatibility, sacrificing encoding for reading capabilities. | Decoders: `vp9`, `av1`, `webm`, `wmv`<br>Filters: `select`, `tile` (Sprite Sheets) | Scanning agents for Media Asset Management (MAM) systems, cloud storage analysis. |
| **audio** | **Audio-Only Processing**.<br>Strips all video components to focus on audio transcoding and analysis. | Encoders: `aac`, `flac`, `opus`, `mp3`<br>Filters: `silencedetect`, `volume` | Online radio, podcast hosting backends, audiobook applications. |

## 3. Processing Pipeline
These profiles are designed for core compute nodes, clearly dividing tasks based on workload type (IO-bound vs. CPU-bound).

| Profile | Core Capability | Key Components | Typical Use Cases |
| :--- | :--- | :--- | :--- |
| **remux** | **Container Conversion**.<br>No transcoding involved. Changes container formats only. Extremely fast. | Muxers: `mp4`, `mkv`, `mov`, `ts`<br>Feat: Bitstream Filtering (BSF) | Video upload preprocessing (e.g., MKV to MP4), lossless editing. |
| **transcode** | **Full Transcoding**.<br>Uses FFmpeg native codecs for software decoding and encoding. | Encoders: `mpeg4`, `prores`, `aac`<br>Compat: Zero-dependency static linking | Dedicated transcoding clusters, format factory services, video restoration. |
| **animator** | **Animation Generation**.<br>Focused on generating high-quality GIF/WebP/APNG. | Filters: `palettegen`, `paletteuse`<br>Encoders: `gif`, `apng` | Meme creation tools, social media snippet generation. |

## 4. Delivery & Storage
These profiles focus on the "final form" of media files, whether for web distribution or long-term cold storage.

| Profile | Core Capability | Key Components | Typical Use Cases |
| :--- | :--- | :--- | :--- |
| **vod** | **Segmentation & Delivery**.<br>Generates streaming segments suitable for H5 players. | Muxers: `hls`, `dash`, `segment`<br>Feat: Multi-bitrate manifest generation | Self-hosted video hosting, VOD services for online education platforms. |
| **archive** | **Lossless Preservation**.<br>Ensures AV data remains readable by open-source software for decades. | Encoders: `ffv1` (Video), `flac` (Audio)<br>Containers: `mkv`, `nut` | Library/Museum digital asset vaults, raw footage cold backup. |

## 5. Specialized
Special versions tailored for specific hardware limitations or operational debugging needs.

| Profile | Core Capability | Key Components | Typical Use Cases |
| :--- | :--- | :--- | :--- |
| **debug** | **Fault Analysis**.<br>Includes detailed logging output and visual analysis tools. | Filters: `trace_headers`, `datascope`, `vectorscope` | Production environment troubleshooting, encoding parameter tuning analysis. |
| **legacy** | **Legacy Compatibility**.<br>Disables advanced instruction sets to ensure stability on low-end architectures. | Disabled: `asm`, `pthreads` (partial)<br>Arch: MIPS, ARMv5 | Running on decade-old routers, set-top boxes, or embedded industrial PCs. |

---

## Decision Guide

Refer to the following logic when selecting a VTX FFmpeg profile:

1.  **Do you need to process video frames?**
    * No (Audio only) -> `audio`
    * No (Metadata only) -> `nano`
    * Yes -> *Go to Step 2*

2.  **Do you need to modify video encoding (Transcode)?**
    * No (Container swap only) -> `remux`
    * No (Push/Copy only) -> `stream`
    * Yes -> *Go to Step 3*

3.  **Is the target for Web Playback or Download?**
    * Web Streaming -> `vod`
    * Animation Sharing -> `animator`
    * Archival Storage -> `archive`
    * General/Unknown -> *Go to Step 4*

4.  **What is the hardware environment?**
    * Extremely Restricted (IoT/Router) -> `micro` (Basic) or `legacy` (Compat)
    * Standard (NAS/PC) -> `mini` (Balanced)
    * Dedicated Compute Node -> `transcode` (Soft-code) or `full` (Complete)
    * Debugging Issues -> `debug`