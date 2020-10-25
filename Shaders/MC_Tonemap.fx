/*
 	Tonemap by Constantine 'MadCake' Rudenko

 	License: https://creativecommons.org/licenses/by/4.0/
	CC BY 4.0
	
	You are free to:

	Share — copy and redistribute the material in any medium or format
		
	Adapt — remix, transform, and build upon the material
	for any purpose, even commercially.

	The licensor cannot revoke these freedoms as long as you follow the license terms.
		
	Under the following terms:

	Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. 
	You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

	No additional restrictions — You may not apply legal terms or technological measures 
	that legally restrict others from doing anything the license permits.
*/

#include "ReShadeUI.fxh"

uniform float Contrast < __UNIFORM_DRAG_FLOAT1
	ui_min = 1.0; ui_max = 16.0; ui_step = 0.01;
	ui_tooltip = "Increases contrast in the middle of the visible brightness range at the expense of shadows and highlights.";
	ui_label = "Contrast";
> = 1.0;

uniform float Compression < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.001; ui_max = 16.0; ui_step = 0.01;
	ui_tooltip = "Compress highlights";
	ui_label = "Compression";
> = 0.00001;

uniform float BlackLevel < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.0025;
	ui_tooltip = "Subtract this value from final result to compensate for monitor's diffuse reflection";
	ui_label = "Black Level";
> = 0.00001;

uniform bool DeGamma <
	ui_label = "DeGamma";
	ui_tooltip = "Assume that colors are stored in gamma space";
> = false;

uniform float Exposure < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.05;
	ui_tooltip = "Exposure";
	ui_label = "Exposure";
> = 1.0;

/*
uniform int BlackPoint < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 255;
	ui_label = "Black Point";
	ui_tooltip = "The black point is the new black - literally. Everything darker than this will become completely black.";
> = 16;

uniform bool HighlightClipping <
	ui_label = "Highlight clipping pixels";
	ui_tooltip = "Colors between the two points will stretched, which increases contrast, but details above and below the points are lost (this is called clipping).\n"
		"This setting marks the pixels that clip.\n"
		"Red: Some detail is lost in the highlights\n"
		"Yellow: All detail is lost in the highlights\n"
		"Blue: Some detail is lost in the shadows\n"
		"Cyan: All detail is lost in the shadows.";
> = false;
*/

#include "ReShade.fxh"

float3 MadCakeToneMapPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	if (DeGamma)
	{
		color.rgb = pow(color.rgb, 0.45454545);
	}
	
	color = color * Exposure;
	
	float r = 1.0 / Compression;
	float a_mid = pow(0.5, Contrast - (Contrast - 1.0) * 0.5);
	float r_fix = - (a_mid * r) / (-1.0 + a_mid - r + 2 * a_mid * r);
	
	color.r = pow(color.r, Contrast - (Contrast - 1.0) * color.r);
	color.g = pow(color.g, Contrast - (Contrast - 1.0) * color.g);
	color.b = pow(color.b, Contrast - (Contrast - 1.0) * color.b);
	
	color.r = color.r * (r_fix + 1.0) / (color.r + r_fix);
	color.g = color.g * (r_fix + 1.0) / (color.g + r_fix);
	color.b = color.b * (r_fix + 1.0) / (color.b + r_fix);
	
	if (DeGamma)
	{
		color.rgb = pow(color.rgb, 2.2);
	}
	
	color.rgb = color.rgb - BlackLevel;

	return color;
}

technique MC_ToneMap
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MadCakeToneMapPass;
	}
}
