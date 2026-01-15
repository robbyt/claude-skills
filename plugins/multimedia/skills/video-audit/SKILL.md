---
name: video-audit
description: This skill should be used when the user asks to "audit this video", "analyze video quality", "check this video file", "is this video good quality", "should I reencode this", "what format is this video", or wants to understand a video file's technical properties and quality before working with it.
---

# Video File Audit

Analyze video files to understand their technical properties, identify quality issues, and recommend appropriate next steps (remux, reencode, or leave unchanged).

## Prerequisites

Requires `mediainfo` CLI tool. Install via:
- macOS: `brew install mediainfo`
- Linux: `apt install mediainfo` or equivalent
- Windows: Download from mediaarea.net

## Audit Workflow

### Step 1: Gather File Metadata

Run MediaInfo to get comprehensive file information:

```bash
mediainfo --Full "/path/to/video.mkv"
```

For quick summary:
```bash
mediainfo "/path/to/video.mkv"
```

### Step 2: Identify Container vs Codec

Extract and report separately:

**Container format** (file extension): mkv, mp4, webm, avi, mov, m2ts
- Containers store and package video/audio streams
- Changing container = remuxing (fast, lossless)

**Video codec** (actual encoding): H.264 (AVC), H.265 (HEVC), VP9, AV1, ProRes
- Codecs compress and encode the actual video data
- Changing codec = reencoding (slow, quality loss)

Key MediaInfo fields:
- `Format` under "General" section = container
- `Format` under "Video" section = codec

### Step 3: Check Color Space Parameters

Examine these fields in MediaInfo's Video section:

| Parameter | Expected Value | Problem Indicator |
|-----------|---------------|-------------------|
| Color primaries | BT.709 | BT.601 on HD content |
| Matrix coefficients | BT.709 | BT.601 on HD content |
| Transfer characteristics | BT.709 | Mismatched values |
| Color range | Limited | "Full" on broadcast content |
| Chroma subsampling | 4:2:0 | Unusual values |

**Red flags:**
- HD video (720p+) tagged as BT.601 instead of BT.709
- Mismatched matrix/primaries/transfer values
- "Full" range on content that should be "Limited"

For detailed color space information, consult `${CLAUDE_PLUGIN_ROOT}/references/color-space.md`.

### Step 4: Identify Quality Red Flags

Check MediaInfo for these warning signs:

**Encoding quality indicators:**
- `Encoded_Library`: Look for x264/x265 (good) vs NVENC/QuickSync (lower quality for archival)
- `Writing application`: Identify source (ffmpeg, Handbrake, etc.)
- `Bit rate mode`: VBR preferred over CBR for quality

**Suspicious characteristics:**
- Resolution not matching source (e.g., 4K from 1080p source = upscaled)
- Frame rate interpolated (e.g., 60fps from 24fps source)
- Very high or very low bitrate for resolution
- 10-bit encoding of 8-bit source content (acceptable, often more efficient)

**Content red flags:**
- HDR metadata on content never released in HDR (fake HDR)
- Dolby Vision on SDR-only content
- Unusual aspect ratios suggesting cropping or stretching

### Step 5: Provide Recommendations

Based on findings, recommend one of:

**Leave unchanged** when:
- Container and codec match intended use
- Color space parameters are correct
- No quality red flags detected
- File works with target application/device

**Remux only** when:
- Need different container (e.g., mkv→mp4 for compatibility)
- Container change doesn't require reencoding
- Color space just needs retagging (not conversion)

**Reencode required** when:
- Codec incompatible with target device
- Source has fixable quality issues (wrong matrix applied, not just mistagged)
- File size reduction needed (with quality tradeoff warning)

**Avoid/warn** when:
- Video already heavily compressed (reencoding will compound quality loss)
- User wants to upscale resolution (quality loss, not gain)
- User wants to interpolate frame rate (quality loss)

## Quick Reference: Container vs Codec

| If user says... | They probably mean... | Actual operation |
|-----------------|----------------------|------------------|
| "Convert mkv to mp4" | Change container | Remux (fast, lossless) |
| "Compress this video" | Reduce file size | Reencode (slow, quality loss) |
| "Make it H.265" | Change codec | Reencode (slow, quality loss) |
| "Fix the colors" | Depends on issue | Retag (fast) or reencode (slow) |

## Additional Resources

### Reference Files

For detailed technical information, consult:
- **`${CLAUDE_PLUGIN_ROOT}/references/quality-myths.md`** - Why resolution/bitrate don't equal quality
- **`${CLAUDE_PLUGIN_ROOT}/references/color-space.md`** - Color matrices, range, chroma location
- **`${CLAUDE_PLUGIN_ROOT}/references/tools.md`** - Recommended and discouraged tools
- **`${CLAUDE_PLUGIN_ROOT}/references/encoding-commands.md`** - ffmpeg/mpv command templates
