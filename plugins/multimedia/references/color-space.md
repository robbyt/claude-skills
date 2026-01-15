# Color Space Parameters

Technical details on color space parameters that affect video playback and quality.

## Overview

Video colors are stored in YCbCr, not RGB. Converting between them requires knowing several parameters:

| Parameter | What It Controls | Common Values |
|-----------|------------------|---------------|
| Matrix | YCbCr ↔ RGB conversion formula | BT.601, BT.709, BT.2020 |
| Range | Value range used | Limited (16-235), Full (0-255) |
| Transfer | Gamma/brightness curve | BT.709, sRGB, PQ, HLG |
| Primaries | Color gamut | BT.709, BT.2020, DCI-P3 |
| Chroma location | Chroma sample alignment | Left, Center, Top-Left |

## Color Matrix (BT.601 vs BT.709)

### What It Does

Defines the mathematical formula to convert YCbCr to RGB and back.

### Which To Use

| Content Type | Correct Matrix |
|--------------|----------------|
| SD content (DVD, 480p/576p) | BT.601 |
| HD content (720p and above) | BT.709 |
| UHD/HDR content | BT.2020 |

### What Goes Wrong

If a BT.709 video is played as BT.601 (or vice versa):
- Colors shift in hue
- Saturation changes
- Skin tones look wrong
- Overall "off" appearance

**Visual symptom**: Colors look slightly wrong throughout entire frame, not localized issues.

### Checking Matrix

**MediaInfo**: Look for "Matrix coefficients" in Video section
**mpv**: Press `i`, check "Colormatrix" under Video (not Display)

### Fixing Matrix Issues

**If just mistagged** (correct matrix, wrong metadata):
- Retag with MKVToolNix (no reencode needed)
- Set correct matrix in container metadata

**If actually wrong** (converted with wrong matrix):
- Must reencode with correct matrix conversion
- Quality loss unavoidable

## Color Range (Limited vs Full)

### What It Does

Defines which numeric values represent black and white.

| Range | Black | White | Use Case |
|-------|-------|-------|----------|
| Limited | 16 | 235 | Video (broadcast, Blu-ray, streaming) |
| Full | 0 | 255 | Computer graphics, screenshots |

### What Goes Wrong

**Limited played as Full:**
- Washed out appearance
- Blacks look gray
- Low contrast

**Full played as Limited:**
- Crushed blacks (shadow detail lost)
- Clipped highlights (bright detail lost)
- Excessive contrast

### Double Range Compression

If Limited→Full→Limited conversion happens:
- Shadows crushed to pure black
- Highlights clipped to pure white
- Information permanently lost

### Checking Range

**MediaInfo**: "Color range" field (may show as "Limited" or "TV" vs "Full" or "PC")
**mpv**: Press `i`, check color range in Video section

### Fixing Range Issues

**If mistagged**: Retag metadata, no reencode
**If actually converted wrong**: Must reencode, quality loss from clipping may be permanent

## Chroma Location

### What It Does

Specifies where chroma samples are positioned relative to luma samples after 4:2:0 subsampling.

### Common Locations

| Location | Description | Use Case |
|----------|-------------|----------|
| Left (Center-Left) | Between left two luma samples | Standard for most video |
| Center | Center of 2x2 luma block | Some software defaults |
| Top-Left | Top-left corner | JPEG, some cameras |

### What Goes Wrong

Wrong chroma location causes **chroma shift**:
- Color misaligned with luminance
- Colored fringe on one side of edges
- Subtle but visible on sharp edges

### Visual Symptoms

- Red/blue glow consistently on one side of all edges
- Color "bleeding" in one direction
- Diagonal lines have asymmetric color fringing

### Checking Chroma Location

**MediaInfo**: "Chroma subsampling position" (often untagged)
**Visual inspection**: Look at sharp edges for consistent color fringing

### Distinguishing from Chromatic Aberration

| Chroma Shift | Chromatic Aberration |
|--------------|---------------------|
| YCbCr chroma vs luma misalignment | RGB channel misalignment |
| Can fix by retagging | Intentional artistic effect |
| Same shift direction everywhere | Varies by position in frame |

## Transfer Characteristics (Gamma)

### What It Does

Defines the brightness curve (how numeric values map to light output).

### Common Values

| Transfer | Description | Use Case |
|----------|-------------|----------|
| BT.709 | Standard video gamma | HD video, streaming |
| BT.1886 | Display-referred BT.709 | Playback standard |
| sRGB | Similar to BT.709 | Computer monitors |
| PQ (SMPTE 2084) | HDR absolute brightness | HDR10, Dolby Vision |
| HLG | HDR relative brightness | Broadcast HDR |

### For SDR Content

BT.709/BT.1886/sRGB are nearly identical in practice. Mismatches cause subtle brightness differences but rarely major issues.

### For HDR Content

PQ and HLG are fundamentally different from SDR transfers. Playing HDR as SDR (or vice versa) causes severe brightness problems.

## Color Primaries

### What It Does

Defines the color gamut (which RGB values represent which real-world colors).

### Common Values

| Primaries | Gamut Size | Use Case |
|-----------|-----------|----------|
| BT.709 | Standard | HD video, sRGB displays |
| BT.2020 | Wide | UHD, HDR |
| DCI-P3 | Wide | Cinema, Apple displays |

### When It Matters

- SDR content: Almost always BT.709, rarely issues
- HDR content: Usually BT.2020, mismatch causes saturation problems
- Professional workflows: May use DCI-P3

## MediaInfo Field Reference

Key fields to check in MediaInfo "Video" section:

```
Format: H.264                    # Codec
Color space: YUV                 # Always YUV for video
Chroma subsampling: 4:2:0        # Standard
Bit depth: 8 bits                # 8 or 10 common
Color range: Limited             # Limited or Full
Color primaries: BT.709          # Color gamut
Transfer characteristics: BT.709  # Gamma curve
Matrix coefficients: BT.709      # YCbCr conversion
```

## Diagnosing Color Issues

### Workflow

1. Get MediaInfo dump of problematic file
2. Check matrix, range, transfer, primaries for consistency
3. Compare to expected values for content type
4. Check for untagged fields (player may guess wrong)
5. Compare visually to known-good source if available

### Common Problems and Solutions

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Overall color shift | Wrong matrix | Retag or reencode |
| Washed out | Limited as Full | Retag range |
| Crushed blacks | Full as Limited | Retag range |
| Color fringing on edges | Chroma shift | Retag chroma location |
| Way too dark | HDR played as SDR | Use HDR-capable player |

## mpv Color Verification

Use mpv to verify how video is being interpreted:

1. Open video in mpv
2. Press `i` for technical overlay
3. Check "Video" section for source parameters
4. Check "Display" section for output parameters
5. Values should match or be correctly converted

## Tools for Color Work

| Tool | Use |
|------|-----|
| MediaInfo | Read metadata |
| MKVToolNix | Edit metadata (retag without reencode) |
| mpv | Verify playback interpretation |
| ffmpeg | Convert/fix color parameters |
| vs-preview | Frame comparison with correct color handling |
