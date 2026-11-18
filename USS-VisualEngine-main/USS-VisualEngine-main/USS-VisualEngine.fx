#include "ReShade.fxh"

// ============================================================================
// USS-VisualEngine - Unified Color, Bloom and Screen-Space Reflection Engine
// Automatic HUD guard, precision bloom, depth-aware AO and temporal subpixel reconstruction
// ReShade 6.x / D3D11-D3D12 intended.
//
// ============================================================================
// CREDITS
//
// Project Author & Maintainer: Elshad03
// AI Development Assistant: ChatGPT (OpenAI)
//
// ============================================================================
// Contributions:
// - Shader architecture and algorithm development
// - HLSL code drafting and technical analysis
// - Debugging and optimization assistance
// - Documentation and release preparation
// ============================================================================
// ACES RRT/ODT fit adapted from:
// https://github.com/selfshadow/ltc_code/blob/master/webgl/shaders/ltc/ltc_blit.fs
// Copyright (c) 2017, Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt.
// See THIRD-PARTY-NOTICES.md for attribution and license terms.
// Color vision simulation matrices based on:
// Gustavo M. Machado, Manuel M. Oliveira, and Leandro A. F. Fernandes,
// "A Physiologically-based Model for Simulation of Color Vision Deficiency,"
// IEEE Transactions on Visualization and Computer Graphics, 15(6), 2009.
// DOI: 10.1109/TVCG.2009.113
// Notes:
// - Texture/material-only sharpening is intentionally not added: a ReShade
//   post-process sees the composited backbuffer, not material texture inputs.
// - AO history is depth-rejected at the same screen coordinate. Without motion
//   vectors this is not true reprojection and may ghost during camera motion.
// - History textures are unpooled so their contents are not aliased with other
//   effects' temporary render targets.
// - Bloom and luminance intermediate buffers use 32-bit float formats.
// - HUD protection is an automatic temporal/screen-space heuristic; it requires
//   no manually configured rectangles, but cannot be perfect for every game frame.
// - USS X is an experimental image-space edge/coverage reconstruction that runs
//   before the other post-process modules. It is not hardware MSAA or true
//   geometry/sample coverage; temporal matching has no motion vectors.
// - SSR is an approximate view-space reconstruction using adjustable FOV and
//   depth scale. It cannot access material roughness, normals or off-screen geometry.
// - Color vision modes are simulations / daltonization-style remapping, not a
//   medical diagnostic or guaranteed accessibility correction.
// ============================================================================

// ------------------------------ UI ------------------------------------------

uniform bool EnableLocalContrast <
    ui_label = "Enable Local Contrast";
    ui_category = "Local Contrast";
> = true;

uniform float LC_Strength <
    ui_type = "slider";
    ui_label = "Local Contrast Strength";
    ui_min = 0.0; ui_max = 2.5; ui_step = 0.01;
> = 1.00;

uniform float LC_KernelShape <
    ui_type = "slider";
    ui_label = "Local Contrast Scale";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
> = 1.00;

uniform float LC_HighlightShadow <
    ui_type = "slider";
    ui_label = "Highlight / Shadow Detail";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 1.00;

uniform float HDRContrast <
    ui_type = "slider";
    ui_label = "HDR Contrast";
    ui_min = 0.50; ui_max = 2.00; ui_step = 0.01;
> = 1.00;

uniform bool EnableDetailReconstruction <
    ui_label = "Enable Detail Reconstruction";
    ui_category = "Detail Reconstruction";
> = true;

uniform float DetailAmount <
    ui_type = "slider";
    ui_label = "Detail Reconstruction Strength";
    ui_min = 0.0; ui_max = 5.0; ui_step = 0.05;
> = 1.00;

uniform float DetailRadius <
    ui_type = "slider";
    ui_label = "Detail Radius";
    ui_min = 0.5; ui_max = 5.5; ui_step = 0.1;
> = 1.00;

uniform float NoiseThreshold <
    ui_type = "slider";
    ui_label = "Noise Suppression";
    ui_min = 0.0; ui_max = 0.05; ui_step = 0.001;
> = 0.014;

uniform float EdgeProtection <
    ui_type = "slider";
    ui_label = "Edge Protection";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
> = 0.200;

uniform float DetailLimit <
    ui_type = "slider";
    ui_label = "Detail Overshoot Limit";
    ui_min = 0.01; ui_max = 1.50; ui_step = 0.005;
> = 0.45;

uniform float HDRBloomThreshold <
    ui_type = "slider";
    ui_label = "HDR Bloom Threshold";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.90;

uniform float HDRBloomIntensity <
    ui_type = "slider";
    ui_label = "HDR Bloom Intensity";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
> = 1.00;

uniform float MagicBloomIntensity <
    ui_type = "slider";
    ui_label = "Magic Bloom Intensity";
    ui_min = 0.0; ui_max = 5.0; ui_step = 0.01;
> = 2.00;

uniform float MagicBloomCurve <
    ui_type = "slider";
    ui_label = "Magic Bloom Curve";
    ui_min = 0.5; ui_max = 5.0; ui_step = 0.05;
> = 1.00;

uniform float BloomSpread <
    ui_type = "slider";
    ui_label = "Bloom Spread";
    ui_min = 0.5; ui_max = 3.0; ui_step = 0.05;
> = 1.00;

uniform bool AutoExposure <
    ui_label = "Auto Exposure";
> = false;

uniform float ExposureCompensation <
    ui_type = "slider";
    ui_label = "Exposure Compensation";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.01;
> = 0.10;

uniform float AdaptationSpeed <
    ui_type = "slider";
    ui_label = "Exposure Adaptation Speed";
    ui_min = 0.001; ui_max = 1.0; ui_step = 0.001;
> = 0.10;

uniform int ToneMapper <
    ui_type = "combo";
    ui_label = "Tone Mapper";
    ui_items = "Normal\0Reinhard\0ACES Fitted\0";
> = 0;

uniform float GammaValue <
    ui_type = "slider";
    ui_label = "Working Gamma";
    ui_min = 1.0; ui_max = 2.6; ui_step = 0.01;
> = 2.60;

uniform int DebugMode <
    ui_type = "combo";
    ui_label = "Debug View";
    ui_items = "Normal\0High Frequency\0Detail Mask\0Local Contrast\0Bloom\0Exposure\0Ambient Occlusion\0HUD Mask\0SSR Reflection\0Color Range Masks\0";
> = 0;

uniform bool EnableAO <
    ui_label = "Ambient Occlusion";
> = true;

uniform float AOIntensity <
    ui_type = "slider";
    ui_label = "AO Intensity";
    ui_min = 0.0; ui_max = 15.0; ui_step = 0.05;
> = 3.00;

uniform float AORadius <
    ui_type = "slider";
    ui_label = "AO Radius";
    ui_min = 0.5; ui_max = 1500.0; ui_step = 0.1;
> = 150.00;

uniform float AOTemporalWeight <
    ui_type = "slider";
    ui_label = "AO Temporal Stability";
    ui_min = 0.0; ui_max = 2.00; ui_step = 0.01;
> = 0.95;

uniform bool EnableAOTemporal <
    ui_label = "Enable AO Temporal History";
    ui_category = "Ambient Occlusion";
> = true;

// New final-image controls. Neutral values leave the image unchanged.
uniform float SaturationStrength <
    ui_type = "slider";
    ui_label = "Color Saturation";
    ui_min = 0.0; ui_max = 3.0; ui_step = 0.01;
> = 1.25;

uniform bool EnableVignette <
    ui_label = "Enable Vignette";
    ui_category = "Vignette";
> = true;

uniform float VignetteStrength <
    ui_type = "slider";
    ui_label = "Vignette Strength";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.20;

uniform float VignetteRadius <
    ui_type = "slider";
    ui_label = "Vignette Radius";
    ui_min = 0.10; ui_max = 1.20; ui_step = 0.01;
> = 0.68;

uniform float VignetteSoftness <
    ui_type = "slider";
    ui_label = "Vignette Feather";
    ui_min = 0.01; ui_max = 1.00; ui_step = 0.01;
> = 0.35;

uniform bool EnableFilmGrain <
    ui_label = "Enable Film Grain";
> = true;

uniform float FilmGrainAmount <
    ui_type = "slider";
    ui_label = "Film Grain Amount";
    ui_min = 0.0; ui_max = 0.90; ui_step = 0.001;
> = 0.025;

uniform float FilmGrainSize <
    ui_type = "slider";
    ui_label = "Film Grain Size";
    ui_min = 0.5; ui_max = 3.0; ui_step = 0.05;
> = 1.00;


// --------------------------- Color engine ----------------------------------
// Neutral defaults: brightness=0, contrast=1, hue=0, white level=1.
uniform bool EnableColorEngine <
    ui_label = "Enable Color Engine";
    ui_category = "Color Engine";
> = true;

uniform float ColorBrightness <
    ui_type = "slider";
    ui_label = "Brightness";
    ui_min = -0.50; ui_max = 1.50; ui_step = 0.005;
    ui_category = "Color Engine";
> = 0.00;

uniform float ColorContrast <
    ui_type = "slider";
    ui_label = "Contrast";
    ui_min = 0.50; ui_max = 3.00; ui_step = 0.01;
    ui_category = "Color Engine";
> = 1.00;

uniform float GlobalHueShift <
    ui_type = "slider";
    ui_label = "Global Hue Shift";
    ui_min = -180.0; ui_max = 180.0; ui_step = 0.5;
    ui_category = "Color Engine";
> = 0.0;

uniform float WhiteLevel <
    ui_type = "slider";
    ui_label = "White / Highlight Level";
    ui_min = 0.50; ui_max = 2.00; ui_step = 0.01;
    ui_category = "Color Engine";
> = 1.00;

uniform bool EnableSelectiveColor <
    ui_label = "Enable Selective Color";
    ui_category = "Selective Color";
> = true;

// Per-range values are hue offset (degrees), saturation multiplier and value multiplier.
// 0 / 1 / 1 are neutral for every range.
uniform float RedHue < ui_type = "slider";ui_label = "Red Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Red"; > = 0.0;
uniform float RedSaturation < ui_type = "slider";ui_label = "Red Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Red"; > = 1.0;
uniform float RedValue < ui_type = "slider";ui_label = "Red Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Red"; > = 1.0;
uniform float OrangeHue < ui_type = "slider";ui_label = "Orange Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Orange"; > = 0.0;
uniform float OrangeSaturation < ui_type = "slider";ui_label = "Orange Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Orange"; > = 1.0;
uniform float OrangeValue < ui_type = "slider";ui_label = "Orange Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Orange"; > = 1.0;
uniform float YellowHue < ui_type = "slider";ui_label = "Yellow Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Yellow"; > = 0.0;
uniform float YellowSaturation < ui_type = "slider";ui_label = "Yellow Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Yellow"; > = 1.0;
uniform float YellowValue < ui_type = "slider";ui_label = "Yellow Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Yellow"; > = 1.0;
uniform float GreenHue < ui_type = "slider";ui_label = "Green Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Green"; > = 0.0;
uniform float GreenSaturation < ui_type = "slider";ui_label = "Green Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Green"; > = 1.0;
uniform float GreenValue < ui_type = "slider";ui_label = "Green Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Green"; > = 1.0;
uniform float CyanHue < ui_type = "slider";ui_label = "Cyan Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Cyan"; > = 0.0;
uniform float CyanSaturation < ui_type = "slider";ui_label = "Cyan Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Cyan"; > = 1.0;
uniform float CyanValue < ui_type = "slider";ui_label = "Cyan Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Cyan"; > = 1.0;
uniform float BlueHue < ui_type = "slider";ui_label = "Blue Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Blue"; > = 0.0;
uniform float BlueSaturation < ui_type = "slider";ui_label = "Blue Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Blue"; > = 1.0;
uniform float BlueValue < ui_type = "slider";ui_label = "Blue Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Blue"; > = 1.0;
uniform float PurpleHue < ui_type = "slider";ui_label = "Purple Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Purple"; > = 0.0;
uniform float PurpleSaturation < ui_type = "slider";ui_label = "Purple Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Purple"; > = 1.0;
uniform float PurpleValue < ui_type = "slider";ui_label = "Purple Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Purple"; > = 1.0;
uniform float MagentaHue < ui_type = "slider";ui_label = "Magenta Hue"; ui_min = -45.0; ui_max = 45.0; ui_step = 0.1; ui_category = "Selective Color - Magenta"; > = 0.0;
uniform float MagentaSaturation < ui_type = "slider";ui_label = "Magenta Saturation"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Magenta"; > = 1.0;
uniform float MagentaValue < ui_type = "slider";ui_label = "Magenta Brightness"; ui_min = 0.0; ui_max = 2.0; ui_step = 0.01; ui_category = "Selective Color - Magenta"; > = 1.0;

