/*
  DisplayDepth by CeeJay.dk (with many updates and additions by the Reshade community)

  Visualizes the depth buffer. The distance of pixels determine their brightness.
  Close objects are dark. Far away objects are bright.
  Use this to configure the depth input preprocessor definitions (RESHADE_DEPTH_INPUT_*).

  "OK .. one last time, these are SMALL, but the ones out there are FAR AWAY"
  */

#include "ReShade.fxh"

// -- Basic options --
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
#define TEXT_UPSIDE_DOWN "1"
#define TEXT_UPSIDE_DOWN_ALTER "0"
#else
#define TEXT_UPSIDE_DOWN "0"
#define TEXT_UPSIDE_DOWN_ALTER "1"
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
#define TEXT_REVERSED "1"
#define TEXT_REVERSED_ALTER "0"
#else
#define TEXT_REVERSED "0"
#define TEXT_REVERSED_ALTER "1"
#endif
#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
#define TEXT_LOGARITHMIC "1"
#define TEXT_LOGARITHMIC_ALTER "0"
#else
#define TEXT_LOGARITHMIC "0"
#define TEXT_LOGARITHMIC_ALTER "1"
#endif

#include "DisplayDepth_L10N.fxh" //Include the Translations

// "ui_text" was introduced in ReShade 4.5, so cannot show instructions in older versions

uniform int iUIPresentType <
    ui_label = "Present type";
    ui_type = "combo";
    ui_items = "Depth map\0Normal map\0Show both (Vertical 50/50)\0";
#if __RESHADE__ < 40500
    ui_tooltip =
#else
    ui_text =
#endif
        "The right settings need to be set in the dialog that opens after clicking the \"Edit global preprocessor definitions\" button above.\n"
        "\n"
        "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN is currently set to " TEXT_UPSIDE_DOWN ".\n"
        "If the Depth map is shown upside down set it to " TEXT_UPSIDE_DOWN_ALTER ".\n"
        "\n"
        "RESHADE_DEPTH_INPUT_IS_REVERSED is currently set to " TEXT_REVERSED ".\n"
        "If close objects in the Depth map are bright and far ones are dark set it to " TEXT_REVERSED_ALTER ".\n"
        "Also try this if you can see the normals, but the depth view is all black.\n"
        "\n"
        "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC is currently set to " TEXT_LOGARITHMIC ".\n"
        "If the Normal map has banding artifacts (extra stripes) set it to " TEXT_LOGARITHMIC_ALTER ".";
UI_PRESENT_TYPE_L10N
> = 2;

uniform bool bUIShowOffset <
    ui_label = "Blend Depth map into the image (to help with finding the right offset)";
	UI_SHOW_OFFSET_L10N
> = false;

uniform bool bUIUseLivePreview <
    ui_category = "Preview settings";
#if __RESHADE__ <= 50902
    ui_category_closed = true;
#elif !ADDON_ADJUST_DEPTH
    ui_category_toggle = true;
#endif
    ui_label = "Show live preview and ignore preprocessor definitions";
    ui_tooltip = "Enable this to preview with the current preset settings instead of the global preprocessor settings.";
	UI_USE_LIVE_PREVIEW_L10N
> = false;

#if __RESHADE__ <= 50902
uniform int iUIUpsideDown <
#else
uniform bool iUIUpsideDown <
#endif
    ui_category = "Preview settings";
    ui_label = "Upside Down";
#if __RESHADE__ <= 50902
    ui_type = "combo";
    ui_items = "Off\0On\0";
#endif
UI_UPSIDE_DOWN_L10N
> = RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN;

//-----

#if __RESHADE__ <= 50902
uniform int iUIReversed <
#else
uniform bool iUIReversed <
#endif
    ui_category = "Preview settings";
    ui_label = "Reversed";
#if __RESHADE__ <= 50902
    ui_type = "combo";
    ui_items = "Off\0On\0";
#endif
UI_REVERSED_L10N
> = RESHADE_DEPTH_INPUT_IS_REVERSED;
//---
#if __RESHADE__ <= 50902
uniform int iUILogarithmic <
#else
uniform bool iUILogarithmic <
#endif
    ui_category = "Preview settings";
    ui_label = "Logarithmic";
#if __RESHADE__ <= 50902
    ui_type = "combo";
    ui_items = "Off\0On\0";
#endif
    ui_tooltip = "Change this setting if the displayed surface normals have stripes in them.";
UI_LOGARITHMIC_L10N
> = RESHADE_DEPTH_INPUT_IS_LOGARITHMIC;

// -- Advanced options --

uniform float2 fUIScale <
    ui_category = "Preview settings";
    ui_label = "Scale";
    ui_type = "drag";
    ui_text =
        "\n"
        " * Advanced options\n"
        "\n"
        "The following settings also need to be set using \"Edit global preprocessor definitions\" above in order to take effect.\n"
        "You can preview how they will affect the Depth map using the controls below.\n"
        "\n"
        "It is rarely necessary to change these though, as their defaults fit almost all games.\n\n";
    ui_tooltip =
        "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the scale.\n"
        "Use these values for:\nRESHADE_DEPTH_INPUT_X_SCALE=<left value>\nRESHADE_DEPTH_INPUT_Y_SCALE=<right value>\n"
        "\n"
        "If you know the right resolution of the games depth buffer then this scale value is simply the ratio\n"
        "between the correct resolution and the resolution Reshade thinks it is.\n"
        "For example:\n"
        "If it thinks the resolution is 1920 x 1080, but it's really 1280 x 720 then the right scale is (1.5 , 1.5)\n"
        "because 1920 / 1280 is 1.5 and 1080 / 720 is also 1.5, so 1.5 is the right scale for both the x and the y";
    UI_SCALE_L10N
    ui_min = 0.0; ui_max = 2.0;
    ui_step = 0.001;
