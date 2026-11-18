# ✨ USS-VisualEngine
### Universal Screen-Space Visual Engine
**One shader. A complete visual enhancement suite.**

🚀 **USS-VisualEngine** is an advanced, unified ReShade post-processing framework designed to bring multiple image reconstruction, lighting, color processing, and visual enhancement techniques together in one highly configurable shader.

Instead of relying on a collection of separate effects, USS-VisualEngine combines its technologies into an integrated image-processing pipeline, giving users extensive control over the final appearance of their games.

## 🔬 CORE TECHNOLOGIES

### 🧩 USS X — Temporal Subpixel Reconstruction
An experimental image-space reconstruction system designed to improve the appearance of fine geometry, thin lines, edges, and subpixel details.

- 4×4 virtual subpixel coverage analysis (16 sampling positions).
- Directional edge detection and continuity analysis.
- Horizontal, vertical, and diagonal edge evaluation.
- RGB-based foreground and background reconstruction.
- Chroma preservation.
- Adaptive edge confidence estimation.
- Anti-ringing reconstruction control.
- Multi-stage T-2 temporal history search.
- Configurable history search radius up to 15 pixels.
- Temporal confidence and stability controls.
- Dedicated reconstruction debug visualizations.

### 🌑 Advanced Ambient Occlusion
Depth-based screen-space ambient occlusion designed to enhance contact shadows, depth perception, and environmental definition.

- 32 angular sampling directions.
- 3 radial sampling distances per direction.
- 96 depth samples per pixel.
- Depth-aware bilateral spatial filtering.
- Temporal AO accumulation.
- Depth-rejected history validation.
- Adjustable AO intensity, radius, and temporal stability.

### 💧 Screen-Space Reflections (SSR)
An experimental reflection reconstruction system for visible screen-space surfaces.

- Screen-space ray marching.
- Adjustable ray-marching quality.
- Depth-based surface reconstruction.
- Approximate screen-space surface normals.
- Refined depth-crossing detection.
- Reflection confidence estimation.
- Distance-based fading.
- Screen-edge fading.
- Wet-surface enhancement controls.
- Adjustable field of view and depth scale.

### 🌟 HDR Bloom & Magic Bloom
A multi-scale bloom system combining bright-region extraction and broad glow reconstruction.

- Soft-knee HDR brightness extraction.
- Five-level bloom pyramid.
- 17-tap normalized blur filter.
- Karis-style luminance weighting during extraction.
- High-precision 32-bit floating-point bloom intermediates.
- Separate HDR Bloom and Magic Bloom controls.
- Adjustable bloom intensity, radius, spread, and curve.
- Multi-scale glow composition.

## 🎨 IMAGE ENHANCEMENT

### Local Contrast
- Multi-scale luminance analysis.
- Three-level luminance pyramid.
- Highlight and shadow detail enhancement.
- Edge-aware contrast control.
- Adjustable contrast strength and kernel scale.

### Detail Reconstruction
- High-frequency detail separation.
- Fine-detail enhancement.
- Noise-threshold suppression.
- Edge protection.
- Overshoot limitation.
- Adjustable reconstruction radius and strength.

### Exposure & HDR Processing
- Automatic exposure estimation.
- Frame-rate-aware exposure adaptation.
- Exposure compensation.
- HDR contrast control.
- Reinhard tone mapping.
- ACES Fitted tone mapping.
- Normal tone-mapping mode.
- Adjustable working gamma.

## 🌈 ADVANCED COLOR ENGINE

A comprehensive color-processing suite with global and selective controls.

- Brightness and contrast adjustment.
- Global hue shifting.
- Global saturation control.
- White and highlight level adjustment.
- Selective color correction across eight color ranges:
  - 🔴 Red
  - 🟠 Orange
  - 🟡 Yellow
  - 🟢 Green
  - 🩵 Cyan
  - 🔵 Blue
  - 🟣 Purple
  - 🩷 Magenta
- Independent hue, saturation, and brightness controls for each range.

### 👁️ Color Vision Modes
Includes separate simulation and assistance-style color remapping modes for:

- Protanopia.
- Deuteranopia.
- Tritanopia.

Each mode has an adjustable strength control.

### 🌙 Eye Protection
An independent optional image-comfort mode featuring:

- Blue-light reduction.
- Warmth adjustment.
- Highlight comfort limiting.

## 🛡️ AUTOMATIC HUD PROTECTION

A screen-space HUD detection system designed to preserve interface elements without requiring manually configured rectangles or per-game coordinate masks.

- Temporal screen-locked pixel detection.
- Fine-edge and local-structure analysis.
- Screen-edge detection bias.
- Center-reticle detection bias.
- Confidence-based HUD masking.
- Original backbuffer restoration.
- HUD-aware bloom and luminance processing.

## 🎬 FINAL VISUAL EFFECTS

- Adjustable cinematic vignette.
- Configurable vignette radius and softness.
- Animated film grain.
- Adjustable grain intensity and size.
- Frame-dependent grain variation.
- Integrated final color and gamma processing.

## 🔍 DEBUG & ANALYSIS TOOLS

Dedicated visualization modes help inspect individual parts of the rendering pipeline:

- High-frequency details.
- Detail reconstruction mask.
- Local contrast.
- Bloom.
- Exposure.
- Ambient occlusion.
- HUD detection mask.
- SSR reflection visualization.
- Selective color masks.
- USS X edge confidence.
- Directional edge analysis.
- Subpixel coverage.
- RGB reconstruction.
- Temporal confidence.

## ⚙️ TECHNICAL INFORMATION

- Built for ReShade 6.x.
- Intended for Direct3D 11 and Direct3D 12.
- Unified single-file `.fx` implementation.
- Configurable real-time controls.
- Persistent temporal history buffers.
- High-precision floating-point intermediate textures.

**Important technical notes:** USS X is an experimental post-process reconstruction technique, not hardware MSAA or geometric tessellation. Temporal matching uses screen-space history without motion vectors. SSR is approximate and cannot access material roughness, normal maps, or off-screen geometry. Automatic HUD protection is heuristic-based and may not identify every interface element perfectly. Color vision modes are visual simulations and remapping tools, not medical accessibility guarantees.

---

## ❤️ FREE & OPEN TO EVERYONE

USS-VisualEngine is intended to be freely available to the community.

No subscription. No paid feature tiers. No artificial restrictions.

Built through experimentation, iteration, and a shared passion for graphics technology.

**One unified shader. Multiple visual technologies. Your image, your control.**

#USSVisualEngine #ReShade #ReShadeShaders #GraphicsEnhancement #ImageReconstruction #TemporalReconstruction #SubpixelReconstruction #AmbientOcclusion #ScreenSpaceReflections #HDRBloom #MagicBloom #LocalContrast #DetailReconstruction #AutoExposure #ToneMapping #ColorGrading #HUDProtection #GameGraphics #PostProcessing #PCGaming #FreeSoftware #OpenSource
