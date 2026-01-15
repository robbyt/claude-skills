# Encoding Command Templates

Ready-to-use commands for common video operations.

## Remuxing (No Quality Loss)

### MKV to MP4

Basic remux:
```bash
ffmpeg -i input.mkv -c copy output.mp4
```

With constant frame rate (for video editors):
```bash
# Step 1: Set timescale
ffmpeg -i input.mkv -c copy -video_track_timescale 24000 temp.mp4

# Step 2: Force constant timestamps (for 23.976 fps)
ffmpeg -i temp.mp4 -c copy -bsf:v "setts=dts=1001*round(DTS/1001):pts=1001*round(PTS/1001)" output.mp4

# Clean up
rm temp.mp4
```

For 29.97 fps, use `-video_track_timescale 30000`.

### MP4 to MKV

```bash
ffmpeg -i input.mp4 -c copy output.mkv
```

### Extract Video Stream Only

```bash
ffmpeg -i input.mkv -an -c:v copy output-video.mkv
```

### Extract Audio Stream Only

```bash
# Keep original format
ffmpeg -i input.mkv -vn -c:a copy output.m4a

# Convert to different format
ffmpeg -i input.mkv -vn -c:a aac -b:a 256k output.m4a
```

## Encoding (Quality Loss - Use Carefully)

### x264 (H.264) - Recommended for Quality

**Standard encode**:
```bash
ffmpeg -i input.mkv -c:v libx264 -preset slower -crf 18 -c:a copy output.mkv
```

**For animation/anime** (more efficient for flat content):
```bash
ffmpeg -i input.mkv -c:v libx264 -preset slower -crf 18 -x264-params bframes=8 -c:a copy output.mkv
```

**CRF Guide**:
| CRF | Quality | Use Case |
|-----|---------|----------|
| 14-16 | Near lossless | Archival, source preservation |
| 17-19 | High quality | General high-quality encoding |
| 20-23 | Good quality | Balanced quality/size |
| 24-28 | Acceptable | Size-constrained distribution |

### x265 (H.265) - Smaller Files

**Standard encode**:
```bash
ffmpeg -i input.mkv -c:v libx265 -preset slow -crf 20 -c:a copy output.mkv
```

**10-bit encoding** (often more efficient):
```bash
ffmpeg -i input.mkv -c:v libx265 -preset slow -crf 20 -pix_fmt yuv420p10le -c:a copy output.mkv
```

**CRF for x265**: Generally 2-4 points higher than x264 for similar quality (x265 CRF 22 ≈ x264 CRF 18).

### Preset Guide

| Preset | Speed | Efficiency | Recommendation |
|--------|-------|------------|----------------|
| ultrafast | Very fast | Poor | Never for quality |
| faster | Fast | Poor | Streaming only |
| fast | Moderate | Fair | Preview encodes |
| medium | Moderate | Good | Default |
| slow | Slow | Good | Recommended minimum |
| slower | Slower | Very good | Recommended |
| veryslow | Very slow | Excellent | Best quality/size |
| placebo | Extremely slow | Marginal gain | Not worth it |

### Two-Pass Encoding (Target Bitrate)

When specific file size is needed:

**Pass 1**:
```bash
ffmpeg -i input.mkv -c:v libx264 -preset slower -b:v 5M -pass 1 -an -f null /dev/null
```

**Pass 2**:
```bash
ffmpeg -i input.mkv -c:v libx264 -preset slower -b:v 5M -pass 2 -c:a copy output.mkv
```

**Note**: CRF usually preferred over target bitrate for quality.

## Hardsubbing

### Using mpv (Recommended)

```bash
mpv --no-config input.mkv -o output.mkv --audio=no --ovc=libx264 --ovcopts=preset=slower,crf=18,bframes=8
```

**Select specific subtitle track**:
```bash
# By track number
mpv --no-config input.mkv -o output.mkv --sid=2 --audio=no --ovc=libx264 --ovcopts=preset=slower,crf=18

# By language
mpv --no-config input.mkv -o output.mkv --slang=eng --audio=no --ovc=libx264 --ovcopts=preset=slower,crf=18
```

### Using ffmpeg

```bash
# Internal subtitle track
ffmpeg -i input.mkv -vf "subtitles=input.mkv:si=0" -c:v libx264 -preset slower -crf 18 -c:a copy output.mkv

# External subtitle file
ffmpeg -i input.mkv -vf "subtitles=subs.ass" -c:v libx264 -preset slower -crf 18 -c:a copy output.mkv
```

### Near-Lossless Intermediate