// Color-vision simulation and daltonization-style assistance are separate modes.
uniform bool EnableColorVision <
    ui_label = "Enable Color Vision Mode";
    ui_category = "Color Vision";
> = false;

uniform int ColorVisionMode <
    ui_type = "combo";
    ui_label = "Color Vision Mode";
    ui_items = "Off\0Protanopia Simulation\0Deuteranopia Simulation\0Tritanopia Simulation\0Protanopia Assist\0Deuteranopia Assist\0Tritanopia Assist\0";
    ui_category = "Color Vision";
> = 0;

uniform float ColorVisionStrength <
    ui_type = "slider";
    ui_label = "Color Vision Strength";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Color Vision";
> = 1.0;

// Eye-comfort processing is independent and disabled by default.
uniform bool EnableEyeProtection <
    ui_label = "Enable Eye Protection";
    ui_category = "Eye Protection";
> = false;

uniform float EyeBlueReduction <
    ui_type = "slider";
    ui_label = "Blue Light Reduction";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Eye Protection";
> = 0.30;

uniform float EyeWarmth <
    ui_type = "slider";
    ui_label = "Warmth";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Eye Protection";
> = 0.35;

uniform float EyeHighlightLimit <
    ui_type = "slider";
    ui_label = "Highlight Comfort Limit";
    ui_min = 0.50; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Eye Protection";
> = 0.90;

// Screen-space reflections are experimental and disabled by default.
uniform bool EnableSSR <
    ui_label = "Enable Screen-Space Reflections";
    ui_category = "Screen-Space Reflections";
> = false;

uniform float SSRIntensity <
    ui_type = "slider";
    ui_label = "Reflection Intensity";
    ui_min = 0.0; ui_max = 8.0; ui_step = 0.01;
    ui_category = "Screen-Space Reflections";
> = 0.65;

uniform int SSRQuality <
    ui_type = "combo";
    ui_label = "Ray March Quality";
    ui_items = "Low - 12\0Medium - 24\0High - 40\0";
    ui_category = "Screen-Space Reflections";
> = 1;

uniform float SSRMaxDistance <
    ui_type = "slider";
    ui_label = "Maximum Ray Distance";
    ui_min = 5.0; ui_max = 150.0; ui_step = 1.0;
    ui_category = "Screen-Space Reflections";
> = 55.0;

uniform float SSRThickness <
    ui_type = "slider";
    ui_label = "Ray Thickness";
    ui_min = 0.05; ui_max = 5.0; ui_step = 0.05;
    ui_category = "Screen-Space Reflections";
> = 0.45;

uniform float SSRFieldOfView <
    ui_type = "slider";
    ui_label = "Approximate Vertical FOV";
    ui_min = 40.0; ui_max = 120.0; ui_step = 0.5;
    ui_category = "Screen-Space Reflections";
> = 70.0;

uniform float SSRDepthScale <
    ui_type = "slider";
    ui_label = "Depth Scale / Far Plane";
    ui_min = 100.0; ui_max = 5000.0; ui_step = 10.0;
    ui_category = "Screen-Space Reflections";
> = 1000.0;

uniform float SSRSurfaceSmoothness <
    ui_type = "slider";
    ui_label = "Surface Smoothness Bias";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "Screen-Space Reflections";
> = 0.70;

uniform float SSRWetSurfaceBoost <
    ui_type = "slider";
    ui_label = "Wet Surface Boost";
    ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
    ui_category = "Screen-Space Reflections";
> = 0.65;

uniform float SSREdgeFade <
    ui_type = "slider";
    ui_label = "Screen Edge Fade";
    ui_min = 0.0; ui_max = 0.5; ui_step = 0.01;
    ui_category = "Screen-Space Reflections";
> = 0.15;

// Compact bloom radius is independent of the original BloomSpread control.
uniform bool EnableBloom <
    ui_label = "Enable Bloom";
    ui_category = "Bloom";
> = true;

uniform float BloomRadius <
    ui_type = "slider";
    ui_label = "Bloom Radius";
    ui_min = 0.01; ui_max = 3.00; ui_step = 0.01;
    ui_category = "Bloom";
> = 0.35;

uniform bool EnableUSSX <
    ui_label = "Enable USS X Subpixel Reconstruction";
    ui_category = "USS X - Subpixel Reconstruction";
    ui_category_toggle = true;
> = true;

uniform bool EnableUSSXTemporal <
    ui_label = "Enable USS X Temporal T-2";
    ui_category = "USS X - Subpixel Reconstruction";
> = true;

uniform float USSX_ReconstructionStrength <
    ui_type = "slider";
    ui_label = "Reconstruction Strength";
    ui_min = 0.0; ui_max = 55.0; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 1.0;

uniform float USSX_SubpixelCoverageStrength <
    ui_type = "slider";
    ui_label = "Subpixel Coverage Strength";
    ui_min = 0.0; ui_max = 22.0; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 1.0;

uniform float USSX_RGBReconstruction <
    ui_type = "slider";
    ui_label = "RGB Reconstruction";
    ui_min = 0.0; ui_max = 12.0; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 1.0;

uniform float USSX_ChromaPreservation <
    ui_type = "slider";
    ui_label = "Chroma Preservation";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 1.0;

uniform float USSX_EdgeSensitivity <
    ui_type = "slider";
    ui_label = "Edge Sensitivity";
    ui_min = 0.0; ui_max = 5.0; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 1.0;

uniform float USSX_DirectionalContinuity <
    ui_type = "slider";
    ui_label = "Directional Continuity";
    ui_min = 0.0; ui_max = 5.0; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 0.85;

uniform float USSX_TemporalStability <
    ui_type = "slider";
    ui_label = "Temporal Stability";
    ui_min = 0.0; ui_max = 3.5; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 0.20;

uniform float USSX_TemporalColorThreshold <
    ui_type = "slider";
    ui_label = "Temporal Color Threshold";
    ui_min = 0.01; ui_max = 9.25; ui_step = 0.005;
    ui_category = "USS X - Subpixel Reconstruction";
> = 0.08;

uniform float USSX_HistorySearchRadius <
    ui_type = "slider";
    ui_label = "History Search Radius";
    ui_min = 1.0; ui_max = 15.0; ui_step = 0.5;
    ui_category = "USS X - Subpixel Reconstruction";
> = 15.0;

uniform float USSX_AntiRinging <
    ui_type = "slider";
    ui_label = "Anti-Ringing";
    ui_min = 0.0; ui_max = 9.0; ui_step = 0.01;
    ui_category = "USS X - Subpixel Reconstruction";
> = 0.75;

uniform int USSX_DebugView <
    ui_type = "combo";
    ui_label = "USS X Debug View";
    ui_items = "Normal\0Edge Confidence\0Direction Analysis\0Subpixel Coverage\0RGB Reconstruction\0Temporal Confidence\0";
    ui_category = "USS X - Subpixel Reconstruction";
> = 0;

// Automatic HUD protection. No manual rectangles or per-game coordinate setup.
// This is a conservative screen-space heuristic, not access to the game's UI layer.
uniform bool EnableHUDProtection <
    ui_label = "Automatic HUD Protection";
    ui_category = "HUD Protection";
> = true;

uniform float HUDDetectionStrength <
    ui_type = "slider";
    ui_label = "HUD Detection Strength";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "HUD Protection";
> = 0.80;

uniform float HUDTemporalThreshold <
    ui_type = "slider";
    ui_label = "HUD Motion Threshold";
    ui_min = 0.001; ui_max = 0.10; ui_step = 0.001;
    ui_category = "HUD Protection";
> = 0.025;

uniform float HUDEdgeSensitivity <
    ui_type = "slider";
    ui_label = "HUD Fine-Edge Sensitivity";
    ui_min = 0.25; ui_max = 3.0; ui_step = 0.01;
    ui_category = "HUD Protection";
> = 1.00;

uniform float HUDScreenEdgeBias <
    ui_type = "slider";
    ui_label = "HUD Screen-Edge Bias";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "HUD Protection";
> = 0.85;

uniform float HUDCenterBias <
    ui_type = "slider";
    ui_label = "HUD Center Reticle Bias";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_category = "HUD Protection";
> = 0.95;

// Runtime-provided values used for frame-rate independent exposure and grain.
uniform float FrameTime < source = "frametime"; >;
uniform int FrameCount < source = "framecount"; >;

// --------------------------- Shared textures -------------------------------
// Full float luminance pyramid for local contrast.
texture2D USS110_Luma2
{
    Width = BUFFER_WIDTH / 2;
    Height = BUFFER_HEIGHT / 2;
    Format = RG32F;
};
texture2D USS110_Luma4
{
    Width = BUFFER_WIDTH / 4;
    Height = BUFFER_HEIGHT / 4;
    Format = RG32F;
};
texture2D USS110_Luma8
{
    Width = BUFFER_WIDTH / 8;
    Height = BUFFER_HEIGHT / 8;
    Format = RG32F;
};

