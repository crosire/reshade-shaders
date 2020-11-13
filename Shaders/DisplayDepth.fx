/*
 * Ported from Reshade v2.x. Original by CeeJay.
 * Visualizes the depth buffer: further away is more white than close by pixels. 
 * Use this to configure the depth input preprocessor definitions (RESHADE_DEPTH_INPUT_*).
 */

#include "ReShade.fxh"

#if (__RESHADE__ < 30101) || (__RESHADE__ >= 40600)
	#define __DISPLAYDEPTH_UI_FAR_PLANE_DEFAULT__ 1000.0
	#define __DISPLAYDEPTH_UI_UPSIDE_DOWN_DEFAULT__ 0
	#define __DISPLAYDEPTH_UI_REVERSED_DEFAULT__ 0
	#define __DISPLAYDEPTH_UI_LOGARITHMIC_DEFAULT__ 0
#else
	#define __DISPLAYDEPTH_UI_FAR_PLANE_DEFAULT__ 1000.0
	#define __DISPLAYDEPTH_UI_UPSIDE_DOWN_DEFAULT__ 0
	#define __DISPLAYDEPTH_UI_REVERSED_DEFAULT__ 1
	#define __DISPLAYDEPTH_UI_LOGARITHMIC_DEFAULT__ 0
#endif

#ifndef RESHADE_DISPLAYDEPTH_UNLOCKED
	// "ui_text" was introduced in ReShade 4.5, so cannot show instructions before
	#define RESHADE_DISPLAYDEPTH_UNLOCKED (__RESHADE__ < 40500)
#endif

#if RESHADE_DISPLAYDEPTH_UNLOCKED == 0

uniform int iUIHelp <
ui_type = "radio";
ui_label = " ";
ui_text = "All realtime controls (sliders, checkboxes...) will only affect DisplayDepth by default.\n"
	"To apply their settings globally, they have to be copied to the global preprocessor definitions.\n"
	"To guide you on how to do this, you need to unlock the realtime controls of this shader with the same method:\n"
	"Click on 'Edit global preprocessor definitions', where 4 default entries should already be present. To unlock the realtime controls, add a new entry as follows:\n\n"
	"RESHADE_DISPLAYDEPTH_UNLOCKED       1\n\n"
	"If done properly, various controls below will unlock. Now tweak these settings until the output looks correct, then transfer the new settings to the same place where you added the above entry.";
>;

// Replace all with stubs
#define bUIUsePreprocessorDefs 0
#define fUIFarPlane __DISPLAYDEPTH_UI_FAR_PLANE_DEFAULT__
#define fUIDepthMultiplier 1.0
#define iUIUpsideDown __DISPLAYDEPTH_UI_UPSIDE_DOWN_DEFAULT__
#define iUIReversed __DISPLAYDEPTH_UI_REVERSED_DEFAULT__
#define iUILogarithmic __DISPLAYDEPTH_UI_LOGARITHMIC_DEFAULT__ 
#define iUIOffset int2(0.0, 0.0)
#define fUIScale float2(1.0, 1.0)
#define iUIPresentType 2
#define bUIShowOffset 0

#else

uniform bool bUIUsePreprocessorDefs <
	ui_label = "Use global preprocessor definitions";
	ui_tooltip = "Enable this to use the values set via global preprocessor definitions rather than the ones below.";
> = false;

uniform float fUIFarPlane <
	ui_type = "drag";
	ui_label = "Far Plane";
	ui_tooltip = "RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=<value>\n"
	             "Changing this value is not necessary in most cases.";
	ui_min = 0.0; ui_max = 1000.0;
	ui_step = 0.1;
> = __DISPLAYDEPTH_UI_FAR_PLANE_DEFAULT__;

uniform float fUIDepthMultiplier <
	ui_type = "drag";
	ui_label = "Multiplier";
	ui_tooltip = "RESHADE_DEPTH_MULTIPLIER=<value>";
	ui_min = 0.0; ui_max = 1000.0;
	ui_step = 0.001;
