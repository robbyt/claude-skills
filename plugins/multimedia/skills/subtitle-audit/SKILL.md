---
name: subtitle-audit
description: This skill should be used when the user asks "check subtitles", "audit subs", "subtitle font issues", "ASS vs SRT", "missing fonts", "subtitle timing", or wants to analyze subtitle tracks for issues like missing fonts, timing problems, or format limitations.
---

# Subtitle Track Audit

Analyze subtitle tracks for issues including missing fonts, timing problems, format capabilities, and proper tagging.

## Subtitle Formats

### ASS (Advanced SubStation Alpha)

**Capabilities**:
- Full styling (fonts, colors, positioning)
- Complex typesetting (signs, karaoke)
- Multiple styles per file
- Precise positioning

**Requirements**:
- Fonts must be available (embedded or installed)
- Only MKV container fully supports ASS
- MP4 does not support ASS (must hardsub)

### SRT (SubRip)

**Capabilities**:
- Basic text with timing
- Limited styling (some players support HTML tags)
- Wide compatibility

**Limitations**:
- No font specification
- No precise positioning
- No complex typesetting

### PGS (Presentation Graphic Stream)

**Capabilities**:
- Blu-ray subtitle format
- Image-based (pre-rendered)
- Perfect styling preservation

**Limitations**:
- Cannot be edited easily
- Large file size
- Text not searchable/selectable

## Audit Workflow

### Step 1: List Subtitle Tracks

```bash
mediainfo video.mkv
```

Look for Subtitle sections showing:
- Format (ASS, SRT, PGS, etc.)
- Language
- Title/name
- Default/forced flags

**Using ffprobe**:
```bash
ffprobe -v error -select_streams s -show_entries \
  stream=index,codec_name:stream_tags=language,title \
  -of csv=p=0 video.mkv
```

### Step 2: Extract for Inspection

```bash
# Extract first subtitle track
ffmpeg -i video.mkv -map 0:s:0 subtitles.ass

# Extract by language
ffmpeg -i video.mkv -map 0:s:m:language:eng output.srt
```

### Step 3: Check ASS Font Requirements

**Using Aegisub**:
1. Open ASS file in Aegisub
2. Go to View → Fonts Collector
3. Lists all fonts used and availability

**Manual inspection**:
Open ASS file in text editor, look for Style lines:
```
Style: Default,Arial,48,&H00FFFFFF,...
```
The second field after style name is the font.

### Step 4: Verify Embedded Fonts

For MKV files, check attachments:
```bash
mediainfo video.mkv | grep -A 20 "Attachment"
```

Should show font files (TTF, OTF) if fonts are embedded.

**Extract embedded fonts**:
```bash
mkvextract attachments video.mkv 1:font1.ttf 2:font2.ttf
```

### Step 5: Timing Analysis

**Check for issues**:
- Subtitles appearing too early/late
- Overlapping subtitle events
- Very short display times

**Using Aegisub**:
- Open subtitle file
- Check timing column for irregularities
- Look for negative durations or overlaps

## Common Issues

### Missing Fonts

**Symptoms**:
- Subtitles render in wrong font
- Missing characters (boxes or blanks)
- Wrong styling/positioning

**Solutions**:
1. Install required fonts system-wide
2. Use font manager (FontBase) for temporary activation
3. Embed fonts when muxing MKV

### Wrong Language Tag

**Symptoms**:
- Player selects wrong subtitle track
- Language filtering doesn't work

**Fix with MKVToolNix**:
```bash
mkvpropedit video.mkv --edit track:s1 --set language=eng
```

### Timing Offset

**Symptoms**:
- All subtitles early or late by same amount

**Fix**:
```bash
# Delay subtitles by 2 seconds
ffmpeg -i input.srt -itsoffset 2 -i input.srt -c copy output.srt
```

Or use Aegisub: Timing → Shift Times

### Container Compatibility

**MKV**: Full ASS support, can embed fonts
**MP4**: No ASS support, SRT only (basic), or must hardsub
**WebM**: Limited subtitle support

## Muxing Subtitles

### Add to MKV

```bash
# With MKVToolNix
mkvmerge -o output.mkv input.mkv subtitles.ass

# With ffmpeg
ffmpeg -i video.mkv -i subtitles.ass -map 0 -map 1 -c copy output.mkv
```

### Set Language and Default

```bash
mkvmerge -o output.mkv input.mkv \
  --language 0:eng --default-track 0:yes subtitles.ass
```

### Embed Fonts

```bash
mkvmerge -o output.mkv input.mkv subtitles.ass \
  --attach-file font1.ttf --attach-file font2.ttf
```

## Quick Reference

| Format | Styling | Fonts | Container Support |
|--------|---------|-------|-------------------|
| ASS | Full | Required | MKV only |
| SRT | Basic/None | N/A | Most containers |
| PGS | Image-based | N/A | MKV, M2TS |
| VobSub | Image-based | N/A | MKV, AVI |

## Font Collection

When distributing ASS subtitles:

1. **Collect fonts** using Aegisub's Font Collector
2. **Embed in MKV** as attachments
3. **Test on clean system** without fonts installed

## Tools

- **Aegisub**: Subtitle editing, font collection, timing
- **MKVToolNix**: Muxing, track properties, font embedding
- **ffmpeg**: Extraction, basic manipulation
- **FontBase**: Font management without installation

## Additional Resources

- **`${CLAUDE_PLUGIN_ROOT}/references/tools.md`** - Tool recommendations
- **`${CLAUDE_PLUGIN_ROOT}/references/encoding-commands.md`** - Subtitle extraction/muxing commands
