# Video Artifacts Catalog

Detailed guide to identifying video artifacts, their causes, and assessment.

## Compression Artifacts

### Blocking (Macroblocking)

**Appearance**: Square or rectangular blocks visible in image, especially during motion or in gradients.

**Cause**:
- Video codecs divide frames into blocks (typically 16x16 or smaller)
- At low bitrates, quantization causes blocks to become visible
- Block boundaries become apparent when adjacent blocks have different average values

**Where to look**:
- Fast motion scenes
- Gradients (sky, shadows)
- Areas with subtle color transitions
- Dark scenes (quantization error more visible)

**Severity indicators**:
- Mild: Only visible in specific problem scenes
- Moderate: Visible in most scenes on close inspection
- Severe: Obvious at normal viewing distance

**Source vs encoding issue**: Could be either. Check if source has same blocking.

### Banding

**Appearance**: Visible steps/bands in gradients instead of smooth transitions. Looks like contour lines on a topographic map.

**Cause**:
- Insufficient bit depth for smooth gradients
- Aggressive quantization removing subtle variations
- Source may have been processed with banding-inducing filters
- Dithering removed during processing

**Where to look**:
- Sky gradients (especially blue sky, sunset)
- Dark shadows transitioning to black
- Smooth surfaces (walls, skin in soft lighting)
- Any area with gentle color gradients

**Source vs encoding issue**: Often a source problem. Check original.

### Mosquito Noise

**Appearance**: Fuzzy, shifting noise around sharp edges. Looks like tiny insects buzzing around edges.

**Cause**:
- DCT-based compression struggling with sharp transitions
- High-frequency information lost and recreated imperfectly
- Worse at lower bitrates

**Where to look**:
- Around text overlays and credits
- High-contrast edges
- Animation line art
- Logos and graphics

**Distinguishing from grain**: Mosquito noise shifts and buzzes; grain is consistent texture.

### DCT Ringing

**Appearance**: Wavy patterns radiating from sharp edges. Similar to ripples in water.

**Cause**:
- Gibbs phenomenon in DCT transform
- Sharp edges create high frequencies that get truncated
- Reconstruction creates oscillating artifacts

**Where to look**:
- Near text
- Around logos
- Any sharp, high-contrast transition

## Post-Processing Artifacts

### Sharpening Halos

**Appearance**: Bright or dark outlines around edges. Like edges have been traced with highlighter.

**Cause**:
- Unsharp mask or similar sharpening filters
- Warp sharpening algorithms
- "Enhancement" processing

**Characteristics**:
- Consistent width throughout video
- Same side of edges always affected
- Bright halo on bright side, dark on dark side (or vice versa)

**Where to look**:
- Around character outlines
- Text and titles
- Any hard edge in the image
- Most obvious against flat backgrounds

**Severity assessment**:
- Mild: Thin, subtle haloing
- Moderate: Clearly visible halos
- Severe: Thick glowing outlines, line warping

### Line Warping

**Appearance**: Straight lines appear wavy or distorted.

**Cause**:
- Aggressive sharpening algorithms
- Some AI enhancement methods
- Over-processing

**Where to look**:
- Architecture (buildings, doorframes)
- Text and credits
- Grid patterns
- Any straight line in source

### Over-sharpened Texture

**Appearance**: Unnatural crispness, "crunchy" look. Details pop out unnaturally.

**Cause**:
- Excessive sharpening
- "HDR look" processing
- Local contrast enhancement

**Comparison**: Natural texture has subtle variations; over-sharpened looks like an overprocessed photo.

## Upscaling Artifacts

### AI Hallucinations

**Appearance**: Invented details that look plausible but weren't in source. May appear as:
- Hair strands that merge or split unnaturally
- Fabric textures that shift between frames
- Text that's sharper than surroundings but contains errors
- Faces with subtle distortions

**Cause**:
- AI upscaling (Real-ESRGAN, Topaz, Anime4K, etc.)
- Neural network "completing" details based on training data
- Generated details don't match temporal consistency

**Where to look**:
- Fine textures (hair, fabric, foliage)
- Text and numbers
- Repeating patterns
- Small facial features
- Background details

**Key indicator**: Details that are sharper than the actual source resolution could support.

### Interpolation Blur

**Appearance**: Soft, smeared edges. Loss of sharpness on fine details.

**Cause**:
- Bilinear or bicubic upscaling
- Low-quality scaling algorithms
- Resolution increase without detail enhancement

**Where to look**:
- Diagonal lines (show aliasing or blur)
- Fine text
- Any sharp detail in source

