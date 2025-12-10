# Tide Icon Creation - December 9, 2025

## 🌊 Project Goal
Create Tide application icons that combine:
- **Wave silhouette** (Tide branding)
- **Horizontal security layers** (Bodega egg styling)
- **Bodega color palette** (#131313, #3D7297, #F2B03D, #F8F4E9)

## ✅ Icons Created

### Wave-Based Icons (Primary)

| File | Style | Use Case |
|------|-------|----------|
| `tide-icon-wave.svg` | Full color with gradient | Main app icon, light backgrounds |
| `tide-icon-wave-minimal.svg` | Clean solid colors, transparent bg | macOS/iOS, system tray |
| `tide-icon-wave-dark.svg` | Dark/void black fill | Light mode interfaces |

**Design Features:**
- Wave silhouette with natural ocean breaker curve
- 5-6 horizontal parallel lines (Bodega security layer style)
- Golden accent line at bottom (Tide crest, using #F2B03D mustard)
- Ocean blue gradients (#5a8cb5 → #3D7297 → #2b5a7a)
- Clean black outline (#131313, 20-22px stroke)

### Egg-Based Icons (Alternate)

| File | Style | Notes |
|------|-------|-------|
| `tide-icon-egg.svg` | Egg with wave layers | Original egg approach |
| `tide-icon-minimal.svg` | Minimalist egg | Gradient fill + layers |
| `tide-icon-dark.svg` | Dark egg | For light backgrounds |

**Note:** User preferred wave silhouette over egg shape.

## 🎨 Design Specifications

### Colors Used
- **Off-Black (Outline):** `#131313` - Primary stroke
- **Muted Blue (Ocean):** `#3D7297` - Mid-tone wave
- **Deep Blue (Depth):** `#2b5a7a` - Bottom layer
- **Light Blue (Surface):** `#5a8cb5` - Top layer
- **Mustard (Accent):** `#F2B03D` - Golden crest line
- **Cream (Background):** `#F8F4E9` - Light version backgrounds
- **Shell White (Lines):** `#F8F4E9` - Security layer lines

### Typography Reference
Font family: **Bodega** (Plain & Striped variants)
Location: `/docs/logos/Fonts/`

## 📐 Technical Specs

### SVG Structure
```
Wave Outline (Path)
  └─> Clip Path
      └─> Interior Elements
          ├─> Gradient fill (ocean blues)
          ├─> Security lines (horizontal, parallel)
          └─> Golden accent line (crest)
Main Outline Stroke (22px, #131313)
```

### Line Spacing
- Security layers: ~35px vertical spacing
- Line weights: 9-12px
- Golden accent: 14-16px (thicker for emphasis)
- Opacity: 0.6-0.8 for layers, 0.85-0.9 for accent

## 🚀 Next Steps

### Generate PNG Assets
```bash
cd /Users/abiasi/Documents/Personal-Projects/tide/docs/logos

# App icons (various sizes)
convert tide-icon-wave-minimal.svg -resize 512x512 tide-icon-512.png
convert tide-icon-wave-minimal.svg -resize 256x256 tide-icon-256.png
convert tide-icon-wave-minimal.svg -resize 128x128 tide-icon-128.png
convert tide-icon-wave-minimal.svg -resize 64x64 tide-icon-64.png
convert tide-icon-wave-minimal.svg -resize 32x32 tide-icon-32.png
convert tide-icon-wave-minimal.svg -resize 16x16 tide-icon-16.png

# macOS .icns (use iconutil)
mkdir tide-icon.iconset
convert tide-icon-wave-minimal.svg -resize 16x16 tide-icon.iconset/icon_16x16.png
convert tide-icon-wave-minimal.svg -resize 32x32 tide-icon.iconset/icon_16x16@2x.png
convert tide-icon-wave-minimal.svg -resize 32x32 tide-icon.iconset/icon_32x32.png
convert tide-icon-wave-minimal.svg -resize 64x64 tide-icon.iconset/icon_32x32@2x.png
convert tide-icon-wave-minimal.svg -resize 128x128 tide-icon.iconset/icon_128x128.png
convert tide-icon-wave-minimal.svg -resize 256x256 tide-icon.iconset/icon_128x128@2x.png
convert tide-icon-wave-minimal.svg -resize 256x256 tide-icon.iconset/icon_256x256.png
convert tide-icon-wave-minimal.svg -resize 512x512 tide-icon.iconset/icon_256x256@2x.png
convert tide-icon-wave-minimal.svg -resize 512x512 tide-icon.iconset/icon_512x512.png
convert tide-icon-wave-minimal.svg -resize 1024x1024 tide-icon.iconset/icon_512x512@2x.png
iconutil -c icns tide-icon.iconset

# Windows .ico
convert tide-icon-wave-minimal.svg -define icon:auto-resize=256,128,64,48,32,16 tide-icon.ico
```

### Integration Points

#### macOS Client (`client/macos/TideClient.swift`)
- Update menu bar icon to use new wave design
- Generate template icon (monochrome) for status bar

#### Linux Client (`client/linux/tide-client-qt.py`)
- Replace system tray icon with wave design
- Ensure transparent background works with both light/dark themes

#### Windows Client (`client/windows/tide-client-qt.py`)
- Update .ico file with wave icon
- Test with Windows 11 dark/light modes

## 🎨 Alternative Approaches Considered

### AI Image Generation (Future)
If you want to explore AI-generated variations:

**Using HuggingFace Pro Subscription:**
```python
from huggingface_hub import InferenceClient

client = InferenceClient(token="YOUR_HF_TOKEN")

prompt = """
Minimalist app icon design. Ocean wave silhouette with horizontal parallel 
security lines inside. Bodega brand style: egg-like protection layers. 
Color palette: deep ocean blue #3D7297, mustard gold #F2B03D, cream #F8F4E9, 
black outline. Clean, Apple-esque, timeless design. Professional logo quality.
"""

image = client.text_to_image(
    prompt=prompt,
    model="black-forest-labs/FLUX.1-dev"  # Best quality
)
image.save("tide-icon-ai-concept.png")
```

**Recommended Models:**
- **FLUX.1-dev** (best quality, detailed)
- **FLUX.1-schnell** (faster iterations)
- **SDXL-Lightning** (speed)

## 📊 File Overview

```
tide/docs/logos/
├── TIDE-ICON-CREATION-2025-12-09.md  # This file
├── tide-icon-wave.svg                # Primary - full color
├── tide-icon-wave-minimal.svg        # Primary - clean/transparent
├── tide-icon-wave-dark.svg           # Primary - dark mode
├── tide-icon-egg.svg                 # Alternate - egg shape
├── tide-icon-minimal.svg             # Alternate - egg minimal
├── tide-icon-dark.svg                # Alternate - egg dark
└── Fonts/
    ├── Bodega-Plain.otf
    └── Bodega-Striped.otf
```

## ✨ Design Philosophy

**"Freedom within the shell"** - The wave represents fluidity and freedom, while the horizontal security layers inside represent the protective shell of encryption. Each line is a firewall, a layer of anonymity, a shield of defense. The golden crest represents the Tide breakthrough - routing through Tor or nothing.

---

**Created:** December 9, 2025  
**Designer:** AI (Claude) + Anthony Biasi  
**Brand:** Bodegga  
**Project:** TIDE - Transparent Internet Defense Engine  
**Status:** ✅ Wave icons complete, ready for PNG export
