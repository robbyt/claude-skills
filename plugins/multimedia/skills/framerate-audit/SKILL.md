---
name: framerate-audit
description: This skill should be used when the user asks "check frame rate", "is this CFR or VFR", "video has duplicate frames", "video stutters", "frame rate issues", "why does video judder", or wants to analyze frame rate characteristics and detect timing problems.
---

# Frame Rate Audit

Analyze video frame rate characteristics, detect CFR vs VFR, find duplicate frames, and diagnose timing issues.

## Key Concepts

### CFR vs VFR

**CFR (Constant Frame Rate)**:
- Every frame has identical duration
- Required by most video editors
- Preferred for distribution

**VFR (Variable Frame Rate)**:
- Frame durations vary
- Common in screen recordings, phone videos
- Causes editor sync issues

### Common Frame Rates

| Rate | Actual Value | Use Case |
|------|--------------|----------|
| 23.976 fps | 24000/1001 | Film, most streaming |
| 24 fps | 24/1 | True film rate (rare digital) |
| 25 fps | 25/1 | PAL video |
| 29.97 fps | 30000/1001 | NTSC video |
| 30 fps | 30/1 | Some digital content |
| 59.94 fps | 60000/1001 | High frame rate NTSC |
| 60 fps | 60/1 | Gaming, high frame rate |

**23.976 vs 24**: Nearly identical visually. The fractional rate exists for NTSC broadcast compatibility from analog TV era.

## Audit Workflow

### Step 1: Check MediaInfo

```bash
mediainfo video.mkv
```

Look for:
```
Frame rate mode    : Constant or Variable
Frame rate         : 23.976 (24000/1001) FPS
```

**Frame rate mode tells you CFR vs VFR**.

### Step 2: Detailed Frame Analysis

For deeper analysis:
```bash
# Check frame rate mode specifically
mediainfo --Inform="Video;%FrameRate_Mode%" video.mkv

# Get frame count
ffprobe -v error -count_packets -select_streams v:0 \
  -show_entries stream=nb_read_packets -of csv=p=0 video.mkv
```

### Step 3: Detect Duplicate Frames

**Using ffmpeg**:
```bash
# Detect duplicate frames (mpdecimate filter)
ffmpeg -i video.mkv -vf "mpdecimate,setpts=N/FRAME_RATE/TB" \
  -f null - 2>&1 | grep "drop"
```

**Manual inspection with mpv**:
- Open video in mpv
- Step frame-by-frame with `.` and `,`
- Compare adjacent frames visually
- Look for identical frames in sequence

### Step 4: Check for Judder

**Judder causes**:
- Frame rate mismatch with display
- Incorrect pulldown handling
- Duplicate frames creating uneven motion

**Visual test**:
- Watch panning shots
- Motion should be smooth
- Stuttering indicates timing issues

## Common Issues

### VFR Causing Editor Problems

**Symptoms**:
- Audio/video desync in editors
- Random stuttering
- Export timing issues

**Solution**:
Convert to CFR before editing:
```bash
ffmpeg -i vfr_video.mkv -vsync cfr -r 30 cfr_video.mkv
```

### Duplicate Frames

**Symptoms**:
- Motion appears to stutter
- Some frames are identical to previous
- Uneven playback

**Causes**:
- Bad frame rate conversion
- Screen recording with drops
- Encoding errors

**Detection**:
Step through video frame-by-frame. If two adjacent frames are identical, you have duplicates.

### Wrong Frame Rate Tag

**Symptoms**:
- Video plays too fast or slow
- Audio sync issues
- Duration doesn't match expected

**Solution**:
Retag without reencoding:
```bash
# Change frame rate metadata only
ffmpeg -i video.mkv -c copy -video_track_timescale 24000 output.mkv
```

### Interpolation Damage

**Symptoms**:
- "Soap opera effect" smoothness
- Morphing/warping on motion
- Ghosting around moving objects

**Cause**:
Frame interpolation (RIFE, SVP, TV motion smoothing) generating fake frames.

**Why it's bad**:
- Invented frames don't match source
- Artistic intent is 24fps, not 60fps
- Creates unnatural motion

## Editor Compatibility

### Premiere Pro / DaVinci / Vegas

**Requirements**:
- CFR strongly preferred
- Fractional rates (23.976) can cause issues
- Some editors handle VFR poorly

**Before importing**:
1. Check if source is CFR
2. If VFR, convert to CFR first
3. Use MkvToMp4 or ffmpeg for conversion

### MKV to MP4 for Editors

Standard remux may preserve VFR timestamps:
```bash
# May not fix VFR
ffmpeg -i input.mkv -c copy output.mp4
```

Force true CFR:
```bash
# Step 1: Set timescale
ffmpeg -i input.mkv -c copy -video_track_timescale 24000 temp.mp4

# Step 2: Round timestamps (for 23.976 fps)
ffmpeg -i temp.mp4 -c copy \
  -bsf:v "setts=dts=1001*round(DTS/1001):pts=1001*round(PTS/1001)" output.mp4
```

## Quick Reference

| Issue | MediaInfo Shows | Solution |
|-------|-----------------|----------|
| VFR video | Frame rate mode: Variable | Convert to CFR |
| Duplicate frames | N/A (visual inspection) | Re-encode or accept |
| Wrong rate tag | Unexpected frame rate | Retag with ffmpeg |
| Interpolated | Higher fps than source | Use original |

## Tools

- **MediaInfo**: Frame rate mode detection
- **ffprobe**: Detailed timing analysis
- **mpv**: Frame stepping (`.` and `,` keys)
- **MkvToMp4**: VFR to CFR conversion for editors

## Additional Resources

- **`${CLAUDE_PLUGIN_ROOT}/references/encoding-commands.md`** - Frame rate conversion commands
- **`${CLAUDE_PLUGIN_ROOT}/references/tools.md`** - Tool recommendations
