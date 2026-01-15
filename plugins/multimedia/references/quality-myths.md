# Video Quality Myths

Common misconceptions about video quality and why they're wrong.

## The Core Principle

**Quality** = how closely a video resembles its original source.

Quality can only be measured relative to a reference. Without ground truth, evaluation becomes subjective. The encoding process should preserve the source as faithfully as possible.

## Myth: Resolution = Quality

### The Truth

Resolution is the pixel grid size, not visual fidelity. A badly encoded 4K video looks worse than a well-encoded 1080p video.

### Why Resolution Doesn't Equal Quality

**Upscaling doesn't add detail:**
- AI or conventional upscaling can only work with existing pixels
- Any "detail" added by upscaling is invented, not recovered
- Upscaling takes video further from source, not closer

**Native resolution matters:**
- Many "4K" releases are upscaled from 1080p or lower masters
- Digital anime is often produced at 720p or lower, then upscaled
- Some Blu-rays are poorly upscaled DVDs

**Downscaling for file size is suboptimal:**
- Better to adjust CRF/quality settings than reduce resolution
- Encoder can intelligently allocate bits where needed
- Downscaling forces detail loss everywhere uniformly

### When Resolution Matters

- Native resolution content (not upscaled)
- Matching display resolution for sharp playback
- Text legibility at small sizes

## Myth: Higher Bitrate = Better Quality

### The Truth

Bitrate measures data used, not quality achieved. An inefficient encode at 20 Mbps can look worse than an efficient encode at 8 Mbps.

### Why Bitrate Is Misleading

**Encoder efficiency varies dramatically:**
- x264 at 8 Mbps often beats NVENC at 15 Mbps
- Different presets change efficiency at same bitrate
- AV1 can match x264 quality at half the bitrate (for some content)

**Content complexity affects needs:**
- Static scenes need fewer bits than action scenes
- Grain/texture is expensive to preserve
- Animation compresses more efficiently than live action

**VBR distributes bits intelligently:**
- Simple scenes use fewer bits
- Complex scenes get more bits
- CBR wastes bits on simple scenes

### What Actually Matters

- Encoder used (x264/x265 vs hardware encoders)
- Encoding settings (preset, CRF)
- Source quality
- Content type

## Myth: File Format = Quality

### The Truth

File format (mkv, mp4) is the container, not the encoding. The same H.264 stream can be in either container with identical quality.

### Container vs Codec

| Container | Codec |
|-----------|-------|
| Stores/packages streams | Compresses video data |
| mkv, mp4, webm, avi | H.264, H.265, VP9, AV1 |
| Changing = remux (fast) | Changing = reencode (slow) |
| No quality impact | Determines quality |

### Why This Matters

"Convert mkv to mp4" can mean:
1. Remux (correct): Extract stream, put in new container. Fast, lossless.
2. Reencode (wrong): Decode, re-encode. Slow, quality loss.

Many "converter" tools reencode by default, destroying quality unnecessarily.

## Myth: Newer Codec = Better Quality

### The Truth

The codec format defines encoding possibilities. The actual encoder and settings determine quality.

### Why Format Alone Doesn't Determine Quality

**The "HEVC is 50% more efficient" claim is misleading:**
- Real-world gains are smaller and content-dependent
- Depends heavily on encoder implementation
- x264 can beat poor H.265 encoders

**Encoder quality varies:**
- x265 >> hardware H.265 encoders for quality
- AV1 efficiency gains depend on encoder maturity
- Older x264 often beats newer but poorly-tuned H.265

**Target quality level matters:**
- AV1 excels at low bitrates
- x264/x265 still superior for transparency (high quality)

### What Matters More Than Format

1. Encoder software (x264, x265, SVT-AV1)
2. Encoding settings (preset, CRF, tune)
3. Source quality
4. Encoding expertise

## Myth: Sharper = Better

### The Truth

Sharpness is not quality. Over-sharpened video has artifacts and deviates from the source.

### Sharpening Damage

**Haloing:** Bright/dark outlines around edges
**Ringing:** Wavy patterns near sharp transitions
**Line warping:** Straight lines become distorted
**Texture crunching:** Unnatural crispy appearance

### Why Sharpening Is Harmful

- Source material has intentional softness in places
- Sharpening cannot distinguish intentional from unintentional blur
- Artifacts compound with compression
- Takes video further from source

### The Sharp ≠ Quality Trap

Layman viewers prefer sharpened images initially. Trained eyes see:
- Haloing around all edges
- Destroyed fine detail
- Unnatural appearance
- Compression struggling with artificial edges

## Myth: HDR = Better Than SDR

### The Truth

HDR is a capability, not automatically better. Quality depends on source and mastering.

### When HDR Is Better

- Content mastered in HDR from HDR source
- Proper HDR display for viewing
- Metadata correctly preserved

### When HDR Is Not Better

- Inverse tonemapped from SDR (fake HDR)
- SDR content with HDR container (no actual extended range)
- HDR that never exceeds 100 nits
- Viewed on SDR display (tonemapping loses information)

### Red Flags for Fake HDR

- HDR version of content never officially released in HDR
- Peak brightness never exceeds SDR levels
- Dolby Vision on known SDR-only content
- Random releases with HDR that official sources lack

## Myth: Blu-ray Is Always Better Than Web

### The Truth

Blu-ray has higher bitrate potential, but mastering quality varies. Web sources can be better in specific cases.

### When Blu-ray Wins

- Same master, Blu-ray has more bitrate
- Web version is heavily compressed
- No destructive filtering on Blu-ray

### When Web Wins

- Blu-ray has lowpass (blur) applied
- Different (better) color grading on web
- Blu-ray is poor upscale of SD source
- Web has newer, better master

### The Real Question

Which source is closer to the original master? Higher bitrate only helps if the source material is clean.

## Summary: What Actually Determines Quality

1. **Source quality** - Garbage in, garbage out
2. **Encoding software** - x264/x265 >> hardware encoders
3. **Encoding settings** - CRF, preset, appropriate options
4. **Preservation intent** - Staying true to source, not "improving"
5. **Processing chain** - Fewer steps = less quality loss

## Rules for Quality

1. Use best available source
2. Encode with x264/x265 (not NVENC for archival)
3. Adjust CRF for quality/size tradeoff
4. Don't upscale, interpolate, sharpen, or "improve colors"
5. Minimize encoding generations (reencode only once)
6. Compare output to source to verify quality
