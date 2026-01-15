# Video Tools Reference

Recommended tools and tools to avoid when working with video.

## Recommended Tools

### MediaInfo

**Purpose**: Analyze video file metadata and technical properties.

**Installation**:
- macOS: `brew install mediainfo`
- Linux: `apt install mediainfo`
- Windows: Download from mediaarea.net

**Usage**:
```bash
# Quick summary
mediainfo video.mkv

# Full technical details
mediainfo --Full video.mkv

# JSON output for scripting
mediainfo --Output=JSON video.mkv
```

**Key info to check**:
- Format (codec)
- Bit rate
- Color matrix/range/primaries
- Encoded_Library (encoder used)
- Writing application

**Why essential**: First step in any video work is understanding what you have.

### mpv

**Purpose**: High-quality video playback with technical features.

**Installation**:
- macOS: `brew install mpv`
- Linux: `apt install mpv` or package manager
- Windows: Download from mpv.io

**Key features**:
- Press `i`: Show technical overlay (color space, codec, etc.)
- Press `.`: Frame step forward
- Press `,`: Frame step backward
- Press `s`: Screenshot (current frame)
- Press `S`: Screenshot (with subtitles)

**Why preferred over VLC**:
- More accurate color handling
- Better subtitle rendering
- Proper frame timing
- Technical overlay for debugging

**Configuration** (`~/.config/mpv/mpv.conf`):
```ini
# High quality scaling
profile=high-quality

# Show filename in title
title=${filename}

# OSD duration
osd-duration=2000
```

### ffmpeg

**Purpose**: Swiss army knife for video conversion, encoding, remuxing.

**Installation**:
- macOS: `brew install ffmpeg`
- Linux: `apt install ffmpeg`
- Windows: Download from ffmpeg.org

**Key operations**:

Remux (change container, no reencode):
```bash
ffmpeg -i input.mkv -c copy output.mp4
```

Reencode with x264:
```bash
ffmpeg -i input.mkv -c:v libx264 -preset slower -crf 18 output.mkv
```

Extract audio:
```bash
ffmpeg -i input.mkv -vn -c:a copy audio.aac
```

Extract video:
```bash
ffmpeg -i input.mkv -an -c:v copy video.mkv
```

**Important**: ffmpeg itself doesn't encode—it calls encoders like x264/x265. Quality depends on encoder settings.

### MKVToolNix

**Purpose**: Mux, demux, and edit MKV files without reencoding.

**Installation**:
- macOS: `brew install mkvtoolnix`
- Linux: `apt install mkvtoolnix`
- Windows: Download from mkvtoolnix.download

**Key operations**:
- Combine video/audio/subtitle tracks
- Edit metadata (titles, languages)
- Add/remove tracks
- Edit color space tags (without reencode)
- Add chapters

**GUI**: mkvtoolnix-gui provides visual interface

### MKVExtractGUI / MKVcleaver

**Purpose**: Extract tracks from MKV files.

**Use cases**:
- Extract subtitle tracks
- Extract audio tracks
- Pull video stream for processing

### Aegisub

**Purpose**: Create and edit subtitles (ASS/SRT format).

**Key features**:
- Visual timing interface
- Audio waveform display
- Font collector for ASS subtitles
- Style editor

**Installation**: Download from aegisub.org

### SlowPics

**Purpose**: Share video frame comparisons.

**URL**: slow.pics

**Usage**:
- Upload comparison frames
- Uncheck "Show border" and "Smooth scaling"
- Use clicker view (not slider)
- Number keys (1/2/3) switch between images

**Why not imgsli**: imgsli converts to JPEG, invalidating quality comparisons.

### vs-preview

**Purpose**: VapourSynth-based frame comparison and analysis.

**Features**:
- Side-by-side frame comparison
- Automatic SlowPics upload
- Frame analysis tools

**Installation**: pip install vs-preview (requires VapourSynth)

## Specialized Tools

### MkvToMp4

**Purpose**: Remux MKV to MP4 with constant frame rate.

