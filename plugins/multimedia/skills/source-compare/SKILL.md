---
name: source-compare
description: This skill should be used when the user asks "compare these videos", "which source is better", "compare blu-ray vs web", "which release should I use", "compare video quality", or needs to evaluate multiple versions of the same content to determine which has better quality.
---

# Video Source Comparison

Compare multiple video sources to determine which has better quality. Higher bitrate or resolution does not automatically mean better quality.

## Core Principle

Quality = how closely video resembles original master.

When comparing sources:
- Both derive from some common master
- The better source is closer to that master
- Technical specs (bitrate, resolution) are secondary to actual visual quality

## Comparison Workflow

### Step 1: Gather Metadata

Run MediaInfo on both sources:
```bash
mediainfo source_a.mkv > source_a_info.txt
mediainfo source_b.mkv > source_b_info.txt
```

Compare:
- Resolution
- Bitrate
- Encoder used
- Color space parameters
- HDR metadata (if applicable)

**Note**: Higher numbers don't guarantee better quality.

### Step 2: Extract Comparison Frames

Choose frames that reveal quality differences:

**Good comparison frames**:
- Dark scenes with gradients (reveals banding)
- Scenes with fine texture (hair, fabric, foliage)
- High motion scenes (reveals compression)
- Scenes with text or sharp edges (reveals filtering)
- Areas with strong colors (reveals color handling)

**Extract frames with ffmpeg**:
```bash
# Extract frame at specific timestamp
ffmpeg -ss 00:15:30 -i source.mkv -frames:v 1 frame_15m30s.png

# Extract multiple frames
ffmpeg -ss 00:10:00 -i source.mkv -frames:v 1 frame1.png
ffmpeg -ss 00:25:00 -i source.mkv -frames:v 1 frame2.png
ffmpeg -ss 00:45:00 -i source.mkv -frames:v 1 frame3.png
```

### Step 3: Visual Comparison

**Using SlowPics** (https://slow.pics):
1. Upload comparison frames from each source
2. Uncheck "Show border" and "Smooth scaling"
3. Use clicker mode (not slider)
4. Press number keys (1/2/3) to switch rapidly between sources

**What to look for**:

| Area | Better Source Shows |
|------|---------------------|
| Dark gradients | Smoother transitions, less banding |
| Edges | Clean edges, no haloing/ringing |
| Textures | Preserved grain/detail, not smeared |
| Colors | Natural, not oversaturated or shifted |
| Compression | Less blocking, less mosquito noise |

### Step 4: Check for Filtering

**Signs of harmful filtering**:

**Lowpassing (blur)**:
- Soft, smeared appearance
- Fine details less defined than other source
- Some Blu-ray authoring studios apply this

**Sharpening**:
- Haloing around edges (bright/dark outlines)
- Unnatural crispness
- Line warping on straight edges

**Color manipulation**:
- Oversaturated colors
- Crushed blacks or blown highlights
- Different color grading than other source

**Upscaling**:
- Details too sharp for claimed resolution
- AI hallucinations (invented details)
- Native resolution lower than file resolution

## Common Scenarios

### Blu-ray vs Web

**Blu-ray usually better when**:
- Same master, Blu-ray has more bitrate
- No filtering applied during authoring
- Proper color space handling

**Web can be better when**:
- Blu-ray has lowpass filter applied
- Web has newer/better master
- Blu-ray is poor upscale from SD source
- Web version has better color grading

### Multiple Blu-ray Releases

Different authoring studios, regions, or editions can have different quality:
- Check authoring studio (some are known for lowpassing)
- Compare frame-by-frame for filtering
- Look for remastered vs original master

### SD vs HD

**HD version better when**:
- Truly native HD content
- Good upscale from clean SD master

**SD version better when**:
- HD is poorly upscaled from SD source
- HD has additional filtering damage
- SD is closer to original DVD master

## Red Flags

**Higher bitrate source might be worse if**:
- Encoded with inferior encoder (NVENC vs x264)
- Has filtering applied (sharpening, lowpass)
- Is upscaled from lower resolution
- Has wrong color space applied

**Higher resolution source might be worse if**:
- Upscaled from lower resolution original
- Has AI upscaling artifacts
- Native production resolution was lower

## Quick Decision Guide

| Comparison | Check First | Likely Winner |
|------------|-------------|---------------|
| Blu-ray vs Web | Filtering, authoring | Depends on studio |
| 4K vs 1080p | Native resolution | If native, 4K |
| HEVC vs AVC | Encoder, settings | Neither inherently |
| High vs low bitrate | Encoder efficiency | Higher if same encoder |
| HDR vs SDR | HDR legitimacy | SDR if HDR is fake |

## Tools Reference

- **SlowPics** (slow.pics) - Frame comparison hosting
- **vs-preview** - VapourSynth comparison tool
- **mpv** - Frame extraction, playback comparison
- **MediaInfo** - Metadata comparison

## Additional Resources

- **JET Guide**: https://jaded-encoding-thaumaturgy.github.io/JET-guide/
- **`${CLAUDE_PLUGIN_ROOT}/references/quality-myths.md`** - Why specs don't equal quality
- **`${CLAUDE_PLUGIN_ROOT}/references/artifacts.md`** - What quality issues look like