sampler2D USS110_Luma2S
{
    Texture = USS110_Luma2;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D USS110_Luma4S
{
    Texture = USS110_Luma4;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D USS110_Luma8S
{
    Texture = USS110_Luma8;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

// Full-resolution HUD mask is built once, then reused by all image stages.
// R16F is sufficient for a feathered 0..1 coverage mask and saves bandwidth.
texture2D USS110_HUDMaskTexture
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = R16F;
};
sampler2D USS110_HUDMaskS
{
    Texture = USS110_HUDMaskTexture;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

// Previous original backbuffer frame, used to find screen-locked UI pixels.
// Pooled=false prevents another effect from aliasing temporal contents.
texture2D USS110_HUDColorHistory < pooled = false; >
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};
sampler2D USS110_HUDColorHistoryS
{
    Texture = USS110_HUDColorHistory;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

// Shared high-precision colour bloom pyramid.
texture2D USS110_Bloom2
{
    Width = BUFFER_WIDTH / 2;
    Height = BUFFER_HEIGHT / 2;
    Format = RGBA32F;
};
texture2D USS110_Bloom4
{
    Width = BUFFER_WIDTH / 4;
    Height = BUFFER_HEIGHT / 4;
    Format = RGBA32F;
};
texture2D USS110_Bloom8
{
    Width = BUFFER_WIDTH / 8;
    Height = BUFFER_HEIGHT / 8;
    Format = RGBA32F;
};
texture2D USS110_Bloom16
{
    Width = BUFFER_WIDTH / 16;
    Height = BUFFER_HEIGHT / 16;
    Format = RGBA32F;
};
texture2D USS110_Bloom32
{
    Width = BUFFER_WIDTH / 32;
    Height = BUFFER_HEIGHT / 32;
    Format = RGBA32F;
};

sampler2D USS110_Bloom2S
{
    Texture = USS110_Bloom2;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D USS110_Bloom4S
{
    Texture = USS110_Bloom4;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D USS110_Bloom8S
{
    Texture = USS110_Bloom8;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D USS110_Bloom16S
{
    Texture = USS110_Bloom16;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D USS110_Bloom32S
{
    Texture = USS110_Bloom32;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

// AO working buffers. Float32 reduces precision loss in depth comparisons.
texture2D USS110_AOCurrent
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = R32F;
};
texture2D USS110_AOResolved
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = R32F;
};

// Persistent history must not be pooled/reused by unrelated render targets.
texture2D USS110_AOHistory < pooled = false; >
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = R32F;
};
texture2D USS110_DepthHistory < pooled = false; >
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = R32F;
};

sampler2D USS110_AOCurrentS
{
    Texture = USS110_AOCurrent;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
};
sampler2D USS110_AOResolvedS
{
    Texture = USS110_AOResolved;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
sampler2D USS110_AOHistoryS
{
    Texture = USS110_AOHistory;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
};
sampler2D USS110_DepthHistoryS
{
    Texture = USS110_DepthHistory;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
};

// 256x256 luminance image; the exposure pass explicitly regenerates mipmaps.
texture2D USS110_ExposureLuma
{
    Width = 256;
    Height = 256;
    Format = RG32F;
    MipLevels = 9;
};
sampler2D USS110_ExposureLumaS
{
    Texture = USS110_ExposureLuma;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

texture2D USS110_ExposureCurrent
{
    Width = 1;
    Height = 1;
    Format = R32F;
};
texture2D USS110_ExposureHistory < pooled = false; >
{
    Width = 1;
    Height = 1;
    Format = R32F;
};
sampler2D USS110_ExposureCurrentS
{
    Texture = USS110_ExposureCurrent;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
};
sampler2D USS110_ExposureHistoryS
{
    Texture = USS110_ExposureHistory;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
};

// Source copy and USS X buffers. RGBA16F is more precise than the usual
// 8-bit display target while keeping 4K history memory use manageable.
texture2D USS110_XSource
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};
texture2D USS110_XCurrent
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};
texture2D USS110_XTemporal
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};


// T-1/T-2 histories persist between frames and must not be pooled.
// History alpha is stored as coverage + 2.0, reserving values below 1.5 as invalid.
texture2D USS110_XHistory1 < pooled = false; >
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};
texture2D USS110_XHistory2 < pooled = false; >
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D USS110_XSourcePointS
{
    Texture = USS110_XSource;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};
sampler2D USS110_XSourceLinearS
{
    Texture = USS110_XSource;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
};
sampler2D USS110_XCurrentS
{
    Texture = USS110_XCurrent;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};
sampler2D USS110_XTemporalS
{
    Texture = USS110_XTemporal;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};
sampler2D USS110_XHistory1S
{
    Texture = USS110_XHistory1;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};
sampler2D USS110_XHistory2S
{
    Texture = USS110_XHistory2;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};


// Half-resolution reflection buffer: depth is still sampled at native resolution.
// RGBA16F stores linear reflection RGB and a confidence/validity weight.
texture2D USS110_SSRReflection
{
    Width = BUFFER_WIDTH / 2;
    Height = BUFFER_HEIGHT / 2;
    Format = RGBA16F;
};
sampler2D USS110_SSRReflectionS
{
    Texture = USS110_SSRReflection;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
};

// --------------------------- HUD preservation ------------------------------

float USS_HUDLuma(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float USS_HUDMaskShape(float2 uv)
{
    // Single initialized return path avoids compiler warnings about the
    // generated function return value on early-exit branches.
    float result = 0.0;

    if (EnableHUDProtection && HUDDetectionStrength > 0.001 && FrameCount >= 2)
    {
        float4 history = tex2D(USS110_HUDColorHistoryS, saturate(uv));
        // Alpha=1 is a validity marker written by the history-store pass.
        if (abs(history.a - 1.0) <= 0.01)
        {
            float3 currentColor = tex2D(ReShade::BackBuffer, saturate(uv)).rgb;

            // Screen-locked HUD pixels tend to remain stable at the same coordinates
            // while the 3D scene changes. Combine temporal stability with compact
            // high-frequency structure and a weak screen-space prior.
            float temporalDifference = dot(abs(currentColor - history.rgb),
                                           float3(0.299, 0.587, 0.114));
            float motionLimit = max(HUDTemporalThreshold, 0.0005);
            float temporalStability = 1.0 - smoothstep(motionLimit,
                                                       motionLimit * 3.0,
                                                       temporalDifference);

            float2 px = ReShade::PixelSize;
            float centerLuma = USS_HUDLuma(currentColor);
            float l1 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(px.x, 0))).rgb);
            float l2 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(-px.x, 0))).rgb);
            float l3 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(0, px.y))).rgb);
            float l4 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(0, -px.y))).rgb);
            float l5 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(2.0 * px.x, 0))).rgb);
            float l6 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(-2.0 * px.x, 0))).rgb);
            float l7 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(0, 2.0 * px.y))).rgb);
            float l8 = USS_HUDLuma(tex2D(ReShade::BackBuffer, saturate(uv + float2(0, -2.0 * px.y))).rgb);

            float localMin = min(centerLuma, min(min(min(l1, l2), min(l3, l4)), min(min(l5, l6), min(l7, l8))));
            float localMax = max(centerLuma, max(max(max(l1, l2), max(l3, l4)), max(max(l5, l6), max(l7, l8))));
            float localRange = localMax - localMin;
            float gradientX = max(abs(l1 - l2), abs(l5 - l6) * 0.5);
            float gradientY = max(abs(l3 - l4), abs(l7 - l8) * 0.5);
            float edgeEnergy = max(gradientX, gradientY) * HUDEdgeSensitivity;
            float fineEdge = smoothstep(0.012, 0.095, max(localRange, edgeEnergy));
            // Avoid treating broad, high-contrast scene regions as small UI glyphs.
            float compactness = 1.0 - smoothstep(0.45, 0.90, localRange);
            float structureConfidence = fineEdge * compactness;

            // HUD elements are usually near the screen boundary; the small center
            // prior protects reticles without requiring manual screen coordinates.
            float borderDistance = min(min(uv.x, 1.0 - uv.x) * ReShade::AspectRatio,
                                       min(uv.y, 1.0 - uv.y));
            float edgePrior = 1.0 - smoothstep(0.015, 0.30, borderDistance);
            float centerDistance = length((uv - 0.5) * float2(ReShade::AspectRatio, 1.0));
            float centerPrior = 1.0 - smoothstep(0.002, 0.045, centerDistance);
            float screenPrior = max(edgePrior * HUDScreenEdgeBias,
                                    centerPrior * HUDCenterBias);

            float score = temporalStability * structureConfidence * screenPrior;
            float threshold = lerp(0.82, 0.24, saturate(HUDDetectionStrength));
            result = smoothstep(threshold, min(threshold + 0.22, 1.0), score);
        }
    }

    return result;
}

float USS_HUDMask(float2 uv)
{
    return tex2Dlod(USS110_HUDMaskS, float4(saturate(uv), 0.0, 0.0)).r;
}

float4 PS_USS_HUDMask(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return float4(USS_HUDMaskShape(uv), 0, 0, 1);
}

float4 PS_USS_HUDHistoryStore(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    // Always store the unprocessed game frame; alpha=1 marks this history as valid.
    return float4(tex2D(ReShade::BackBuffer, uv).rgb, 1.0);
}

// ------------------------------ Utilities ----------------------------------

float3 USS_ToLinear(float3 c)
{
    return pow(abs(c), GammaValue);
}

float3 USS_SceneColorLinear(float2 uv)
{
    float2 q = saturate(uv);
    float3 scene = USS_ToLinear(tex2D(USS110_XTemporalS, q).rgb);
    if (EnableSSR)
    {
        float4 reflection = tex2D(USS110_SSRReflectionS, q);
        float weight = saturate(reflection.a * SSRIntensity);
        scene = lerp(scene, reflection.rgb, weight);
    }
    return scene;
}

float3 USS_SceneSample(float2 uv, float3 centerColor)
{
    float2 sampleUV = saturate(uv);
    float3 sampled = USS_SceneColorLinear(sampleUV);
    return lerp(sampled, centerColor, USS_HUDMask(sampleUV));
}

float3 USS_ToDisplay(float3 c)
{
    return pow(saturate(c), rcp(GammaValue));
}