> = 1.0;

uniform int iUIUpsideDown <
	ui_type = "combo";
	ui_label = "Upside Down";
	ui_items = "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=0\0RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=1\0";
> = __DISPLAYDEPTH_UI_UPSIDE_DOWN_DEFAULT__;

uniform int iUIReversed <
	ui_type = "combo";
	ui_label = "Reversed";
	ui_items = "RESHADE_DEPTH_INPUT_IS_REVERSED=0\0RESHADE_DEPTH_INPUT_IS_REVERSED=1\0";
> = __DISPLAYDEPTH_UI_REVERSED_DEFAULT__;

uniform int iUILogarithmic <
	ui_type = "combo";
	ui_label = "Logarithmic";
	ui_items = "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=0\0RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=1\0";
	ui_tooltip = "Change this setting if the displayed surface normals have stripes in them.";
> = __DISPLAYDEPTH_UI_LOGARITHMIC_DEFAULT__;

uniform int2 iUIOffset <
	ui_type = "drag";
	ui_label = "Offset";
	ui_tooltip = "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the offset in pixels.\n"
	             "Use these values for:\nRESHADE_DEPTH_INPUT_X_PIXEL_OFFSET=<left value>\nRESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET=<right value>";
	ui_step = 1;
> = int2(0, 0);

uniform float2 fUIScale <
	ui_type = "drag";
	ui_label = "Scale";
	ui_tooltip = "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the scale.\n"
	             "Use these values for:\nRESHADE_DEPTH_INPUT_X_SCALE=<left value>\nRESHADE_DEPTH_INPUT_Y_SCALE=<right value>";
	ui_min = 0.0; ui_max = 2.0;
	ui_step = 0.001;
> = float2(1.0, 1.0);

uniform int iUIPresentType <
	ui_category = "Options";
	ui_type = "combo";
	ui_label = "Present type";
	ui_items = "Depth map\0Normal map\0Show both (Vertical 50/50)\0";
> = 2;

uniform bool bUIShowOffset <
	ui_category = "Options";
	ui_type = "radio";
	ui_tooltip = "Blend depth output with backbuffer";
	ui_label = "Show Offset";
> = false;

#endif

float GetLinearizedDepth(float2 texcoord)
{
	if (bUIUsePreprocessorDefs)
	{
		return ReShade::GetLinearizedDepth(texcoord);
	}
	else
	{
		// RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		if (iUIUpsideDown)
			texcoord.y = 1.0 - texcoord.y;

		// RESHADE_DEPTH_INPUT_X_SCALE
		texcoord.x /= fUIScale.x;
		// RESHADE_DEPTH_INPUT_Y_SCALE
		texcoord.y /= fUIScale.y;
		// RESHADE_DEPTH_INPUT_X_PIXEL_OFFSET
		texcoord.x -= iUIOffset.x * BUFFER_RCP_WIDTH;
		// RESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET
		texcoord.y += iUIOffset.y * BUFFER_RCP_HEIGHT;

		float depth = tex2Dlod(ReShade::DepthBuffer, float4(texcoord, 0, 0)).x * fUIDepthMultiplier;

		// RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		if (iUILogarithmic)
			depth = (exp(depth * log(C + 1.0)) - 1.0) / C;

		// RESHADE_DEPTH_INPUT_IS_REVERSED
		if (iUIReversed)
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
	ui_tooltip = "This shader helps finding the right preprocessor settings for depth input.\n\n"
                 "By default calculated normals are shown and the goal is to make the displayed surface normals look smooth.\n"
                 "Change the options for *_IS_REVERSED and *_IS_LOGARITHMIC in the variable editor until this happens.\n"
                 "Change the 'Present type' to 'Depth map' and check whether close objects are dark and far away objects are white.\n\n"
                 "When the right settings are found click on 'Edit global preprocessor definitions' and put the new values there."; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DisplayDepth;
	}
}