For workflows needing intermediate file:
```bash
# Hardsub to near-lossless intermediate
mpv --no-config input.mkv -o intermediate.mkv --audio=no --ovc=libx264 --ovcopts=crf=1

# Then final encode
ffmpeg -i intermediate.mkv -c:v libx264 -preset slower -crf 18 -c:a copy final.mkv
```

## Color Space Operations

### Tag Color Matrix (No Reencode)

Using ffmpeg:
```bash
# Tag as BT.709
ffmpeg -i input.mkv -c copy -color_primaries bt709 -color_trc bt709 -colorspace bt709 output.mkv
```

Using MKVToolNix:
```bash
mkvpropedit input.mkv --edit track:v1 --set colour-matrix-coefficients=1 --set colour-primaries=1 --set colour-transfer-characteristics=1
```

### Convert Color Matrix (Requires Reencode)

BT.601 to BT.709:
```bash
ffmpeg -i input.mkv -vf "colormatrix=bt601:bt709" -c:v libx264 -preset slower -crf 18 -c:a copy output.mkv
```

### Tag Color Range

Limited range:
```bash
ffmpeg -i input.mkv -c copy -color_range tv output.mkv
```

Full range:
```bash
ffmpeg -i input.mkv -c copy -color_range pc output.mkv
```

## Subtitle Operations

### Extract Subtitles

```bash
# First subtitle track
ffmpeg -i input.mkv -map 0:s:0 output.ass

# By language
ffmpeg -i input.mkv -map 0:s:m:language:eng output.srt

# All subtitle tracks
ffmpeg -i input.mkv -map 0:s output.ass
```

### Convert Subtitle Format

```bash
# ASS to SRT
ffmpeg -i input.ass output.srt

# SRT to ASS (basic)
ffmpeg -i input.srt output.ass
```

### Add Subtitle to MKV

```bash
# With MKVToolNix
mkvmerge -o output.mkv input.mkv subtitles.ass

# With ffmpeg
ffmpeg -i input.mkv -i subtitles.ass -map 0 -map 1 -c copy output.mkv
```

## Analysis Commands

### Detailed File Info

```bash
mediainfo --Full input.mkv
```

### Specific Fields

```bash
# Frame rate mode
mediainfo --Inform="Video;%FrameRate_Mode%" input.mkv

# Color matrix
mediainfo --Inform="Video;%colour_description_present% %matrix_coefficients%" input.mkv

# Encoder
mediainfo --Inform="Video;%Encoded_Library%" input.mkv
```

### Stream Information

```bash
ffprobe -show_streams input.mkv
```

### Frame Count

```bash
ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 input.mkv
```

## Troubleshooting Commands

### Check for Variable Frame Rate

```bash
mediainfo --Inform="Video;%FrameRate_Mode%" input.mkv
# "Constant" = good
# "Variable" = may cause issues in editors
```

### Compare Frame Counts

```bash
# Source
ffprobe -v error -count_packets -select_streams v:0 -show_entries stream=nb_read_packets source.mkv

# Encoded
ffprobe -v error -count_packets -select_streams v:0 -show_entries stream=nb_read_packets encoded.mkv
```

### Extract Single Frame

```bash
# Frame at timestamp
ffmpeg -ss 00:01:30 -i input.mkv -frames:v 1 frame.png

# Specific frame number
ffmpeg -i input.mkv -vf "select=eq(n\,100)" -frames:v 1 frame100.png
```

### Compare Files Side by Side

Using mpv:
```bash
mpv --lavfi-complex="[vid1][vid2]hstack[vo]" input1.mkv --external-file=input2.mkv
```

## Quick Reference

| Task | Command |
|------|---------|
| Remux MKV→MP4 | `ffmpeg -i in.mkv -c copy out.mp4` |
| Encode x264 | `ffmpeg -i in.mkv -c:v libx264 -preset slower -crf 18 out.mkv` |
| Encode x265 | `ffmpeg -i in.mkv -c:v libx265 -preset slow -crf 20 out.mkv` |
| Extract audio | `ffmpeg -i in.mkv -vn -c:a copy out.m4a` |
| Extract video | `ffmpeg -i in.mkv -an -c:v copy out.mkv` |
| Extract subs | `ffmpeg -i in.mkv -map 0:s:0 out.ass` |
| Hardsub | `mpv --no-config in.mkv -o out.mkv --audio=no --ovc=libx264 --ovcopts=crf=18` |
| Tag BT.709 | `mkvpropedit in.mkv --edit track:v1 --set colour-matrix-coefficients=1` |