float USS_Luma(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float3 USS_ACESFit(float3 x)
{
    float3 a = x * (x + 0.0245786) - 0.000090537;
    float3 b = x * (0.983729 * x + 0.4329510) + 0.238081;
    return saturate(a / max(b, 0.00001));
}

float3 USS_ToneMap(float3 c)
{
    if (ToneMapper == 1)
        return c / (1.0 + c);
    if (ToneMapper == 2)
        return USS_ACESFit(c);
    return c;
}

float USS_Hash12(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

float2 USS_LumaDown4(sampler2D src, float2 uv, float2 srcPixel)
{
    float2 d = srcPixel * 0.5;
    float2 a = tex2D(src, uv + float2(-d.x, -d.y)).rg;
    float2 b = tex2D(src, uv + float2(d.x, -d.y)).rg;
    float2 c = tex2D(src, uv + float2(-d.x, d.y)).rg;
    float2 e = tex2D(src, uv + float2(d.x, d.y)).rg;

    // Each RG value stores (mean-luma numerator, unmasked coverage).
    // Averaging both channels independently preserves the weighted ratio
    // through every pyramid level without multiplying interpolated averages.
    return 0.25 * (a + b + c + e);
}

// Normalized 17-tap bloom filter. All tap weights sum to 1.0.
float3 USS_BlurDown17(sampler2D src, float2 uv, float2 srcPixel)
{
    float2 d = srcPixel * BloomSpread * BloomRadius;
    float3 c = tex2D(src, uv).rgb * 0.20;
    c += (tex2D(src, uv + float2(d.x, 0)).rgb + tex2D(src, uv + float2(-d.x, 0)).rgb
        + tex2D(src, uv + float2(0, d.y)).rgb + tex2D(src, uv + float2(0, -d.y)).rgb) * 0.10;
    c += (tex2D(src, uv + float2(d.x, d.y)).rgb + tex2D(src, uv + float2(-d.x, d.y)).rgb
        + tex2D(src, uv + float2(d.x, -d.y)).rgb + tex2D(src, uv + float2(-d.x, -d.y)).rgb) * 0.05;
    float2 q = d * 2.0;
    c += (tex2D(src, uv + float2(q.x, 0)).rgb + tex2D(src, uv + float2(-q.x, 0)).rgb
        + tex2D(src, uv + float2(0, q.y)).rgb + tex2D(src, uv + float2(0, -q.y)).rgb) * 0.025;
    c += (tex2D(src, uv + float2(q.x, q.y)).rgb + tex2D(src, uv + float2(-q.x, q.y)).rgb
        + tex2D(src, uv + float2(q.x, -q.y)).rgb + tex2D(src, uv + float2(-q.x, -q.y)).rgb) * 0.025;
    return c;
}

// Soft-knee HDR extraction plus the Magic Bloom low-level glow contribution.
float3 USS_BrightExtract(float3 c)
{
    float lum = max(USS_Luma(c), 0.0);
    float knee = max(HDRBloomThreshold * 0.5, 0.0001);
    float soft = saturate((lum - HDRBloomThreshold + knee) / (2.0 * knee));
    float softContribution = soft * soft * knee;
    float hardContribution = max(lum - HDRBloomThreshold, 0.0);
    float hdrContribution = max(hardContribution, softContribution);
    float hdrMask = hdrContribution / max(lum, 0.0001);
    float magicMask = pow(saturate(lum), MagicBloomCurve) * 0.15;
    return c * saturate(hdrMask + magicMask);
}

// Four-tap downsample with Karis-style luminance weights to reduce isolated
// bright-pixel/firefly dominance before the wide bloom pyramid is built.
float3 USS_BloomExtractDownsample(float2 uv, float2 d)
{
    float2 uv0 = saturate(uv + float2(-d.x, -d.y));
    float2 uv1 = saturate(uv + float2(d.x, -d.y));
    float2 uv2 = saturate(uv + float2(-d.x, d.y));
    float2 uv3 = saturate(uv + float2(d.x, d.y));

    float3 c0 = USS_BrightExtract(USS_SceneColorLinear(uv0));
    float3 c1 = USS_BrightExtract(USS_SceneColorLinear(uv1));
    float3 c2 = USS_BrightExtract(USS_SceneColorLinear(uv2));
    float3 c3 = USS_BrightExtract(USS_SceneColorLinear(uv3));

    float coverage0 = 1.0 - USS_HUDMask(uv0);
    float coverage1 = 1.0 - USS_HUDMask(uv1);
    float coverage2 = 1.0 - USS_HUDMask(uv2);
    float coverage3 = 1.0 - USS_HUDMask(uv3);

    float w0 = rcp(1.0 + max(USS_Luma(c0), 0.0)) * coverage0;
    float w1 = rcp(1.0 + max(USS_Luma(c1), 0.0)) * coverage1;
    float w2 = rcp(1.0 + max(USS_Luma(c2), 0.0)) * coverage2;
    float w3 = rcp(1.0 + max(USS_Luma(c3), 0.0)) * coverage3;
    float weightSum = w0 + w1 + w2 + w3;
    return (c0 * w0 + c1 * w1 + c2 * w2 + c3 * w3) / max(weightSum, 0.00001);
}

// ----------------------- Screen-space reflections --------------------------
// Reconstructs an approximate view-space position from ReShade's linearized
// depth. This uses a user-adjustable FOV/depth scale because ReShade does not
// expose a universal game projection matrix to ordinary post-process effects.
float3 USS_SSRViewPosition(float2 uv, float linearDepth)
{
    float z = max(linearDepth * SSRDepthScale, 0.1);
    float tanHalfFov = tan(SSRFieldOfView * 0.00872664626);
    float2 ndc = float2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);
    return float3(ndc.x * z * tanHalfFov * ReShade::AspectRatio,
                  ndc.y * z * tanHalfFov,
                  z);
}

float4 PS_USS_SSRTrace(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableSSR || SSRIntensity <= 0.001 || USS_HUDMask(uv) > 0.001)
        return float4(0.0, 0.0, 0.0, 0.0);

    float depth = ReShade::GetLinearizedDepth(uv);
    if (depth <= 0.00001 || depth >= 0.9999)
        return float4(0.0, 0.0, 0.0, 0.0);

    float2 px = ReShade::PixelSize;
    float2 uvL = saturate(uv - float2(px.x, 0.0));
    float2 uvR = saturate(uv + float2(px.x, 0.0));
    float2 uvU = saturate(uv - float2(0.0, px.y));
    float2 uvD = saturate(uv + float2(0.0, px.y));

    float depthL = ReShade::GetLinearizedDepth(uvL);
    float depthR = ReShade::GetLinearizedDepth(uvR);
    float depthU = ReShade::GetLinearizedDepth(uvU);
    float depthD = ReShade::GetLinearizedDepth(uvD);

    float3 P = USS_SSRViewPosition(uv, depth);
    float3 PL = USS_SSRViewPosition(uvL, depthL);
    float3 PR = USS_SSRViewPosition(uvR, depthR);
    float3 PU = USS_SSRViewPosition(uvU, depthU);
    float3 PD = USS_SSRViewPosition(uvD, depthD);

    float3 normal = cross(PR - PL, PD - PU);
    float normalLength = length(normal);
    if (normalLength < 0.00001)
        return float4(0.0, 0.0, 0.0, 0.0);
    normal /= normalLength;

    float3 viewDirection = normalize(-P);
    if (dot(normal, viewDirection) < 0.0)
        normal = -normal;

    float3 incident = normalize(P);
    float3 reflectedDirection = normalize(reflect(incident, normal));
    if (dot(reflectedDirection, reflectedDirection) < 0.5)
        return float4(0.0, 0.0, 0.0, 0.0);

    // Estimate geometric smoothness from local second-order depth variation.
    // This is only a screen-space proxy; it is not a material roughness map.
    float zL = depthL * SSRDepthScale;
    float zR = depthR * SSRDepthScale;
    float zU = depthU * SSRDepthScale;
    float zD = depthD * SSRDepthScale;
    float curvature = (abs(zL + zR - 2.0 * P.z) + abs(zU + zD - 2.0 * P.z))
                    / max(P.z, 1.0);
    float geometricSmoothness = 1.0 - saturate(curvature * 8.0);
    float surfaceGate = lerp(0.25, 1.0, SSRSurfaceSmoothness) * geometricSmoothness;

    int raySteps = (SSRQuality == 0) ? 12 : ((SSRQuality == 1) ? 24 : 40);
    float hit = 0.0;
    float hitDistance = SSRMaxDistance;
    float2 hitUV = uv;
    float3 hitColor = 0.0;
    float stepLength = SSRMaxDistance / (float) raySteps;
    float startOffset = max(SSRThickness * 0.20, 0.08);
    float previousDelta = -1e20;
    float previousDistance = startOffset;
    float previousValid = 0.0;
    float tanHalfFov = tan(SSRFieldOfView * 0.00872664626);

    [loop]
    for (int stepIndex = 1; stepIndex <= 40; ++stepIndex)
    {
        if (stepIndex > raySteps)
            break;

        float distanceAlongRay = startOffset + stepLength * (float) stepIndex;
        float3 rayPosition = P + reflectedDirection * distanceAlongRay;
        if (rayPosition.z <= 0.1)
            break;

        float2 projectedNDC = float2(
            rayPosition.x / (rayPosition.z * tanHalfFov * ReShade::AspectRatio),
            rayPosition.y / (rayPosition.z * tanHalfFov));
        float2 rayUV = float2(projectedNDC.x * 0.5 + 0.5,
                              0.5 - projectedNDC.y * 0.5);

        if (rayUV.x <= 0.002 || rayUV.x >= 0.998 ||
            rayUV.y <= 0.002 || rayUV.y >= 0.998)
            break;

        float sceneDepth = ReShade::GetLinearizedDepth(rayUV);
        if (sceneDepth >= 0.9999)
        {
            previousValid = 0.0;
            continue;
        }

        float sceneZ = sceneDepth * SSRDepthScale;
        float depthDelta = rayPosition.z - sceneZ;
        float thickness = SSRThickness + sceneZ * 0.0015;

        // Refine only a front-to-back depth crossing, rather than accepting
        // any sample that happens to be close to a depth surface.
        if (previousValid > 0.5 && previousDelta < 0.0 && depthDelta >= 0.0 &&
            distanceAlongRay > startOffset + stepLength * 1.5)
        {
            float lo = previousDistance;
            float hi = distanceAlongRay;
            float2 refinedUV = rayUV;
            float refinedDelta = depthDelta;

            [loop]
            for (int refine = 0; refine < 4; ++refine)
            {
                float mid = 0.5 * (lo + hi);
                float3 midPosition = P + reflectedDirection * mid;
                if (midPosition.z <= 0.1)
                    break;

                float2 midNDC = float2(
                    midPosition.x / (midPosition.z * tanHalfFov * ReShade::AspectRatio),
                    midPosition.y / (midPosition.z * tanHalfFov));
                float2 midUV = float2(midNDC.x * 0.5 + 0.5,
                                      0.5 - midNDC.y * 0.5);
                if (midUV.x <= 0.002 || midUV.x >= 0.998 ||
                    midUV.y <= 0.002 || midUV.y >= 0.998)
                    break;

                float midSceneDepth = ReShade::GetLinearizedDepth(midUV);
                if (midSceneDepth >= 0.9999)
                {
                    lo = mid;
                    continue;
                }

                float midDelta = midPosition.z - midSceneDepth * SSRDepthScale;
                if (midDelta >= 0.0)
                {
                    hi = mid;
                    refinedUV = midUV;
                    refinedDelta = midDelta;
                }
                else
                {
                    lo = mid;
                }
            }

            float refinedDepth = ReShade::GetLinearizedDepth(refinedUV);
            float refinedSceneZ = refinedDepth * SSRDepthScale;
            float refinedThickness = SSRThickness + refinedSceneZ * 0.0015;
            bool validHit = refinedDepth < 0.9999 &&
                            refinedDelta <= refinedThickness * 1.5 &&
                            USS_HUDMask(refinedUV) < 0.01;
            if (validHit)
            {
                hit = 1.0;
                hitDistance = 0.5 * (lo + hi);
                hitUV = refinedUV;
                hitColor = USS_ToLinear(tex2Dlod(USS110_XTemporalS, float4(hitUV, 0.0, 0.0)).rgb);
                break;
            }
        }

        // Once the ray is substantially behind an occluder, stop marching.
        if (depthDelta > thickness * 3.0)
            break;

        previousDelta = depthDelta;
        previousDistance = distanceAlongRay;
        previousValid = 1.0;
    }

    if (hit < 0.5)
        return float4(0.0, 0.0, 0.0, 0.0);

    float facing = saturate(dot(normal, viewDirection));
    float fresnel = pow(1.0 - facing, 5.0);
    float distanceFade = 1.0 - saturate(hitDistance / max(SSRMaxDistance, 0.001));
    float edgeDistance = min(min(hitUV.x, 1.0 - hitUV.x),
                             min(hitUV.y, 1.0 - hitUV.y));
    float edgeFade = (SSREdgeFade > 0.001)
        ? smoothstep(0.0, SSREdgeFade, edgeDistance)
        : 1.0;
    float confidence = surfaceGate * (0.55 + 0.45 * fresnel) *
                       (0.35 + 0.65 * distanceFade) * edgeFade;
    confidence *= saturate(0.45 + SSRWetSurfaceBoost * 0.35);

    return float4(max(hitColor, 0.0), saturate(confidence));
}

// --------------------------- Luminance pyramid -----------------------------

