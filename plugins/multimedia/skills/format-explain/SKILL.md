---
name: format-explain
description: This skill should be used when the user asks "what does this mediainfo mean", "explain this video format", "what is BT.709", "what is H.264", "container vs codec", "why is this 10bit", "what does limited range mean", or wants educational explanations of video technical concepts.
---

# Video Format Explanations

Provide clear, educational explanations of video technical concepts. Route to detailed references for in-depth information.

## Core Concepts

### Container vs Codec

**Container formats** (mkv, mp4, webm, avi, mov):
- Package that holds video, audio, subtitles, metadata
- Like a ZIP file for media streams
- Changing container = remuxing (fast, no quality loss)
- Different containers support different features (mkv supports more subtitle formats than mp4)

**Video codecs** (H.264/AVC, H.265/HEVC, VP9, AV1):
- Algorithm that compresses/decompresses video data
- The actual encoding that determines quality and file size
- Changing codec = reencoding (slow, causes quality loss)

**Key insight**: A file's extension (.mkv, .mp4) tells you the container, not the codec. An mkv and mp4 can contain identical H.264 video.

### Codec vs Encoder

**Codec/Format** (H.264, H.265): The specification/standard for how video is encoded
**Encoder** (x264, x265, NVENC): Software that creates video in that format

Different encoders produce different quality at same bitrate:
- x264/x265: Best quality, slow (CPU-based)
- NVENC/QuickSync: Fast, larger files for same quality (GPU-based)
- Apple VideoToolbox: Middle ground on macOS

### Resolution

**What it is**: Pixel dimensions (1920x1080, 3840x2160)
**What it's not**: Quality

Resolution indicates the pixel grid size, not visual fidelity. A badly encoded 4K video can look worse than a well-encoded 1080p video.

**Native vs upscaled**: Many "4K" releases are upscaled from lower resolution masters. The file has 4K pixels but no more detail than the source.

### Frame Rate

**Common rates**:
- 23.976 fps (24000/1001): Film, most streaming content
- 24 fps: True film rate (rare in digital distribution)
- 29.97 fps (30000/1001): NTSC video
- 25 fps: PAL video
- 59.94/60 fps: High frame rate, gaming content

**23.976 vs 24**: Nearly identical to viewers. The fractional rate exists for NTSC compatibility reasons from analog TV era.

**CFR vs VFR**:
- CFR (Constant Frame Rate): Every frame has same duration
- VFR (Variable Frame Rate): Frame durations vary (common in screen recordings, phone videos)

### Bit Depth

**8-bit**: Standard, 256 levels per color channel, 16.7 million colors
**10-bit**: HDR standard, 1024 levels per channel, 1 billion+ colors
**12-bit**: Professional/mastering, rarely seen in distribution

**10-bit for 8-bit content**: Encoders sometimes use 10-bit encoding for 8-bit sources because it improves compression efficiency (fewer banding artifacts).

### Bitrate

**What it measures**: Data per second (Mbps, kbps)
**What it indicates**: How much data the encoder used, not necessarily quality

Higher bitrate ≠ better quality. An inefficient encode at 20 Mbps can look worse than an efficient encode at 8 Mbps.

**VBR vs CBR**:
- VBR (Variable): Allocates bits where needed, better quality
- CBR (Constant): Fixed rate, required for some streaming, wastes bits on simple scenes

### CRF (Constant Rate Factor)

Quality-based encoding setting used by x264/x265:
- Lower CRF = higher quality, larger file
- Higher CRF = lower quality, smaller file
- Range: 0 (lossless) to 51 (worst)
- Typical: 18-23 for high quality, 23-28 for smaller files

CRF automatically adjusts bitrate based on scene complexity.

## Color Space Concepts

### Color Matrix (BT.601 vs BT.709)

Defines how YCbCr values convert to/from RGB:
- **BT.601**: Legacy standard for SD content (DVD era)
- **BT.709**: Modern standard for HD content (Blu-ray, streaming)

Wrong matrix = incorrect colors. HD content played as BT.601 will have shifted hues.

### Color Range (Limited vs Full)

**Limited range** (16-235): Standard for video, leaves headroom
**Full range** (0-255): Uses entire value range

Most video content is Limited range. Playing Limited as Full = washed out. Playing Full as Limited = crushed blacks/clipped whites.

### Chroma Subsampling

**4:4:4**: Full color resolution (rare, large files)
**4:2:2**: Half horizontal color resolution (professional)
**4:2:0**: Quarter color resolution (standard for distribution)

Human eyes are less sensitive to color detail than brightness, so 4:2:0 looks nearly identical to 4:4:4 for most content.

### HDR vs SDR

**SDR** (Standard Dynamic Range): Traditional brightness levels, ~100 nits peak
**HDR** (High Dynamic Range): Extended brightness, 1000+ nits peak, wider color gamut

HDR requires:
- 10-bit color depth (minimum)
- HDR metadata (PQ or HLG transfer function)
- Compatible display

Not all "HDR" releases are legitimate. Some are inverse tonemapped from SDR sources.

## Quick Answers

| Question | Short Answer |
|----------|--------------|
| "Is mkv better than mp4?" | Different containers, neither is "better" - mkv supports more features |
| "Should I reencode to H.265?" | Only if you need smaller files and accept quality loss |
| "Is 4K always better than 1080p?" | No - depends on source quality and encoding |
| "Why is my file so large?" | Check codec (NVENC vs x264), bitrate settings, or CRF value |
| "What's the best format?" | Depends on use case. H.264/mkv for compatibility, H.265 for size |

## Additional Resources

For detailed explanations:
- **`${CLAUDE_PLUGIN_ROOT}/references/quality-myths.md`** - Common misconceptions debunked
- **`${CLAUDE_PLUGIN_ROOT}/references/color-space.md`** - Full color space details
- **`${CLAUDE_PLUGIN_ROOT}/references/encoding-commands.md`** - Practical command examples
