---
name: telecine-detect
description: This skill should be used when the user asks "is this interlaced", "detect telecine", "video has combing", "should I deinterlace", "3:2 pulldown", "inverse telecine", or sees horizontal lines/combing artifacts in video and wants to understand if the content is truly interlaced or telecined.
---

# Telecine and Interlacing Detection

Detect whether video content is telecined (reversible) or truly interlaced (not reversible), and advise on proper handling. Getting this wrong destroys video quality.

## Critical Distinction

**Telecine (3:2 Pulldown)**:
- 24fps film content converted to 30fps for NTSC broadcast
- Creates repeating pattern of combing across frames
- Can be reversed nearly losslessly via IVTC (inverse telecine)
- Original 24fps frames can be recovered

**True Interlacing**:
- Content actually captured at 60 interlaced fields per second
- Each field is unique temporal information
- Cannot be reversed without quality loss
- Deinterlacing merges or discards fields

## The Common Mistake

Seeing combing → Immediately running a deinterlacer

**Why this is wrong for telecined content**:
- Deinterlacers throw away half the vertical resolution
- They cannot distinguish telecine from true interlacing
- The original 24 progressive frames are lost
- Result is a blurry, lower-quality video

**Correct approach**:
1. First detect if content is telecined or truly interlaced
2. If telecined → use IVTC to recover original frames
3. If truly interlaced → only then consider deinterlacing

## Detection Workflow

### Step 1: Check MediaInfo

Look for these fields:
```
Scan type: Interlaced or Progressive
Scan order: Top Field First (TFF) or Bottom Field First (BFF)
```

**Note**: MediaInfo only shows container/stream flags. Content can be flagged as interlaced but actually be telecined, or flagged progressive but have telecine applied.

### Step 2: Visual Inspection

Open in mpv and step through frames (`.` and `,` keys):

**Telecine indicators**:
- Combing appears on some frames but not others
- Pattern repeats (e.g., every 5th frame has combing)
- Combing only on specific parts of frame where motion occurred
- 3:2 pattern: 2 clean frames, then 3 frames with combing alternating

**True interlacing indicators**:
- Every frame shows combing on all motion
- No repeating pattern
- Combing appears uniformly across frame

### Step 3: Confirm with Frame Analysis

For telecine, look for the 3:2 pulldown pattern:
```
Frame 1: Progressive (A)
Frame 2: Progressive (A)
Frame 3: Interlaced (A top + B bottom)
Frame 4: Interlaced (B top + C bottom)
Frame 5: Progressive (C)
... pattern repeats
```

Count frames between clean (progressive) frames. If pattern is consistent (typically 2-3-2-3 or similar), it's telecine.

## Handling Telecined Content

### Tools for IVTC

**Wobbly** (Recommended):
- GUI tool for manual telecine pattern matching
- Handles irregular patterns and scene changes
- Guide: https://wobbly.encode.moe

**VapourSynth VIVTC**:
- Automated IVTC for consistent patterns
- Part of VapourSynth toolchain

**avisynth/vapoursynth TFM+TDecimate**:
- Classic IVTC combination
- TFM matches fields, TDecimate removes duplicates

### IVTC Process

1. Identify the telecine cadence (pattern)
2. Match fields to reconstruct original frames
3. Decimate (remove) duplicate frames
4. Result: Original 24fps progressive content

## Handling True Interlacing

Only when content is confirmed truly interlaced:

**Deinterlacing options** (quality varies):
- QTGMC (VapourSynth/Avisynth) - highest quality, slow
- yadif - fast, moderate quality
- bwdif - improved yadif

**Doubling options** (60fps output):
- Bob deinterlacing - fast, doubles frame rate
- QTGMC bob - higher quality bob

## Quick Reference

| Symptom | Likely Cause | Action |
|---------|--------------|--------|
| Combing on some frames only | Telecine | Use IVTC |
| Repeating pattern of combing | Telecine | Use IVTC |
| Every frame has combing | True interlacing | Deinterlace |
| DVD/NTSC source, 29.97fps | Often telecine | Check pattern |
| Sports/news content | Often true interlacing | Deinterlace |
| Film/movie content | Often telecine | Use IVTC |

## Red Flags

**Don't deinterlace if**:
- Source is a movie or scripted TV show (likely telecine)
- Combing appears in a pattern
- MediaInfo shows 23.976fps original rate
- Source is from DVD/Blu-ray of film content

**Consider deinterlacing if**:
- Live broadcast content (sports, news)
- Home video footage
- Every single frame shows combing
- No discernible pattern

## Additional Resources

- **fieldbased.media** - Comprehensive interlacing guide
- **https://wobbly.encode.moe** - Wobbly IVTC guide
- **`${CLAUDE_PLUGIN_ROOT}/references/telecine.md`** - Detailed telecine patterns