> = float2(RESHADE_DEPTH_INPUT_X_SCALE, RESHADE_DEPTH_INPUT_Y_SCALE);

uniform int2 iUIOffset <
    ui_category = "Preview settings";
    ui_label = "Offset";
    ui_type = "slider";
    ui_tooltip =
        "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the offset in pixels.\n"
        "Use these values for:\nRESHADE_DEPTH_INPUT_X_PIXEL_OFFSET=<left value>\nRESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET=<right value>";
	UI_OFFSET_L10N
    ui_min = -BUFFER_SCREEN_SIZE;
    ui_max = BUFFER_SCREEN_SIZE;
    ui_step = 1;
> = int2(RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET, RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET);

uniform float fUIFarPlane <
    ui_category = "Preview settings";
    ui_label = "Far Plane";
    ui_type = "drag";
    ui_tooltip = 
        "RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=<value>\n"
        "Changing this value is not necessary in most cases.";
	UI_FAR_PLANE_L10N
    ui_min = 0.0; ui_max = 1000.0;
    ui_step = 0.1;
> = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;

uniform float fUIDepthMultiplier <
    ui_category = "Preview settings";
    ui_label = "Multiplier";
    ui_type = "drag";
    ui_tooltip = "RESHADE_DEPTH_MULTIPLIER=<value>";
	UI_MULTIPLIER_L10N
    ui_min = 0.0; ui_max = 1000.0;
    ui_step = 0.001;
> = RESHADE_DEPTH_MULTIPLIER;

float GetLinearizedDepth(float2 texcoord)
{
    if (!bUIUseLivePreview)
    {
        return ReShade::GetLinearizedDepth(texcoord);
    }
    else
    {
        if (iUIUpsideDown) // RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
            texcoord.y = 1.0 - texcoord.y;

        texcoord.x /= fUIScale.x; // RESHADE_DEPTH_INPUT_X_SCALE
        texcoord.y /= fUIScale.y; // RESHADE_DEPTH_INPUT_Y_SCALE
        texcoord.x -= iUIOffset.x * BUFFER_RCP_WIDTH; // RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
        texcoord.y += iUIOffset.y * BUFFER_RCP_HEIGHT; // RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET

        float depth = tex2Dlod(ReShade::DepthBuffer, float4(texcoord, 0, 0)).x * fUIDepthMultiplier;

        const float C = 0.01;
        if (iUILogarithmic) // RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
            depth = (exp(depth * log(C + 1.0)) - 1.0) / C;

        if (iUIReversed) // RESHADE_DEPTH_INPUT_IS_REVERSED
            depth = 1.0 - depth;

        const float N = 1.0;
        depth /= fUIFarPlane - depth * (fUIFarPlane - N);

        return depth;
    }
}

float3 GetScreenSpaceNormal(float2 texcoord)
{
    float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
    float2 posCenter = texcoord.xy;
    float2 posNorth  = posCenter - offset.zy;
    float2 posEast   = posCenter + offset.xz;

    float3 vertCenter = float3(posCenter - 0.5, 1) * GetLinearizedDepth(posCenter);
    float3 vertNorth  = float3(posNorth - 0.5,  1) * GetLinearizedDepth(posNorth);
    float3 vertEast   = float3(posEast - 0.5,   1) * GetLinearizedDepth(posEast);

    return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

void PS_DisplayDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float3 color : SV_Target)
{
    float3 depth = GetLinearizedDepth(texcoord).xxx;
    float3 normal = GetScreenSpaceNormal(texcoord);

    // Ordered dithering
#if 1
    const float dither_bit = 8.0; // Number of bits per channel. Should be 8 for most monitors.
    // Calculate grid position
    float grid_position = frac(dot(texcoord, (BUFFER_SCREEN_SIZE * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25));
    // Calculate how big the shift should be
    float dither_shift = 0.25 * (1.0 / (pow(2, dither_bit) - 1.0));
    // Shift the individual colors differently, thus making it even harder to see the dithering pattern
    float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); // Subpixel dithering
    // Modify shift acording to grid position.
    dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position);
    depth += dither_shift_RGB;
#endif

    color = depth;
    if (iUIPresentType == 1)
        color = normal;
    if (iUIPresentType == 2)
        color = lerp(normal, depth, step(BUFFER_WIDTH * 0.5, position.x));

    if (bUIShowOffset)
    {
        float3 color_orig = tex2D(ReShade::BackBuffer, texcoord).rgb;

        // Blend depth and back buffer color with 'overlay' so the offset is more noticeable
        color = lerp(2 * color * color_orig, 1.0 - 2.0 * (1.0 - color) * (1.0 - color_orig), max(color.r, max(color.g, color.b)) < 0.5 ? 0.0 : 1.0);
    }
}

technique DisplayDepth <
    ui_tooltip =
        "This shader helps you set the right preprocessor settings for depth input.\n"
        "To set the settings click on 'Edit global preprocessor definitions' and set them there - not in this shader.\n"
        "The settings will then take effect for all shaders, including this one.\n"  
        "\n"
        "By default calculated normals and depth are shown side by side.\n"
        "Normals (on the left) should look smooth and the ground should be greenish when looking at the horizon.\n"
        "Depth (on the right) should show close objects as dark and use gradually brighter shades the further away objects are.\n";
	UI_TECHNIQUE_L10N
>

{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_DisplayDepth;
    }
}
