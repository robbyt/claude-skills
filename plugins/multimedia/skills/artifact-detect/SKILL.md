---
name: artifact-detect
description: This skill should be used when the user asks "what's wrong with this video", "why does this video look bad", "detect video artifacts", "find quality issues", "video has artifacts", "identify compression artifacts", or wants to diagnose specific quality problems in a video file.
---

# Video Artifact Detection

Identify and diagnose specific quality issues in video files. Focus on visual inspection techniques and artifact recognition, not fixing the issues.

## Artifact Categories

### 1. Compression Artifacts

**Blocking (macroblocking)**
- Square or rectangular blocks visible in motion or gradients
- Caused by: Low bitrate encoding, high quantization
- Where to look: Fast motion scenes, areas with subtle color gradients
- Severity indicator: More visible = worse quality

**Banding**
- Visible steps/bands in color gradients instead of smooth transitions
- Caused by: Low bit depth, aggressive quantization, source issues
- Where to look: Sky gradients, dark shadows, smooth surfaces
- Note: May be source issue, not encoding issue

**Mosquito noise**
- Fuzzy, shifting noise around sharp edges
- Caused by: Lossy compression struggling with hard edges
- Where to look: Text overlays, high-contrast edges, animation line art

**DCT ringing**
- Wavy patterns near sharp edges
- Caused by: JPEG-based compression (H.264/H.265 use DCT)
- Where to look: Around text, logos, sharp transitions

### 2. Post-Processing Damage

**Haloing/Ringing from sharpening**
- Bright or dark outlines around edges
- Caused by: Oversharpening filters (unsharp mask, warp sharp)
- Where to look: Around character outlines, text, any hard edges
- Key sign: Consistent glow on one side of lines throughout video

**Line warping**
- Straight lines appear wavy or distorted
- Caused by: Aggressive sharpening algorithms
- Where to look: Architecture, text, grid patterns

**Oversharpened texture**
- Unnatural crispness, "crunchy" appearance
- Caused by: Excessive sharpening combined with compression
- Comparison: Should look natural, not like HDR photo filter

### 3. Upscaling Artifacts

**AI hallucinations**
- Invented details that weren't in source
- Caused by: AI upscaling (Real-ESRGAN, Topaz, etc.)
- Where to look: Fine textures (hair, fabric), text, repeating patterns
- Key sign: Details that seem too sharp or don't match surrounding areas

**Interpolation blur**
- Soft, smeared appearance on edges
- Caused by: Bilinear/bicubic upscaling
- Where to look: Diagonal lines, fine details
- Comparison: Native resolution looks sharper

**Stairstepping (aliasing)**
- Jagged edges on diagonal lines
- Caused by: Poor upscaling algorithm, no anti-aliasing
- Where to look: Diagonal lines, curved edges

### 4. Color Issues

**Wrong color matrix symptoms**
- Overall color shift (too green, too magenta)
- Caused by: BT.601/BT.709 mismatch
- Key sign: Colors look "off" but evenly across entire frame
- Verification: Compare to known-good source

**Chroma shift**
- Color misaligned with luminance
- Caused by: Wrong chroma location, processing error
- Where to look: Hard edges - look for color fringing on one side
- Key sign: Consistent colored glow on same side of all edges

**Double range compression**
- Crushed blacks, blown highlights
- Caused by: Limited range treated as full (or vice versa) multiple times
- Where to look: Dark shadows (crushed to pure black), bright areas (clipped)

### 5. Frame Rate Issues

**Judder/stutter**
- Uneven motion, frames "jumping"
- Caused by: Frame rate mismatch, bad pulldown
- Where to look: Panning shots, steady motion

**Duplicate frames**
- Same frame appears twice (or more)
- Caused by: Frame rate conversion errors
- Detection: Step frame-by-frame, compare adjacent frames

**Telecine combing**
- Horizontal lines across moving objects
- Caused by: Improper deinterlacing of telecined content
- Where to look: Horizontal edges during motion
- Note: Not all combing = interlaced. May be telecined (3:2 pulldown)

## Visual Inspection Checklist

When examining a video for artifacts, inspect these areas in order:

### High-Priority Areas

1. **Dark gradients and shadows** - Reveals banding, blocking, crushed blacks
2. **Strong colors (especially dark reds)** - Shows compression stress, color issues
3. **Around sharp edges** - Reveals haloing, ringing, mosquito noise, chroma shift
4. **On-screen text and logos** - Shows sharpness issues, compression artifacts clearly
5. **Image borders** - Often reveals encoding problems first

### Motion-Specific Checks

6. **Panning shots** - Reveals judder, duplicate frames, motion blur issues
7. **Fast action scenes** - Shows blocking, motion compensation failures
8. **Static grain/texture areas** - Reveals whether grain was filtered or preserved

### Comparison Technique

To spot artifacts effectively:
- View at 100% zoom (1:1 pixel mapping)
- Compare against known-good source if available
- Use frame-by-frame stepping for temporal artifacts
- Toggle between source and processed version rapidly

## Reporting Findings

When reporting detected artifacts, include:

1. **Artifact type** - Name from categories above
2. **Severity** - Subtle, moderate, severe
3. **Location** - Where in frame, what type of content affected
4. **Likely cause** - Based on artifact characteristics
5. **Fixability** - Can be fixed (retag, re-encode from source) or permanent damage

## Tools for Detection

- **mpv**: Best playback, press `i` for technical info, frame step with `.` and `,`
- **vs-preview**: Frame-by-frame comparison with VapourSynth
- **SlowPics**: For sharing comparison screenshots (not imgsli - converts to JPEG)

## Additional Resources

For detailed artifact catalogs with visual examples:
- **`${CLAUDE_PLUGIN_ROOT}/references/artifacts.md`** - Comprehensive artifact guide
- **`${CLAUDE_PLUGIN_ROOT}/references/color-space.md`** - Color issue diagnosis
