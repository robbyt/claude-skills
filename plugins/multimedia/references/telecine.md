# Telecine and Interlacing Reference

Detailed guide to understanding telecine patterns, interlacing, and proper handling.

## Background

### Why Telecine Exists

Film is shot at 24 frames per second. NTSC television broadcasts at 29.97fps (approximately 30fps). To convert film to NTSC, telecine applies "3:2 pulldown" to create the additional frames needed.

This process is reversible because no actual information is created—fields from existing frames are duplicated in a pattern.

### Why Interlacing Exists

Interlaced video alternates between odd and even lines (fields) to effectively double temporal resolution while halving vertical resolution per field. A 30fps interlaced video has 60 fields per second, capturing motion twice as often as 30 progressive frames.

True interlaced content (sports, news, soap operas) was actually captured as interlaced fields—each field contains unique temporal information.

## 3:2 Pulldown Pattern

### Standard Pattern (AABBCCD)

Converting 4 film frames (A, B, C, D) to 5 interlaced frames:

```
Film Frame:     A        A        B        C        C        D
                |        |        |        |        |        |
Video Fields: A-top   A-bot   B-top   B-bot   C-top   C-bot   D-top   D-bot
                |        |        |        |        |        |
Interlaced:  [A-t/A-b] [A-b/B-t] [B-t/B-b] [C-t/C-b] [C-b/D-t] [D-t/D-b]
              Frame 1   Frame 2   Frame 3   Frame 4   Frame 5   (continues)
```

**Breakdown**:
- Frame 1: Both fields from A (progressive)
- Frame 2: Bottom of A + Top of B (interlaced, combed)
- Frame 3: Both fields from B (progressive)
- Frame 4: Both fields from C (progressive)
- Frame 5: Bottom of C + Top of D (interlaced, combed)

Pattern then repeats with frames D, E, F, G...

### Identifying the Pattern

Look for this sequence when stepping through frames:
1. Progressive (clean)
2. Interlaced (combed)
3. Progressive (clean)
4. Progressive (clean)
5. Interlaced (combed)
6. (pattern repeats)

The 2-3-2-3 rhythm is characteristic of 3:2 pulldown.

## Pattern Variations

### Cadence Breaks

Films often have cadence breaks due to:
- Scene changes
- Editing cuts
- Different source material spliced in

Automated IVTC may fail at breaks. Wobbly allows manual correction.

### Hard vs Soft Telecine

**Soft telecine**:
- Flags indicate how to duplicate fields
- Decoder can reconstruct 24fps
- No actual field blending

**Hard telecine**:
- Fields actually duplicated in video stream
- Must use IVTC to reverse
- Common in DVD releases

### Field Order

**TFF (Top Field First)**:
- Top field is older (first in time)
- Common in NTSC DVDs

**BFF (Bottom Field First)**:
- Bottom field is older
- Less common

MediaInfo shows: `Scan order: Top Field First` or `Bottom Field First`

## True Interlacing vs Telecine

### Visual Comparison

**Telecine**:
- Combing only on specific frames (pattern)
- Combing only where motion occurred
- Clean frames interspersed regularly

**True interlacing**:
- Every frame shows combing during motion
- No predictable pattern
- Combing throughout motion areas

### Content Clues

**Likely telecine**:
- Movies
- Scripted TV shows
- Animation
- 24fps original content

**Likely true interlacing**:
- Live sports
- News broadcasts
- Soap operas/talk shows
- Home video
- 30fps/60i original content

## Inverse Telecine (IVTC)

### Process

1. **Field matching**: Identify which fields belong to same original frame
2. **Decimation**: Remove duplicate/blended frames
3. **Result**: Original 24fps progressive content

### Tools

**Wobbly** (Recommended for quality):
- GUI for manual pattern matching
- Handles irregular cadences
- Guide: https://wobbly.encode.moe

**VapourSynth VIVTC**:
```python
# Basic VIVTC usage
from vapoursynth import core
clip = core.vivtc.VFM(clip, order=1)  # Field matching
clip = core.vivtc.VDecimate(clip)      # Decimation
```

**Avisynth TFM+TDecimate**:
```
TFM(order=1)
TDecimate(mode=1)
```

### Quality Considerations

- IVTC is nearly lossless when done correctly
- Incorrect field matching creates blended frames
- Cadence breaks need manual attention
- Result should be clean 24fps progressive

## Deinterlacing

### When to Use

Only for truly interlaced content that cannot be reverse-telecined.

### Methods

**Yadif** (Fast, moderate quality):
```bash
ffmpeg -i input.mkv -vf "yadif=mode=0" output.mkv
```
- mode=0: Output 24fps (best for telecine that IVTC failed on)
- mode=1: Output 60fps (bob, doubles frame rate)

**QTGMC** (Highest quality, slow):
```python
# VapourSynth
import havsfunc as haf
clip = haf.QTGMC(clip, Preset="Slow", TFF=True)
```

### Quality Loss

Deinterlacing inherently discards or blends temporal information:
- Blending creates ghosting
- Field dropping loses motion detail
- Neither recovers original progressive frames

## Common Mistakes

### Mistake 1: Deinterlacing Telecine

**What happens**:
- Deinterlacer throws away fields
- Vertical resolution halved
- Blurry, lower quality result

**Why it's wrong**:
- Telecine can be reversed losslessly
- Original frames exist, just need to be found
- Deinterlacing destroys what IVTC would recover

### Mistake 2: Wrong Field Order

**What happens**:
- IVTC uses wrong order
- Fields mismatched
- Ghosting/blending on every frame

**Solution**:
- Check MediaInfo for field order
- Try both TFF and BFF, compare results

### Mistake 3: Ignoring Cadence Breaks

**What happens**:
- Automated IVTC fails at cuts
- Some scenes have wrong cadence
- Results in mixed quality

**Solution**:
- Use Wobbly for manual matching at breaks
- Or accept minor issues in automated workflow

## Quick Reference

| Content Type | Detection | Handling |
|--------------|-----------|----------|
| Film on DVD | 2-3-2-3 pattern | IVTC |
| Animation | Often telecine pattern | IVTC |
| Sports broadcast | Every frame combed | Deinterlace |
| News/talk shows | Every frame combed | Deinterlace |
| Mixed content | Varies by scene | Per-scene analysis |

## Resources

- **fieldbased.media** - Comprehensive interlacing guide
- **https://wobbly.encode.moe** - Wobbly IVTC guide
- **JET Guide** - https://jaded-encoding-thaumaturgy.github.io/JET-guide/