**Why needed**: ffmpeg remux may preserve VFR timestamps that cause issues in editors.

**URL**: videohelp.com/software/MkvToMp4

**Limitation**: H.264 only (not H.265)

### mp4fpsmod

**Purpose**: Modify MP4 frame rate metadata.

**Use case**: Force CFR when remuxing causes VFR issues.

**URL**: github.com/nu774/mp4fpsmod

## Tools to Avoid

### Handbrake

**Problems**:
- Can change frame rate unexpectedly
- May add interlacing flags
- Limited control over encoding parameters
- Easy to accidentally reencode when remux would suffice

**When acceptable**: Quick one-off encodes where quality isn't priority

**Better alternative**: Learn ffmpeg basics

### Online Conversion Tools

**Problems**:
- Usually reencode (quality loss)
- No control over settings
- Privacy concerns
- Just use ffmpeg internally anyway

**Better alternative**: Install ffmpeg locally (10 minutes to learn basics)

### AI Upscalers (Real-ESRGAN, Topaz, etc.)

**Problems**:
- Add invented details (hallucinations)
- Cannot recover real detail
- Take video further from source
- Cause temporal inconsistencies

**The truth**: Upscaling cannot add real detail. It only invents plausible-looking pixels.

**When acceptable**: Never for archival. Possibly for personal viewing if you understand limitations.

### Anime4K

**Problems**:
- Real-time sharpening, not true upscaling
- Adds haloing and ringing
- Destroys subtle textures
- "Sharper" ≠ "better"

### RIFE / Frame Interpolation

**Problems**:
- Invents frames that don't exist
- Causes morphing and warping artifacts
- Changes artistic intent (24fps→60fps)
- Motion blur becomes unnatural

**The truth**: 24fps content is meant to be 24fps. Interpolation doesn't improve it.

### VLC (for analysis)

**Problems**:
- Color handling not always accurate
- Limited technical information
- Frame stepping less reliable

**When acceptable**: Casual playback. Use mpv for technical work.

### $30 ffmpeg Wrappers

**Examples**: Various "video converter pro" applications

**Problems**:
- Just call ffmpeg internally
- Less control than ffmpeg directly
- Paying for free software

**Better alternative**: Learn ffmpeg

## Encoder Comparison

### For Quality (Archival)

| Encoder | Codec | Quality | Speed |
|---------|-------|---------|-------|
| x264 | H.264 | Excellent | Slow |
| x265 | H.265 | Excellent | Very slow |
| SVT-AV1 | AV1 | Excellent (low bitrate) | Slow |

### For Speed (Streaming)

| Encoder | Codec | Quality | Speed |
|---------|-------|---------|-------|
| NVENC | H.264/H.265 | Good | Very fast |
| QuickSync | H.264/H.265 | Good | Very fast |
| VideoToolbox | H.264/H.265 | Good | Fast |

### Key Points

- **x264/x265**: Best quality, use for archival
- **Hardware encoders**: Fast, larger files, good for streaming
- **Never use hardware encoders for archival**: Quality tradeoff not worth it

## Command Quick Reference

### Remux MKV to MP4
```bash
ffmpeg -i input.mkv -c copy output.mp4
```

### Reencode with x264
```bash
ffmpeg -i input.mkv -c:v libx264 -preset slower -crf 18 -c:a copy output.mkv
```

### Reencode with x265
```bash
ffmpeg -i input.mkv -c:v libx265 -preset slow -crf 20 -c:a copy output.mkv
```

### Extract streams
```bash
# Video only
ffmpeg -i input.mkv -an -c:v copy output.mkv

# Audio only
ffmpeg -i input.mkv -vn -c:a copy output.m4a

# Subtitle only
ffmpeg -i input.mkv -map 0:s:0 output.ass
```

### Get detailed file info
```bash
mediainfo --Full input.mkv
```

### Check frame rate type
```bash
mediainfo --Inform="Video;%FrameRate_Mode%" input.mkv
```