float4 PS_USS_Luma2(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableLocalContrast)
        return float4(0.0, 1.0, 0.0, 1.0);
    float2 d = ReShade::PixelSize * 0.5;
    float2 uv0 = saturate(uv + float2(-d.x, -d.y));
    float2 uv1 = saturate(uv + float2(d.x, -d.y));
    float2 uv2 = saturate(uv + float2(-d.x, d.y));
    float2 uv3 = saturate(uv + float2(d.x, d.y));

    float3 a = USS_SceneColorLinear(uv0);
    float3 b = USS_SceneColorLinear(uv1);
    float3 c = USS_SceneColorLinear(uv2);
    float3 e = USS_SceneColorLinear(uv3);

    float m0 = 1.0 - USS_HUDMask(uv0);
    float m1 = 1.0 - USS_HUDMask(uv1);
    float m2 = 1.0 - USS_HUDMask(uv2);
    float m3 = 1.0 - USS_HUDMask(uv3);
    float coverageSum = m0 + m1 + m2 + m3;
    float weightedLuma = USS_Luma(a) * m0 + USS_Luma(b) * m1
                       + USS_Luma(c) * m2 + USS_Luma(e) * m3;
    return float4(weightedLuma * 0.25, coverageSum * 0.25, 0, 1);
}

float4 PS_USS_Luma4(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableLocalContrast)
        return float4(0.0, 1.0, 0.0, 1.0);
    return float4(USS_LumaDown4(USS110_Luma2S, uv, ReShade::PixelSize * 2.0), 0, 1);
}

float4 PS_USS_Luma8(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableLocalContrast)
        return float4(0.0, 1.0, 0.0, 1.0);
    return float4(USS_LumaDown4(USS110_Luma4S, uv, ReShade::PixelSize * 4.0), 0, 1);
}

// ----------------------------- Bloom pyramid -------------------------------

float4 PS_USS_Bloom2(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableBloom)
        return float4(0.0, 0.0, 0.0, 1.0);
    float2 d = ReShade::PixelSize * 0.5;
    return float4(USS_BloomExtractDownsample(uv, d), 1.0);
}

float4 PS_USS_Bloom4(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableBloom)
        return float4(0.0, 0.0, 0.0, 1.0);
    return float4(USS_BlurDown17(USS110_Bloom2S, uv, ReShade::PixelSize * 2.0), 1.0);
}

float4 PS_USS_Bloom8(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableBloom)
        return float4(0.0, 0.0, 0.0, 1.0);
    return float4(USS_BlurDown17(USS110_Bloom4S, uv, ReShade::PixelSize * 4.0), 1.0);
}

float4 PS_USS_Bloom16(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableBloom)
        return float4(0.0, 0.0, 0.0, 1.0);
    return float4(USS_BlurDown17(USS110_Bloom8S, uv, ReShade::PixelSize * 8.0), 1.0);
}

float4 PS_USS_Bloom32(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableBloom)
        return float4(0.0, 0.0, 0.0, 1.0);
    return float4(USS_BlurDown17(USS110_Bloom16S, uv, ReShade::PixelSize * 16.0), 1.0);
}

// --------------------------- Screen-space AO --------------------------------

float4 PS_USS_AO(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableAO || USS_HUDMask(uv) > 0.001)
        return float4(1.0, 0, 0, 1);

    float centerDepth = ReShade::GetLinearizedDepth(uv);
    if (centerDepth >= 0.9999)
        return float4(1.0, 0, 0, 1);

    // 32 angular directions x 3 radial distances = 96 depth samples.
    // A stable per-pixel angular rotation breaks visible radial banding.
    const float TAU = 6.28318530718;
    float2 pixel = pos.xy;
    float rotation = USS_Hash12(pixel) * (TAU / 32.0);
    float bias = max(0.00035, centerDepth * 0.00125);
    float occlusionSum = 0.0;
    float sampleWeightSum = 0.0;

    // Keep only one small dynamic loop. The three radial taps are written
    // explicitly instead of nesting an unrolled loop inside 32 directions.
    // This avoids the FXC X3511 expansion failure while retaining exactly
    // 32 x 3 = 96 depth samples per pixel.
    [loop]
    for (int i = 0; i < 32; ++i)
    {
        float angle = (i + 0.5) * (TAU / 32.0) + rotation;
        float2 dir = float2(cos(angle), sin(angle));

        float2 uv0 = saturate(uv + dir * ReShade::PixelSize * (AORadius * 0.35));
        float2 uv1 = saturate(uv + dir * ReShade::PixelSize * (AORadius * 0.68));
        float2 uv2 = saturate(uv + dir * ReShade::PixelSize * AORadius);

        float depth0 = ReShade::GetLinearizedDepth(uv0);
        float depth1 = ReShade::GetLinearizedDepth(uv1);
        float depth2 = ReShade::GetLinearizedDepth(uv2);

        float diff0 = centerDepth - depth0;
        float diff1 = centerDepth - depth1;
        float diff2 = centerDepth - depth2;

        float weight0 = rcp(1.0 + abs(diff0) * 120.0);
        float weight1 = rcp(1.0 + abs(diff1) * 120.0);
        float weight2 = rcp(1.0 + abs(diff2) * 120.0);

        occlusionSum += saturate((diff0 - bias) * 90.0) * weight0 * 1.00;
        occlusionSum += saturate((diff1 - bias) * 90.0) * weight1 * 0.78;
        occlusionSum += saturate((diff2 - bias) * 90.0) * weight2 * 0.58;
        sampleWeightSum += 1.00 + 0.78 + 0.58;
    }

    float occlusion = occlusionSum / max(sampleWeightSum, 0.0001);
    float ao = saturate(1.0 - occlusion * AOIntensity);
    return float4(ao, 0, 0, 1);
}

// Small depth-aware 3x3 bilateral filter, followed by conservative temporal
// accumulation. It reduces raw AO grain without blurring across depth edges.
float USS_AOSpatialFilter(float2 uv, float centerDepth)
{
    float aoSum = 0.0;
    float weightSum = 0.0;
    float2 px = ReShade::PixelSize;

    [loop]
    for (int y = -1; y <= 1; ++y)
    {
        [loop]
        for (int x = -1; x <= 1; ++x)
        {
            float2 sampleUV = saturate(uv + float2(x, y) * px);
            float sampleDepth = ReShade::GetLinearizedDepth(sampleUV);
            float sampleAO = tex2Dlod(USS110_AOCurrentS, float4(sampleUV, 0.0, 0.0)).r;
            float spatialWeight = (x == 0 && y == 0) ? 1.0 : ((x == 0 || y == 0) ? 0.75 : 0.50);
            float hudWeight = 1.0 - USS_HUDMask(sampleUV);
            float depthWeight = exp(-abs(sampleDepth - centerDepth) * 350.0);
            float w = spatialWeight * depthWeight * hudWeight;
            aoSum += sampleAO * w;
            weightSum += w;
        }
    }

    return aoSum / max(weightSum, 0.0001);
}

float4 PS_USS_AOTemporal(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float currentAO = tex2D(USS110_AOCurrentS, uv).r;
    if (!EnableAO)
        return float4(1.0, 0, 0, 1);

    float currentDepth = ReShade::GetLinearizedDepth(uv);
    if (currentDepth >= 0.9999)
        return float4(currentAO, 0, 0, 1);

    float filteredAO = USS_AOSpatialFilter(uv, currentDepth);
    if (!EnableAOTemporal || AOTemporalWeight <= 0.0)
        return float4(filteredAO, 0, 0, 1);

    // Depth history is stored as depth + 1.0. Zero/uninitialized history is
    // therefore always invalid, including on the first rendered frame.
    float previousDepthEncoded = tex2D(USS110_DepthHistoryS, uv).r;
    float historyValid = step(1.000001, previousDepthEncoded);
    float previousDepth = previousDepthEncoded - 1.0;
    float previousAO = tex2D(USS110_AOHistoryS, uv).r;

    float depthTolerance = max(0.0015, currentDepth * 0.008);
    float depthAgreement = 1.0 - saturate(abs(currentDepth - previousDepth) / depthTolerance);
    float historyWeight = min(AOTemporalWeight, 0.95) * depthAgreement * historyValid;
    float resolved = lerp(filteredAO, previousAO, historyWeight);
    return float4(saturate(resolved), 0, 0, 1);
}

float4 PS_USS_AOStore(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return tex2D(USS110_AOResolvedS, uv);
}

float4 PS_USS_DepthStore(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return float4(ReShade::GetLinearizedDepth(uv) + 1.0, 0, 0, 1);
}

// ------------------------------ Exposure -----------------------------------

float4 PS_USS_ExposureLuma(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (!AutoExposure)
        return float4(0.0, 0.0, 0.0, 0.0);
    float3 c = USS_SceneColorLinear(uv);
    float coverage = 1.0 - USS_HUDMask(uv);
    return float4(max(USS_Luma(c), 0.00001) * coverage, coverage, 0, 1);
}

float4 PS_USS_ExposureAdapt(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    // Level 8 is 1x1 after the pass-generated mip chain has been built.
    float2 lumaAndCoverage = tex2Dlod(USS110_ExposureLumaS, float4(0.5, 0.5, 0, 8)).rg;
    float averageLum = lumaAndCoverage.x / max(lumaAndCoverage.y, 0.0001);

    float previous = tex2D(USS110_ExposureHistoryS, float2(0.5, 0.5)).r;
    if (previous < 0.0001)
        previous = exp2(ExposureCompensation);

    // Do not drive exposure to its maximum when the entire frame is masked as HUD.
    float target = (lumaAndCoverage.y > 0.005)
        ? clamp(0.18 / max(averageLum, 0.0001), 0.25, 4.0) * exp2(ExposureCompensation)
        : previous;

    // AdaptationSpeed retains its existing 60 Hz meaning while compensating
    // for different frame rates using ReShade's frametime in milliseconds.
    float frameScale = max(FrameTime, 0.0) / 16.666667;
    float alpha = 1.0 - pow(max(1.0 - saturate(AdaptationSpeed), 0.000001), frameScale);
    float adapted = lerp(previous, target, saturate(alpha));

    if (!AutoExposure)
        adapted = exp2(ExposureCompensation);

    return float4(adapted, 0, 0, 1);
}

float4 PS_USS_ExposureStore(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    return tex2D(USS110_ExposureCurrentS, float2(0.5, 0.5));
}

// ------------------------- Color processing helpers ------------------------
float3 USS_RGBToHSV(float3 c)
{
    float cMax = max(c.r, max(c.g, c.b));
    float cMin = min(c.r, min(c.g, c.b));
    float delta = cMax - cMin;
    float h = 0.0;

    if (delta > 0.000001)
    {
        if (cMax == c.r)
            h = frac((c.g - c.b) / delta / 6.0);
        else if (cMax == c.g)
            h = ((c.b - c.r) / delta + 2.0) / 6.0;
        else
            h = ((c.r - c.g) / delta + 4.0) / 6.0;
    }

    float s = (cMax > 0.000001) ? delta / cMax : 0.0;
    return float3(frac(h), saturate(s), max(cMax, 0.0));
}

float3 USS_HSVToRGB(float3 hsv)
{
    float3 k = float3(0.0, 4.0, 2.0);
    float3 p = abs(frac(hsv.xxx + k / 6.0) * 6.0 - 3.0);
    float3 rgb = saturate(p - 1.0);
    return hsv.z * lerp(float3(1.0, 1.0, 1.0), rgb, saturate(hsv.y));
}

float USS_HueMask(float hue, float center, float halfWidth)
{
    float distance = abs(frac(hue - center + 0.5) - 0.5);
    return 1.0 - smoothstep(halfWidth * 0.62, halfWidth, distance);
}

