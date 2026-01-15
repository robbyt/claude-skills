---
name: hdr-audit
description: This skill should be used when the user asks "is this real HDR", "check HDR metadata", "fake HDR", "is this Dolby Vision legitimate", "HDR vs SDR", "check HDR peak brightness", or wants to verify whether HDR content is genuine or inverse tonemapped from SDR.
---

# HDR Content Audit

Analyze HDR metadata and detect fake/invalid HDR content. HDR is not automatically better than SDR—many "HDR" releases are fake.

## What Makes HDR Real

Legitimate HDR requires:
1. **10-bit color depth** (minimum)
2. **HDR transfer function** (PQ or HLG)
3. **Actual extended brightness** (content above 100 nits)
4. **Mastered in HDR** from HDR source or graded for HDR

## Fake HDR Indicators

**Inverse tonemapped SDR**:
- SDR content artificially expanded to HDR range
- No actual detail gained in highlights
- Often looks flat or washed out on HDR displays
- Content never officially released in HDR

**HDR container, SDR content**:
- HDR metadata present but peak brightness never exceeds ~100 nits
- Tagged as HDR but visually identical to SDR

**Suspicious Dolby Vision**:
- Content only officially released in SDR
- DV metadata on old catalog titles
- Random releases that don't match official offerings

## MediaInfo HDR Fields

Key fields to check in Video section:

```
HDR format                   : SMPTE ST 2086 / SMPTE ST 2094...
Color primaries              : BT.2020
Transfer characteristics     : PQ (SMPTE 2084) or HLG
Matrix coefficients          : BT.2020 non-constant
Mastering display color prim : BT.2020 or DCI-P3
Mastering display luminance  : min: 0.0050 cd/m2, max: 1000 cd/m2
MaxCLL                       : 1000 cd/m2
MaxFALL                      : 400 cd/m2
```

## Audit Workflow

### Step 1: Check Basic HDR Presence

Run MediaInfo and look for:
- Transfer characteristics: Should be PQ or HLG (not BT.709)
- Bit depth: Should be 10 or 12 bit
- Color primaries: Should be BT.2020 (wide color gamut)

**If any are missing/wrong**: Not HDR, or broken HDR.

### Step 2: Check Mastering Metadata

Look for mastering display info:
- **MaxCLL** (Content Light Level): Peak brightness in content
- **MaxFALL** (Frame Average Light Level): Average peak per frame
- **Mastering display luminance**: Range used in grading

**Red flags**:
- MaxCLL ≤ 100 nits (SDR range only)
- No mastering metadata at all
- Generic/placeholder values

### Step 3: Verify Official HDR Release Exists

Research whether the content was officially released in HDR:
- Check streaming services (Netflix, Disney+, etc.)
- Check UHD Blu-ray releases
- Search for official announcements

**If no official HDR exists**: The "HDR" version is almost certainly fake.

### Step 4: Visual Inspection (If Possible)

On an HDR display:
- Does the content use the extended brightness range?
- Are highlights noticeably brighter than SDR?
- Does it look natural or artificially boosted?

## HDR Formats

### HDR10

- Static metadata (one set of values for whole video)
- Most common format
- Open standard

**MediaInfo shows**:
```
HDR format: SMPTE ST 2086
```

### HDR10+

- Dynamic metadata (per-scene or per-frame optimization)
- Samsung/Amazon developed
- Not widely supported

**MediaInfo shows**:
```
HDR format: SMPTE ST 2094 App 4
```

### Dolby Vision

- Dynamic metadata
- Profile-based system (various capabilities)
- Requires licensing

**MediaInfo shows**:
```
HDR format: Dolby Vision, dvhe.05.06
```

**Dolby Vision Profiles**:
- Profile 5: Single layer, common for streaming
- Profile 7: Dual layer with base HDR10
- Profile 8: Similar to Profile 5 with HLG base

## Quick Reference

| Check | Expected for Real HDR | Fake HDR Indicator |
|-------|----------------------|-------------------|
| MaxCLL | >100 nits | ≤100 nits |
| Transfer | PQ or HLG | BT.709 tagged as HDR |
| Bit depth | 10+ bit | 8 bit |
| Official release | Yes | No HDR release exists |
| Visual brightness | Extended range used | Looks like SDR |

## Common Fake HDR Scenarios

**Older movies "remastered" in HDR**:
- If studio didn't announce HDR remaster, it's fake
- Many pirate releases add fake HDR to old content

**Anime in HDR**:
- Very few anime are produced in HDR
- Most "HDR anime" is inverse tonemapped

**Random Dolby Vision releases**:
- DV requires licensing and official mastering
- Unauthorized DV releases are synthetic conversions

## Recommendations

**When to use HDR version**:
- Official HDR release from studio
- MaxCLL shows actual extended brightness
- Content mastered specifically for HDR

**When to use SDR version**:
- No official HDR release
- HDR shows fake indicators
- SDR version has better encoding quality
- HDR version has conversion artifacts

## Additional Resources

- **`${CLAUDE_PLUGIN_ROOT}/references/hdr.md`** - Detailed HDR metadata guide
- **`${CLAUDE_PLUGIN_ROOT}/references/color-space.md`** - Color space fundamentals