### Stairstepping (Aliasing)

**Appearance**: Jagged, stair-step edges on diagonal lines and curves.

**Cause**:
- Poor upscaling algorithm
- Missing anti-aliasing
- Integer scaling without smoothing

**Where to look**:
- Diagonal lines
- Curved edges
- Text at angles

## Color Artifacts

### Color Matrix Mismatch

**Appearance**: Overall color shift affecting entire frame. Hues are wrong, saturation may be off.

**Cause**:
- BT.601 content played as BT.709 (or vice versa)
- Encoding/decoding matrix mismatch
- Metadata missing or incorrect

**Characteristics**:
- Affects entire frame uniformly
- All colors shifted in similar direction
- Skin tones noticeably wrong

**Where to look**:
- Skin tones (good reference for color accuracy)
- Known colors (grass, sky, common objects)
- Compare to source or reference

### Chroma Shift

**Appearance**: Color misaligned with luminance. Colored fringe appears on one side of edges.

**Cause**:
- Wrong chroma location in encoding or playback
- Processing that doesn't preserve chroma alignment
- Editing software bugs

**Characteristics**:
- Consistent direction throughout frame
- Most visible on sharp, high-contrast edges
- Red/blue fringing on opposite sides of edges

**Where to look**:
- Sharp vertical or horizontal edges
- Text
- High-contrast transitions

**Distinguishing from chromatic aberration**:
- Chroma shift: Same direction everywhere, can be fixed by retagging
- Chromatic aberration: Varies by frame position, artistic effect

### Range Compression Issues

**Double compression appearance**:
- Crushed blacks (shadow detail lost to pure black)
- Clipped highlights (bright detail lost to pure white)
- Reduced overall contrast within midtones

**Cause**:
- Limited range treated as Full, then converted back to Limited
- Multiple processing steps with incorrect range handling

**Expansion appearance**:
- Washed out, low contrast
- Blacks appear gray
- Highlights appear dull

**Cause**: Full range treated as Limited

## Temporal Artifacts

### Frame Rate Judder

**Appearance**: Uneven motion, frames appear to jump or stutter.

**Cause**:
- Frame rate conversion errors
- Pulldown issues
- Playback at wrong rate

**Where to look**:
- Panning shots
- Steady camera motion
- Moving objects

### Duplicate Frames

**Appearance**: Motion stops briefly, then jumps. Frame appears frozen.

**Cause**:
- Frame rate conversion inserting duplicates
- Variable frame rate source converted to constant
- Encoding errors

**Detection**: Step through frame-by-frame, compare adjacent frames.

### Telecine Combing

**Appearance**: Horizontal lines across moving objects, like Venetian blind effect.

**Cause**:
- 24fps film telecined to 30fps (3:2 pulldown)
- Improper deinterlacing of telecined content
- Treating telecine as true interlacing

**Important**: Not all combing is interlacing. Telecine can be reversed nearly losslessly; deinterlacing cannot.

**Where to look**:
- Any motion
- Horizontal edges during movement

### Frame Interpolation Artifacts

**Appearance**:
- Morphing/warping during motion
- Ghosting on moving objects
- Unnatural "soap opera" smoothness
- Objects splitting or merging

**Cause**:
- Motion interpolation (RIFE, SVP, TV motion smoothing)
- Frame rate conversion from lower to higher fps

**Why it's bad**: Interpolated frames are generated, not captured. Motion doesn't match source intent.

## Assessing Artifact Severity

### Questions to Ask

1. **Visible at normal viewing distance?**
   - Yes → Significant issue
   - Only on inspection → Minor issue

2. **Affects all content or specific scenes?**
   - All content → Systematic problem
   - Specific scenes → May be source limitation

3. **Present in source or introduced?**
   - In source → Limitation, not encoding problem
   - Introduced → Encoding or processing error

4. **Fixable without reencode?**
   - Metadata issues → Retag, no quality loss
   - Actual data problems → Must reencode from source

### Severity Scale

| Level | Description |
|-------|-------------|
| Transparent | No visible artifacts at any zoom |
| Minor | Artifacts visible only when looking for them |
| Moderate | Artifacts visible but not distracting |
| Significant | Artifacts distracting during viewing |
| Severe | Artifacts dominate, unwatchable quality |

## Tool Reference

| Tool | Best For |
|------|----------|
| mpv | Frame stepping (`.` and `,`), technical info (`i`) |
| vs-preview | Side-by-side comparison, frame analysis |
| SlowPics | Sharing comparisons (use clicker, not slider) |
| MediaInfo | Technical metadata |