float3 USS_ApplySelectiveColor(float3 color)
{
    if (!EnableSelectiveColor)
        return color;

    float3 hsv = USS_RGBToHSV(max(color, 0.0));
    float h = hsv.x;

    float chromaGate = smoothstep(0.025, 0.12, hsv.y);
    float mR = USS_HueMask(h, 0.000, 0.075) * chromaGate;
    float mO = USS_HueMask(h, 0.083, 0.075) * chromaGate;
    float mY = USS_HueMask(h, 0.167, 0.075) * chromaGate;
    float mG = USS_HueMask(h, 0.333, 0.090) * chromaGate;
    float mC = USS_HueMask(h, 0.500, 0.090) * chromaGate;
    float mB = USS_HueMask(h, 0.667, 0.090) * chromaGate;
    float mP = USS_HueMask(h, 0.750, 0.075) * chromaGate;
    float mM = USS_HueMask(h, 0.833, 0.075) * chromaGate;

    float maskSum = mR + mO + mY + mG + mC + mB + mP + mM;
    float safeMaskSum = max(maskSum, 0.0001);
    float influence = saturate(maskSum);
    float hueDelta = (mR * RedHue + mO * OrangeHue + mY * YellowHue +
                      mG * GreenHue + mC * CyanHue + mB * BlueHue +
                      mP * PurpleHue + mM * MagentaHue) / (360.0 * safeMaskSum);
    float saturationTarget = (mR * RedSaturation + mO * OrangeSaturation +
                      mY * YellowSaturation + mG * GreenSaturation +
                      mC * CyanSaturation + mB * BlueSaturation +
                      mP * PurpleSaturation + mM * MagentaSaturation) / safeMaskSum;
    float valueTarget = (mR * RedValue + mO * OrangeValue +
                      mY * YellowValue + mG * GreenValue +
                      mC * CyanValue + mB * BlueValue +
                      mP * PurpleValue + mM * MagentaValue) / safeMaskSum;
    float saturationMultiplier = lerp(1.0, saturationTarget, influence);
    float valueMultiplier = lerp(1.0, valueTarget, influence);

    hsv.x = frac(hsv.x + hueDelta * influence);
    hsv.y = saturate(hsv.y * saturationMultiplier);
    hsv.z = max(hsv.z * valueMultiplier, 0.0);
    return USS_HSVToRGB(hsv);
}

float3 USS_ApplyColorVision(float3 color)
{
    if (!EnableColorVision || ColorVisionMode == 0 || ColorVisionStrength <= 0.0)
        return color;

    const float3x3 protan = float3x3(
         0.152286, 1.052583, -0.204868,
         0.114503, 0.786281, 0.099216,
        -0.003882, -0.048116, 1.051998);
    const float3x3 deutan = float3x3(
         0.367322, 0.860646, -0.227968,
         0.280085, 0.672501, 0.047413,
        -0.011820, 0.042940, 0.968881);
    const float3x3 tritan = float3x3(
         1.255528, -0.076749, -0.178779,
        -0.078411, 0.930809, 0.147602,
         0.004733, 0.691367, 0.303900);

    float3 simulated = color;
    int mode = ColorVisionMode;
    if (mode == 1 || mode == 4)
        simulated = mul(protan, color);
    else if (mode == 2 || mode == 5)
        simulated = mul(deutan, color);
    else if (mode == 3 || mode == 6)
        simulated = mul(tritan, color);

    float3 adjusted = simulated;
    if (mode == 4)
    {
        float error = color.r - simulated.r;
        adjusted = color + float3(0.0, error * 0.70, error * 0.30);
    }
    else if (mode == 5)
    {
        float error = color.g - simulated.g;
        adjusted = color + float3(error * 0.70, 0.0, error * 0.30);
    }
    else if (mode == 6)
    {
        float error = color.b - simulated.b;
        adjusted = color + float3(error * 0.70, error * 0.30, 0.0);
    }

    return max(lerp(color, adjusted, saturate(ColorVisionStrength)), 0.0);
}

float3 USS_ApplyEyeProtection(float3 color)
{
    if (!EnableEyeProtection)
        return color;

    float3 warmScale = float3(1.0 + EyeWarmth * 0.035,
                              1.0 + EyeWarmth * 0.010,
                              1.0 - EyeBlueReduction * 0.65 - EyeWarmth * 0.10);
    color *= max(warmScale, 0.0);

    float lum = USS_Luma(color);
    float limit = max(EyeHighlightLimit, 0.01);
    float highlightScale = min(1.0, limit / max(lum, 0.0001));
    float highlightMask = smoothstep(limit * 0.55, limit * 1.25, lum);
    color = lerp(color, color * highlightScale, highlightMask);
    return max(color, 0.0);
}

// -------------------------- Final reconstruction --------------------------

float4 PS_USS_VisualFusion(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    if (EnableUSSX && USSX_DebugView != 0)
        return float4(tex2D(USS110_XTemporalS, uv).rgb, 1.0);

    float2 px = ReShade::PixelSize;
    float2 d = px * DetailRadius;

    float3 C = USS_SceneColorLinear(uv);

    // Cardinal and diagonal taps for frequency separation and edge analysis.
    float3 L = USS_SceneSample(uv + float2(-d.x, 0), C);
    float3 R = USS_SceneSample(uv + float2(d.x, 0), C);
    float3 U = USS_SceneSample(uv + float2(0, -d.y), C);
    float3 D = USS_SceneSample(uv + float2(0, d.y), C);
    float3 NW = USS_SceneSample(uv + float2(-d.x, -d.y), C);
    float3 NE = USS_SceneSample(uv + float2(d.x, -d.y), C);
    float3 SW = USS_SceneSample(uv + float2(-d.x, d.y), C);
    float3 SE = USS_SceneSample(uv + float2(d.x, d.y), C);

    float lum = USS_Luma(C);
    float gx = USS_Luma(R) - USS_Luma(L);
    float gy = USS_Luma(D) - USS_Luma(U);
    float gradientMagnitude = sqrt(gx * gx + gy * gy);
    float edgeMask = saturate(gradientMagnitude * 3.0);

    // Multiscale local contrast with reduced gain directly on strong edges.
    float2 local2Data = tex2D(USS110_Luma2S, uv).rg;
    float2 local4Data = tex2D(USS110_Luma4S, uv).rg;
    float2 local8Data = tex2D(USS110_Luma8S, uv).rg;
    float local2Lum = local2Data.x / max(local2Data.y, 0.00001);
    float local4Lum = local4Data.x / max(local4Data.y, 0.00001);
    float local8Lum = local8Data.x / max(local8Data.y, 0.00001);
    float w2 = 0.55 * local2Data.y;
    float w4 = 0.30 * local4Data.y;
    float w8 = 0.15 * local8Data.y;
    float localWeightA = w2 + w4 + w8;
    float localBaseA = (local2Lum * w2 + local4Lum * w4 + local8Lum * w8)
                     / max(localWeightA, 0.00001);
    localBaseA = (localWeightA > 0.00001) ? localBaseA : lum;
    float w2b = 0.35 * local2Data.y;
    float w4b = 0.35 * local4Data.y;
    float w8b = 0.30 * local8Data.y;
    float localWeightB = w2b + w4b + w8b;
    float localBaseB = (local2Lum * w2b + local4Lum * w4b + local8Lum * w8b)
                     / max(localWeightB, 0.00001);
    localBaseB = (localWeightB > 0.00001) ? localBaseB : lum;
    float localBase = lerp(localBaseA, localBaseB, LC_KernelShape);

    float lcDelta = lum - localBase;
    float exposureFusion = 1.0 + LC_HighlightShadow * (1.0 - saturate(lum));
    float lcEdgeGate = 1.0 - 0.35 * edgeMask;
    float lcGain = EnableLocalContrast
        ? 1.0 + clamp(lcDelta * LC_Strength * 2.0 * exposureFusion * lcEdgeGate, -0.35, 0.35)
        : 1.0;
    float3 localContrastColor = max(C * lcGain, 0.0);

    // High-frequency reconstruction with noise gating and edge protection.
    float3 lowFrequency = C * 0.20
                        + (L + R + U + D) * 0.12
                        + (NW + NE + SW + SE) * 0.08;
    float3 highFrequency = C - lowFrequency;
    float detailLuma = abs(USS_Luma(highFrequency));

    float edgeGate = 1.0 - edgeMask * EdgeProtection;
    float detailMask = saturate((detailLuma - NoiseThreshold) /
                                max(NoiseThreshold * 3.0, 0.0001));
    float detailStrength = EnableDetailReconstruction
        ? DetailAmount * detailMask * edgeGate
        : 0.0;
    float3 reconstructed = localContrastColor + highFrequency * detailStrength;

    // AO applies in linear scene space before bloom is composited.
    float aoFactor = EnableAO ? tex2D(USS110_AOResolvedS, uv).r : 1.0;
    reconstructed *= aoFactor;

    float3 localMin = min(C, min(min(L, R), min(U, D)));
    float3 localMax = max(C, max(max(L, R), max(U, D)));
    reconstructed = clamp(reconstructed,
                           localMin - DetailLimit,
                           localMax + DetailLimit);

    // Shared multi-scale bloom pyramid: close scales for HDR bloom, wider
    // scales for Magic Bloom. All intermediates remain unclamped float32.
    float3 bloomHDR = tex2D(USS110_Bloom2S, uv).rgb * 0.55
                    + tex2D(USS110_Bloom4S, uv).rgb * 0.35
                    + tex2D(USS110_Bloom8S, uv).rgb * 0.10;

    float3 bloomNarrow = tex2D(USS110_Bloom2S, uv).rgb * 0.55
                       + tex2D(USS110_Bloom4S, uv).rgb * 0.30
                       + tex2D(USS110_Bloom8S, uv).rgb * 0.15;
    float3 bloomWide = tex2D(USS110_Bloom4S, uv).rgb * 0.10
                     + tex2D(USS110_Bloom8S, uv).rgb * 0.20
                     + tex2D(USS110_Bloom16S, uv).rgb * 0.30
                     + tex2D(USS110_Bloom32S, uv).rgb * 0.40;
    float wideBlend = saturate((BloomRadius - 0.35) / 1.65);
    float3 bloomMagic = lerp(bloomNarrow, bloomWide, wideBlend);

    float3 result = reconstructed;
    if (EnableBloom)
    {
        result += bloomHDR * HDRBloomIntensity;
        float3 magicBloom = max(bloomMagic * MagicBloomIntensity, 0.0);
        magicBloom = magicBloom / (1.0 + magicBloom);
        result = 1.0 - (1.0 - result) * (1.0 - magicBloom);
    }

    float exposure = tex2D(USS110_ExposureCurrentS, float2(0.5, 0.5)).r;
    if (exposure < 0.0001)
        exposure = exp2(ExposureCompensation);
    result *= exposure;

    result = max((result - 0.18) * HDRContrast + 0.18, 0.0);
    result = USS_ToneMap(result);

    if (EnableColorEngine)
    {
        // Global saturation is applied in linear output space around luminance.
        float outputLuma = USS_Luma(result);
        result = lerp(outputLuma.xxx, result, SaturationStrength);
        result = max((result - 0.18) * ColorContrast + 0.18 + ColorBrightness, 0.0);
        float3 globalHSV = USS_RGBToHSV(result);
        globalHSV.x = frac(globalHSV.x + GlobalHueShift / 360.0);
        result = USS_HSVToRGB(globalHSV);

        float highlightLuma = USS_Luma(result);
        float whiteMask = smoothstep(0.55, 1.35, highlightLuma);
        result *= lerp(1.0, WhiteLevel, whiteMask);
        result = USS_ApplySelectiveColor(result);
    }

    result = USS_ApplyColorVision(result);
    result = USS_ApplyEyeProtection(result);

    if (DebugMode == 1)
        return float4(USS_ToDisplay(saturate(highFrequency * 4.0 + 0.5)), 1.0);

    if (DebugMode == 2)
        return float4(detailMask.xxx, 1.0);

    if (DebugMode == 3)
    {
        float contrastMask = saturate(abs(lcDelta) * 4.0);
        return float4(contrastMask, saturate(lum), saturate(localBase), 1.0);
    }

    if (DebugMode == 4)
        return float4(USS_ToDisplay(saturate(bloomHDR + bloomMagic)), 1.0);

    if (DebugMode == 5)
        return float4(saturate(exposure / 4.0).xxx, 1.0);

    if (DebugMode == 6)
        return float4(aoFactor.xxx, 1.0);

    float hudMask = USS_HUDMask(uv);
    if (DebugMode == 7)
        return float4(hudMask.xxx, 1.0);
    if (DebugMode == 8)
    {
        float4 reflectionDebug = tex2D(USS110_SSRReflectionS, uv);
        return float4(USS_ToDisplay(saturate(reflectionDebug.rgb)), reflectionDebug.a);
    }
    if (DebugMode == 9)
    {
        float3 hsvDebug = USS_RGBToHSV(max(C, 0.0));
        float h = hsvDebug.x;
        return float4(USS_HueMask(h, 0.000, 0.075),
                      USS_HueMask(h, 0.167, 0.075),
                      USS_HueMask(h, 0.667, 0.090), 1.0);
    }

    float3 displayColor = USS_ToDisplay(result);

    // Aspect-correct vignette; zero strength is fully neutral/off.
    if (EnableVignette && VignetteStrength > 0.0)
    {
        float2 centered = (uv - 0.5) * float2(ReShade::AspectRatio, 1.0);
        float vignetteDistance = length(centered);
        float vignetteMask = smoothstep(VignetteRadius,
                                        VignetteRadius + max(VignetteSoftness, 0.001),
                                        vignetteDistance);
        float vignetteFactor = 1.0 - saturate(VignetteStrength) * vignetteMask;
        displayColor *= vignetteFactor;
    }

    // Per-frame monochrome grain, generated after tone/gamma conversion.
    // It is applied only while the Enable Film Grain toggle is active.
    if (EnableFilmGrain && FilmGrainAmount > 0.0)
    {
        float2 grainCoord = floor(pos.xy / max(FilmGrainSize, 0.5));
        float frameSeed = (float) FrameCount;
        float noise = USS_Hash12(grainCoord + float2(frameSeed * 17.13, frameSeed * 31.71)) - 0.5;
        float grainLuma = USS_Luma(displayColor);
        float shadowBias = lerp(1.25, 0.70, saturate(grainLuma));
        displayColor += noise * FilmGrainAmount * shadowBias;
    }

    // Restore automatically detected HUD pixels from the original BackBuffer.
    // The confidence mask is deliberately conservative around uncertain pixels.
    float3 originalBackBuffer = tex2D(ReShade::BackBuffer, uv).rgb;
    displayColor = lerp(displayColor, originalBackBuffer, hudMask);
    return float4(saturate(displayColor), 1.0);
}

