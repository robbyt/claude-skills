# Multimedia Plugin

Video and audio file analysis, quality auditing, and encoding guidance for Claude Code.

## Skills

| Skill | Purpose |
|-------|---------|
| `video-audit` | Analyze video files to understand properties and recommend actions |
| `artifact-detect` | Identify quality issues like compression artifacts, sharpening damage, upscaling problems |
| `format-explain` | Educational explanations of video concepts (container vs codec, color space, etc.) |
| `telecine-detect` | Detect telecined vs interlaced content and advise on proper handling |
| `source-compare` | Compare multiple video sources to determine which has better quality |
| `hdr-audit` | Analyze HDR metadata and detect fake/invalid HDR content |
| `framerate-audit` | Analyze frame rate characteristics, CFR vs VFR, duplicate frames |
| `subtitle-audit` | Analyze subtitle tracks for missing fonts, timing, format issues |

## Prerequisites

Install these tools for full functionality:

```bash
# macOS
brew install mediainfo ffmpeg mkvtoolnix

# Linux
apt install mediainfo ffmpeg mkvtoolnix

# mpv (recommended media player)
brew install mpv  # macOS
apt install mpv   # Linux
```

Optional for advanced work:
- Aegisub (subtitle editing)
- Wobbly (telecine analysis)
- VapourSynth (frame analysis)

## Usage Examples

- "Audit this video file to check its quality"
- "What's wrong with this video? It looks bad"
- "Explain what BT.709 means"
- "Is this video interlaced or telecined?"
- "Compare these two video sources"
- "Is this real HDR or fake?"
- "Check if this video is CFR or VFR"
- "Check the subtitle tracks in this file"

## References

Shared reference files in `references/`:

| File | Content |
|------|---------|
| `quality-myths.md` | Common misconceptions about video quality |
| `color-space.md` | Color matrices, range, chroma location |
| `artifacts.md` | Artifact identification guide |
| `tools.md` | Recommended and discouraged tools |
| `encoding-commands.md` | ffmpeg/mpv command templates |
| `telecine.md` | Telecine patterns and IVTC workflow |
| `hdr.md` | HDR metadata and fake HDR detection |

## External Resources

- Source article: https://gist.github.com/arch1t3cht/b5b9552633567fa7658deee5aec60453
- Interlacing guide: https://fieldbased.media
- Wobbly IVTC: https://wobbly.encode.moe
- JET encoding guide: https://jaded-encoding-thaumaturgy.github.io/JET-guide/
- Frame comparisons: https://slow.pics
