# HDR Reference Guide

Technical details on HDR formats, metadata, and detection of fake HDR content.

## HDR Fundamentals

### What HDR Provides

**Extended brightness range**:
- SDR: ~0.1 to 100 nits
- HDR: ~0.0005 to 1000+ nits (up to 10,000 theoretical)

**Wider color gamut**:
- SDR: BT.709 (sRGB equivalent)
- HDR: BT.2020 or DCI-P3

**Higher bit depth**:
- SDR: Usually 8-bit
- HDR: 10-bit minimum (required for smooth gradients in extended range)

### Transfer Functions

**PQ (Perceptual Quantizer, SMPTE ST 2084)**:
- Absolute brightness encoding
- Each code value = specific brightness level
- Used by HDR10, HDR10+, Dolby Vision

**HLG (Hybrid Log-Gamma)**:
- Relative brightness encoding
- Backward compatible with SDR displays
- Used primarily for broadcast

## HDR Formats

### HDR10

**Standard**: SMPTE ST 2086

**Characteristics**:
- Static metadata (one set for entire video)
- Open standard, no licensing
- Most widely supported

**Metadata**:
- Mastering display primaries
- Mastering display luminance (min/max)
- MaxCLL (Maximum Content Light Level)
- MaxFALL (Maximum Frame Average Light Level)

### HDR10+

**Standard**: SMPTE ST 2094-40

**Characteristics**:
- Dynamic metadata (per-scene or per-frame)
- Samsung/Amazon developed
- Limited device support

**Advantages over HDR10**:
- Per-scene optimization
- Better tonemapping on limited displays
- No licensing fees

### Dolby Vision

**Characteristics**:
- Dynamic metadata
- Profile system (various capabilities)
- Requires licensing
- Dual-layer or single-layer options

**Common Profiles**:

| Profile | Description | Base Layer |
|---------|-------------|------------|
| Profile 5 | Single layer, common streaming | None |
| Profile 7 | Dual layer, UHD Blu-ray | HDR10 |
| Profile 8 | Single layer, enhanced | HLG compatible |

**MediaInfo identifier**: `dvhe.XX.XX` where XX indicates profile and level.

## MediaInfo Fields

### Essential HDR Fields

```
HDR format                      : SMPTE ST 2086, HDR10 compatible
Mastering display color prim.   : Display P3
Mastering display luminance     : min: 0.0001 cd/m2, max: 1000 cd/m2
Maximum Content Light Level     : 812 cd/m2
Maximum Frame-Average Light Lev : 342 cd/m2
```

### Field Meanings

**Mastering display color primaries**:
- Color space used during grading
- Usually Display P3 or BT.2020
- Indicates target color gamut

**Mastering display luminance**:
- Min: Black level capability of mastering monitor
- Max: Peak brightness capability
- Range indicates grading target

**MaxCLL (Maximum Content Light Level)**:
- Brightest pixel value in entire video
- Helps displays optimize tonemapping
- Low values (<100) suggest fake HDR

**MaxFALL (Maximum Frame-Average Light Level)**:
- Average of brightest pixels per frame, then max of those
- Lower than MaxCLL
- Another tonemapping hint

## Fake HDR Detection

### Red Flags

**Low MaxCLL**:
- MaxCLL ≤ 100 nits suggests SDR-range content
- Legitimate HDR typically 400+ nits
- Very high values (10000+) may be placeholder

**No mastering metadata**:
- Professional HDR includes mastering data
- Missing metadata suggests conversion

**Wrong transfer function**:
- BT.709 transfer with HDR container = not HDR
- Must be PQ or HLG

**No official HDR release**:
- Content never released in HDR officially
- Random "HDR" version appears = fake

### Inverse Tonemapping Signs

When SDR is converted to HDR:
- Highlights don't contain additional detail
- Shadows don't reveal more information
- Looks flat compared to real HDR
- Often oversaturated to compensate

### Verification Process

1. **Check MaxCLL/MaxFALL**: Low values = likely fake
2. **Research official releases**: Was HDR version released?
3. **Compare visually**: Does it actually use extended brightness?
4. **Check source**: Where did the release come from?

## Tonemapping

### What It Is

Converting HDR content for SDR display by compressing brightness range.

### Tonemapping Algorithms

**Static tonemapping**:
- Same curve applied throughout
- May clip highlights or crush shadows
- Simpler, faster

**Dynamic tonemapping**:
- Per-scene or per-frame adjustments
- Better preservation of intent
- Requires HDR10+ or Dolby Vision

### When SDR Is Better

**Use SDR version if**:
- HDR version is fake/inverse tonemapped
- No HDR display available
- SDR version has better encoding quality
- HDR version has conversion artifacts

## MediaInfo Analysis Examples

### Legitimate HDR10

```
Color primaries             : BT.2020
Transfer characteristics    : PQ
Matrix coefficients         : BT.2020 non-constant
HDR format                  : SMPTE ST 2086, HDR10 compatible
Mastering display primaries : Display P3
Mastering display luminance : min: 0.0050 cd/m2, max: 4000 cd/m2
MaxCLL                      : 1247 cd/m2
MaxFALL                     : 487 cd/m2
```

Analysis: Real HDR. MaxCLL shows actual bright content (1247 nits), mastering data present, proper color space.

### Suspicious HDR

```
Color primaries             : BT.2020
Transfer characteristics    : PQ
Matrix coefficients         : BT.2020 non-constant
MaxCLL                      : 100 cd/m2
MaxFALL                     : 76 cd/m2
```

Analysis: Likely fake. MaxCLL only 100 nits (SDR range). No mastering display info. Probably inverse tonemapped.

### Fake HDR

```
Color primaries             : BT.709
Transfer characteristics    : BT.709
HDR format                  : Dolby Vision, dvhe.05.06
```

Analysis: Definitely fake. Color primaries and transfer are SDR (BT.709) but tagged as Dolby Vision. Impossible combination.

## Resources

- **HDR10+ Technologies**: https://hdr10plus.org
- **Dolby Vision Specs**: https://professional.dolby.com
- **JET Guide HDR Section**: https://jaded-encoding-thaumaturgy.github.io/JET-guide/