float4 PS_USSX_CopySource(float4 position : SV_Position,
                          float2 uv : TEXCOORD) : SV_Target
{
    return tex2D(ReShade::BackBuffer, uv);
}

// ---------------------- USS X temporal subpixel reconstruction -------------
// This is a post-process reconstruction heuristic. The 4x4 grid is virtual:
// it samples the already-composited image and does not create rasterizer MSAA.

float USSX_Luma(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float USSX_RGBDistance(float3 a, float3 b)
{
    float3 d = abs(a - b);
    return dot(d, float3(0.299, 0.587, 0.114));
}

float3 USSX_SamplePoint(float2 sampleUV, float3 centerColor)
{
    float2 q = saturate(sampleUV);
    float3 sampleColor = tex2Dlod(USS110_XSourcePointS, float4(q, 0.0, 0.0)).rgb;
    return lerp(sampleColor, centerColor, USS_HUDMask(q));
}

float3 USSX_SampleLinear(float2 sampleUV, float3 centerColor)
{
    float2 q = saturate(sampleUV);
    float3 sampleColor = tex2Dlod(USS110_XSourceLinearS, float4(q, 0.0, 0.0)).rgb;
    return lerp(sampleColor, centerColor, USS_HUDMask(q));
}

float3 USSX_EvaluateLineSide(
    float2 uv,
    float2 tangent,
    float2 normal,
    float side,
    float2 pixel,
    float3 centerColor,
    out float3 background,
    out float confidence)
{
    background = centerColor;
    confidence = 0.0;
    float2 candidateUV = saturate(uv + normal * pixel * side);
    float3 candidate = USSX_SamplePoint(candidateUV, centerColor);
    float3 t1 = USSX_SamplePoint(candidateUV + tangent * pixel, centerColor);
    float3 t2 = USSX_SamplePoint(candidateUV - tangent * pixel, centerColor);
    float3 t3 = USSX_SamplePoint(candidateUV + tangent * pixel * 2.0, centerColor);
    float3 t4 = USSX_SamplePoint(candidateUV - tangent * pixel * 2.0, centerColor);

    float3 foreground = candidate * 0.40 + t1 * 0.20 + t2 * 0.20
                      + t3 * 0.10 + t4 * 0.10;

    float3 b1 = USSX_SamplePoint(uv - normal * pixel * side * 1.5, centerColor);
    float3 b2 = USSX_SamplePoint(uv - normal * pixel * side * 2.5, centerColor);
    background = b1 * 0.65 + b2 * 0.35;

    float continuityError = USSX_RGBDistance(candidate, t1)
                          + USSX_RGBDistance(candidate, t2);
    float extendedError = USSX_RGBDistance(candidate, t3)
                        + USSX_RGBDistance(candidate, t4);
    float continuityMix = USSX_DirectionalContinuity
                        / (1.0 + USSX_DirectionalContinuity);
    float continuityMetric = lerp(continuityError,
                                  continuityError + extendedError * 0.5,
                                  continuityMix);
    float continuity = 1.0 - smoothstep(0.025, 0.22, continuityMetric);

    float contrast = USSX_RGBDistance(foreground, background);
    float contrastConfidence = smoothstep(0.025, 0.18,
                                          contrast * USSX_EdgeSensitivity);
    float centerBackgroundDifference = USSX_RGBDistance(centerColor, background);
    float backgroundConfidence = 1.0 - smoothstep(0.18, 0.40,
                                                  centerBackgroundDifference);
    confidence = saturate(continuity * contrastConfidence * backgroundConfidence);
    return foreground;
}

float4 USSX_EvaluateDirection(
    float2 uv,
    float2 tangent,
    float2 normal,
    float2 pixel,
    float3 centerColor,
    out float3 bestBackground)
{
    bestBackground = centerColor;

    float3 positiveBackground = centerColor;
    float positiveConfidence = 0.0;
    float3 positiveForeground = USSX_EvaluateLineSide(
        uv, tangent, normal, 1.0, pixel, centerColor,
        positiveBackground, positiveConfidence);

    float3 negativeBackground = centerColor;
    float negativeConfidence = 0.0;
    float3 negativeForeground = USSX_EvaluateLineSide(
        uv, tangent, normal, -1.0, pixel, centerColor,
        negativeBackground, negativeConfidence);

    float choosePositive = step(negativeConfidence, positiveConfidence);
    bestBackground = lerp(negativeBackground, positiveBackground, choosePositive);
    float3 selectedForeground = lerp(negativeForeground, positiveForeground, choosePositive);
    float selectedConfidence = lerp(negativeConfidence, positiveConfidence, choosePositive);
    return float4(selectedForeground, selectedConfidence);
}

float4 USSX_EstimateCoverage(
    float2 uv,
    float2 pixel,
    float3 foreground,
    float3 background,
    float edgeConfidence,
    float3 centerColor)
{
    float coverageSum = 0.0;
    float3 foregroundSum = 0.0;
    float foregroundWeight = 0.0;

    // A single 16-iteration loop replaces nested forced-unroll loops.
    // Explicit-LOD texture reads in USSX_SampleLinear prevent FXC from
    // converting this loop back into a large implicit-gradient expansion.
    [loop]
    for (int sampleIndex = 0; sampleIndex < 16; ++sampleIndex)
    {
        int sx = sampleIndex & 3;
        int sy = sampleIndex >> 2;
        float2 subpixelOffset = float2(((float) sx + 0.5) * 0.25 - 0.5,
                                       ((float) sy + 0.5) * 0.25 - 0.5);
        float2 sampleUV = uv + subpixelOffset * pixel;
        float3 sampleColor = USSX_SampleLinear(sampleUV, centerColor);

        float foregroundDistance = USSX_RGBDistance(sampleColor, foreground);
        float backgroundDistance = USSX_RGBDistance(sampleColor, background);
        float probability = saturate(0.5 +
            (backgroundDistance - foregroundDistance) * 4.0);
        probability = smoothstep(0.10, 0.90, probability);

        coverageSum += probability;
        float3 safeSample = clamp(sampleColor, min(foreground, background),
                                  max(foreground, background));
        foregroundSum += safeSample * probability;
        foregroundWeight += probability;
    }

    float coverage = coverageSum / 16.0;
    float3 sampledForeground = (foregroundWeight > 0.001)
        ? foregroundSum / foregroundWeight
        : foreground;
    float foregroundBlend = saturate(edgeConfidence * 0.5);
    foreground = lerp(foreground, sampledForeground, foregroundBlend);

    float coverageControl = 1.0 - exp(-USSX_SubpixelCoverageStrength);
    coverage = lerp(0.5, coverage,
                    saturate(edgeConfidence * coverageControl * 2.0));
    return float4(foreground, saturate(coverage));
}

float3 USSX_ReconstructRGB(
    float3 original,
    float3 foreground,
    float3 background,
    float coverage)
{
    float3 reconstructed = lerp(background, foreground, coverage);
    float originalLuma = USSX_Luma(original);
    float reconstructedLuma = USSX_Luma(reconstructed);
    float3 originalChroma = original - originalLuma;
    float3 reconstructedChroma = reconstructed - reconstructedLuma;
    float chromaAmount = saturate(USSX_ChromaPreservation);
    float3 preservedChroma = lerp(reconstructedChroma, originalChroma, chromaAmount);
    float3 chromaPreserved = reconstructedLuma + preservedChroma;
    reconstructed = lerp(reconstructed, chromaPreserved, chromaAmount);

    float3 localMinimum = min(original, min(foreground, background));
    float3 localMaximum = max(original, max(foreground, background));
    float3 safeColor = clamp(reconstructed, localMinimum, localMaximum);
    float antiRingingAmount = USSX_AntiRinging / (1.0 + USSX_AntiRinging);
    reconstructed = lerp(reconstructed, safeColor, antiRingingAmount);

    float rgbAmount = 1.0 - exp(-USSX_RGBReconstruction);
    return lerp(original, reconstructed, saturate(rgbAmount));
}

float4 PS_USSX_SubpixelReconstruction(float4 position : SV_Position,
                                      float2 uv : TEXCOORD) : SV_Target
{
    float3 original = tex2D(USS110_XSourcePointS, uv).rgb;

    // Keep detected HUD pixels unchanged and preserve the existing debug views.
    if (!EnableUSSX || DebugMode != 0 || USS_HUDMask(uv) > 0.001)
        return float4(original, 0.0);

    float2 pixel = ReShade::PixelSize;
    float3 background = original;
    float4 best = USSX_EvaluateDirection(uv, float2(1.0, 0.0),
        float2(0.0, 1.0), pixel, original, background);
    float directionCode = 0.0;

    float3 candidateBackground = original;
    float4 candidate = USSX_EvaluateDirection(uv, float2(0.0, 1.0),
        float2(1.0, 0.0), pixel, original, candidateBackground);
    if (candidate.a > best.a)
    {
        best = candidate;
        background = candidateBackground;
        directionCode = 0.33;
    }

    candidate = USSX_EvaluateDirection(uv, normalize(float2(1.0, 1.0)),
        normalize(float2(-1.0, 1.0)), pixel, original, candidateBackground);
    if (candidate.a > best.a)
    {
        best = candidate;
        background = candidateBackground;
        directionCode = 0.66;
    }

    candidate = USSX_EvaluateDirection(uv, normalize(float2(1.0, -1.0)),
        normalize(float2(1.0, 1.0)), pixel, original, candidateBackground);
    if (candidate.a > best.a)
    {
        best = candidate;
        background = candidateBackground;
        directionCode = 1.0;
    }

    float edgeConfidence = saturate(best.a);
    float4 coverageResult = USSX_EstimateCoverage(uv, pixel, best.rgb,
                                                  background, edgeConfidence, original);
    float coverage = coverageResult.a;
    float3 foreground = coverageResult.rgb;
    float3 reconstructedRGB = USSX_ReconstructRGB(original, foreground,
                                                  background, coverage);
    float reconstructionAmount = 1.0 - exp(-USSX_ReconstructionStrength);
    float finalStrength = saturate(reconstructionAmount * edgeConfidence);
    float3 result = lerp(original, reconstructedRGB, finalStrength);

    if (USSX_DebugView == 1)
        return float4(edgeConfidence.xxx, edgeConfidence);
    if (USSX_DebugView == 2)
        return float4(directionCode, edgeConfidence, 1.0 - edgeConfidence, edgeConfidence);
    if (USSX_DebugView == 3)
        return float4(coverage.xxx, edgeConfidence);
    if (USSX_DebugView == 4)
        return float4(reconstructedRGB, edgeConfidence);

    // Alpha carries edge-confidence-weighted coverage into the T-2 validator.
    return float4(result, saturate(coverage * edgeConfidence));
}

void USSX_ConsiderHistory(
    float2 uv,
    float2 offset,
    float3 currentRGB,
    float currentCoverage,
    inout float bestError,
    inout float3 bestHistoryRGB,
    inout float bestHistoryCoverage,
    inout float2 bestOffset,
    inout float historyFound)
{
    float4 history = tex2Dlod(USS110_XHistory2S, float4(saturate(uv + offset), 0.0, 0.0));
    float valid = step(1.5, history.a);
    float historicalCoverage = saturate(history.a - 2.0);
    float colorError = USSX_RGBDistance(currentRGB, history.rgb);
    float coverageError = abs(currentCoverage - historicalCoverage);
    float totalError = colorError + coverageError * 0.10;

    if (valid > 0.5 && totalError < bestError)
    {
        bestError = totalError;
        bestHistoryRGB = history.rgb;
        bestHistoryCoverage = historicalCoverage;
        bestOffset = offset;
        historyFound = 1.0;
    }
}

float4 PS_USSX_TemporalResolve(float4 position : SV_Position,
                               float2 uv : TEXCOORD) : SV_Target
{
    float4 current = tex2D(USS110_XCurrentS, uv);
    if (!EnableUSSX || DebugMode != 0 || USS_HUDMask(uv) > 0.001)
        return current;

    if (USSX_DebugView >= 1 && USSX_DebugView <= 4)
        return current;

    if (!EnableUSSXTemporal)
    {
        if (USSX_DebugView == 5)
            return float4(0.0, 0.0, 0.0, 1.0);
        return current;
    }

    float2 pixel = ReShade::PixelSize;
    float bestError = 1e20;
    float3 bestHistoryRGB = current.rgb;
    float bestHistoryCoverage = current.a;
    float historyFound = 0.0;

    // Coarse-to-fine T-2 search: up to +/-15 px, then progressively refine
    // around the best candidate. Four 3x3 stages = 36 comparisons, not 31x31.
    if (FrameCount >= 2)
    {
        float2 bestOffset = float2(0.0, 0.0);
        float coarseStep = max(USSX_HistorySearchRadius, 1.0);
        float refineStep1 = max(coarseStep / 3.0, 0.75);
        float refineStep2 = max(coarseStep / 9.0, 0.50);
        float refineStep3 = max(coarseStep / 27.0, 0.25);

        [loop]
        for (int y = -1; y <= 1; ++y)
        {
            [loop]
            for (int x = -1; x <= 1; ++x)
                USSX_ConsiderHistory(uv, float2((float) x, (float) y) * pixel * coarseStep,
                    current.rgb, current.a, bestError, bestHistoryRGB,
                    bestHistoryCoverage, bestOffset, historyFound);
        }

        float2 stageCenter = bestOffset;
        [loop]
        for (int y = -1; y <= 1; ++y)
        {
            [loop]
            for (int x = -1; x <= 1; ++x)
                USSX_ConsiderHistory(uv, stageCenter + float2((float) x, (float) y) * pixel * refineStep1,
                    current.rgb, current.a, bestError, bestHistoryRGB,
                    bestHistoryCoverage, bestOffset, historyFound);
        }

        stageCenter = bestOffset;
        [loop]
        for (int y = -1; y <= 1; ++y)
        {
            [loop]
            for (int x = -1; x <= 1; ++x)
                USSX_ConsiderHistory(uv, stageCenter + float2((float) x, (float) y) * pixel * refineStep2,
                    current.rgb, current.a, bestError, bestHistoryRGB,
                    bestHistoryCoverage, bestOffset, historyFound);
        }

        stageCenter = bestOffset;
        [loop]
        for (int y = -1; y <= 1; ++y)
        {
            [loop]
            for (int x = -1; x <= 1; ++x)
                USSX_ConsiderHistory(uv, stageCenter + float2((float) x, (float) y) * pixel * refineStep3,
                    current.rgb, current.a, bestError, bestHistoryRGB,
                    bestHistoryCoverage, bestOffset, historyFound);
        }
    }

    float threshold = max(USSX_TemporalColorThreshold, 0.0001);
    float temporalConfidence = historyFound *
        (1.0 - smoothstep(threshold * 0.35, threshold, bestError));
    temporalConfidence *= saturate(current.a * 2.0);
    float temporalAmount = USSX_TemporalStability /
                           (1.0 + USSX_TemporalStability);
    float temporalWeight = saturate(temporalAmount * temporalConfidence);

    if (USSX_DebugView == 5)
        return float4(temporalConfidence.xxx, 1.0);

    float3 resolvedRGB = lerp(current.rgb, bestHistoryRGB, temporalWeight);
    float resolvedCoverage = lerp(current.a, bestHistoryCoverage, temporalWeight);
    return float4(resolvedRGB, saturate(resolvedCoverage));
}

float4 PS_USSX_ShiftHistory(float4 position : SV_Position,
                            float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableUSSX || !EnableUSSXTemporal || DebugMode != 0 || USSX_DebugView != 0)
        return float4(0.0, 0.0, 0.0, 0.0);
    return tex2D(USS110_XHistory1S, uv);
}

