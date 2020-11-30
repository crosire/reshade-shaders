/*
  DisplayDepth by CeeJay.dk (with many updates and additions by the Reshade community)

  Visualizes the depth buffer. The distance of pixels determine their brightness.
  Close objects are dark. Far away objects are bright.
  Use this to configure the depth input preprocessor definitions (RESHADE_DEPTH_INPUT_*).
*/

#include "ReShade.fxh"

// -- ReShade version check --
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

/*
#ifndef RESHADE_DISPLAYDEPTH_UNLOCKED
	// "ui_text" was introduced in ReShade 4.5, so cannot show instructions before
	#define RESHADE_DISPLAYDEPTH_UNLOCKED (__RESHADE__ < 40500)
#endif


//#define bUIUsePreprocessorDefs 1

//#if RESHADE_DISPLAYDEPTH_UNLOCKED == 0
*/


#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	#define UPSIDE_DOWN_TEXT "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN is currently set to 1\n"\
	"If the Depth map is shown upside down set it to 0"
#else
	#define UPSIDE_DOWN_TEXT "RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN is currently set to 0\n"\
	"If the Depth map is shown upside down set it to 1"
#endif

#if RESHADE_DEPTH_INPUT_IS_REVERSED
	#define REVERSED_TEXT "RESHADE_DEPTH_INPUT_IS_REVERSED is currently set to 1\n"\
	"If close surfaces in the Depth map are bright and far ones are dark set it to 0"
#else
	#define REVERSED_TEXT "RESHADE_DEPTH_INPUT_IS_REVERSED is currently set to 0\n"\
	"If close surfaces in the Depth map are bright and far ones are dark set it to 1"
#endif

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
	#define LOGARITHMIC_TEXT "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC is currently set to 1\n"\
	"If the Normal map has banding artifacts set it to 0"
#else
	#define LOGARITHMIC_TEXT "RESHADE_DEPTH_INPUT_IS_LOGARITHMIC is currently set to 0\n"\
	"If the Normal map has banding artifacts set it to to 1"
#endif


/*
"The Depth buffer is an image that tell the shaders how far away from the camera each pixel is and effects that need this info require the Depth buffer to be setup correctly.\n"
"This effect exists to help you do just that.\n"

"The Depth settings are \n"
*/

uniform int Depth_help <
ui_type = "radio";
ui_label = " ";
ui_text = "The right settings need to be set using the \"Edit global preprocessor definitions\" above\n"

"\n"
UPSIDE_DOWN_TEXT "\n"
"\n"
REVERSED_TEXT "\n"
"\n"
LOGARITHMIC_TEXT "\n";
>;

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

// -- Advanced options --
uniform int Advanced_help <
ui_category = "Advanced settings"; 
ui_category_closed = true;
ui_type = "radio";
ui_label = " ";
ui_text = "These settings also need to be saved using \"Edit global preprocessor definitions\" above in order to take effect.\n"
"You can preview how the settings will affect the depth image using the controls below.\n"
"\n"
"Though you rarely need to change these settings as their defaults fit almost all games.";
>;


uniform float fUIFarPlane <
	ui_category = "Advanced settings"; 
	ui_type = "drag";
	ui_label = "Far Plane (Preview)";
	ui_tooltip = "RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=<value>\n"
	             "Changing this value is not necessary in most cases.";
	ui_min = 0.0; ui_max = 1000.0;
	ui_step = 0.1;
//> = __DISPLAYDEPTH_UI_FAR_PLANE_DEFAULT__;	
> = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;

uniform float fUIDepthMultiplier <
	ui_category = "Advanced settings"; 
	ui_type = "drag";
	ui_label = "Multiplier  (Preview)";
	ui_tooltip = "RESHADE_DEPTH_MULTIPLIER=<value>";
	ui_min = 0.0; ui_max = 1000.0;
	ui_step = 0.001;
> = 1.0;

uniform int2 iUIOffset <
	ui_category = "Advanced settings"; 
	ui_type = "drag";
	ui_label = "Offset  (Preview)";
	ui_tooltip = "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the offset in pixels.\n"
	             "Use these values for:\nRESHADE_DEPTH_INPUT_X_PIXEL_OFFSET=<left value>\nRESHADE_DEPTH_INPUT_Y_PIXEL_OFFSET=<right value>";
	ui_step = 1;
> = int2(0, 0);

uniform float2 fUIScale <
	ui_category = "Advanced settings";
	ui_type = "drag";
	ui_label = "Scale  (Preview)";
	ui_tooltip = "Best use 'Present type'->'Depth map' and enable 'Offset' in the options below to set the scale.\n"
	             "Use these values for:\nRESHADE_DEPTH_INPUT_X_SCALE=<left value>\nRESHADE_DEPTH_INPUT_Y_SCALE=<right value>";
	ui_min = 0.0; ui_max = 2.0;
	ui_step = 0.001;
> = float2(1.0, 1.0);

//#endif

float GetLinearizedDepth(float2 texcoord)
{
//	if (bUIUsePreprocessorDefs)
//	{
		return ReShade::GetLinearizedDepth(texcoord);
//	}

/*
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
	}*/
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
	ui_tooltip = "This shader helps you set the right preprocessor settings for depth input.\n"
	             "To set the settings click on 'Edit global preprocessor definitions' and set them there - not in this shader.\n"
	             "The settings will then take effect for all shaders, including this one.\n"  
	             "\n"
	             "By default calculated normals and depth are shown side by side.\n"
	             "Normals (on the left) should look smooth and the ground should be greenish when looking at the horizont.\n"
	             "Depth (on the right) should show close objects as dark and use gradually brighter shades the further away the objects are.\n";
>

{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DisplayDepth;
	}
}