float4 PS_USSX_SaveHistory(float4 position : SV_Position,
                           float2 uv : TEXCOORD) : SV_Target
{
    if (!EnableUSSX || !EnableUSSXTemporal || DebugMode != 0 || USSX_DebugView != 0)
        return float4(0.0, 0.0, 0.0, 0.0);
    float4 resolved = tex2D(USS110_XTemporalS, uv);
    return float4(resolved.rgb, saturate(resolved.a) + 2.0);
}

// -------------------------------- Technique ---------------------------------

technique USS_VisualFusion_1_10
{
    // Build the automatic HUD mask first; all following stages consume this mask.
    pass HUD_Mask_Build
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_HUDMask;
        RenderTarget = USS110_HUDMaskTexture;
    }

    // USS X runs on the original game frame, before Bloom, AO, local contrast and grading.
    pass USSX_Copy_Source
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USSX_CopySource;
        RenderTarget = USS110_XSource;
    }
    pass USSX_Subpixel_Reconstruction
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USSX_SubpixelReconstruction;
        RenderTarget = USS110_XCurrent;
    }
    pass USSX_Temporal_T2_Resolve
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USSX_TemporalResolve;
        RenderTarget = USS110_XTemporal;
    }

    // Optional half-resolution SSR. It is disabled by default and requires a valid game depth buffer.
    pass SSR_Trace
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_SSRTrace;
        RenderTarget = USS110_SSRReflection;
    }

    // Local-contrast luminance pyramid, now based on USS X plus optional SSR.
    pass Luma_Half
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Luma2;
        RenderTarget = USS110_Luma2;
    }
    pass Luma_Quarter
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Luma4;
        RenderTarget = USS110_Luma4;
    }
    pass Luma_Eighth
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Luma8;
        RenderTarget = USS110_Luma8;
    }

    // Shared precision bloom pyramid.
    pass Bloom_Extract
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Bloom2;
        RenderTarget = USS110_Bloom2;
    }
    pass Bloom_Quarter
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Bloom4;
        RenderTarget = USS110_Bloom4;
    }
    pass Bloom_Eighth
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Bloom8;
        RenderTarget = USS110_Bloom8;
    }
    pass Bloom_Sixteenth
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Bloom16;
        RenderTarget = USS110_Bloom16;
    }
    pass Bloom_ThirtySecond
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_Bloom32;
        RenderTarget = USS110_Bloom32;
    }

    // Depth-based AO, bilateral filtering and temporal stabilization.
    pass Ambient_Occlusion
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_AO;
        RenderTarget = USS110_AOCurrent;
    }
    pass AO_Temporal_Resolve
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_AOTemporal;
        RenderTarget = USS110_AOResolved;
    }

    // Exposure analysis excludes automatically detected HUD pixels and builds the mip chain.
    pass Exposure_Luminance
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_ExposureLuma;
        RenderTarget = USS110_ExposureLuma;
        GenerateMipMaps = true;
    }
    pass Exposure_Adapt
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_ExposureAdapt;
        RenderTarget = USS110_ExposureCurrent;
    }

    // Visual Fusion is the final image pass and restores protected HUD pixels from the original BackBuffer.
    pass Visual_Fusion
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_VisualFusion;
    }

    // Preserve previous USS X frames for T-2 search; these passes do not touch the displayed BackBuffer.
    pass USSX_Shift_History_T1_to_T2
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USSX_ShiftHistory;
        RenderTarget = USS110_XHistory2;
    }
    pass USSX_Save_History_T1
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USSX_SaveHistory;
        RenderTarget = USS110_XHistory1;
    }

    // Store AO, depth and exposure histories after the final image pass.
    pass AO_History_Store
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_AOStore;
        RenderTarget = USS110_AOHistory;
    }
    pass Depth_History_Store
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_DepthStore;
        RenderTarget = USS110_DepthHistory;
    }
    pass Exposure_Store
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_ExposureStore;
        RenderTarget = USS110_ExposureHistory;
    }

    // Capture the original game image for automatic HUD stability detection next frame.
    pass HUD_History_Store
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_USS_HUDHistoryStore;
        RenderTarget = USS110_HUDColorHistory;
    }
}