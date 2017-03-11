/**
 * Vibrance
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Vibrance intelligently boosts the saturation of pixels so pixels that had little color get a larger boost than pixels that had a lot.
 * This avoids oversaturation of pixels that were already very saturated.
 */

uniform float Vibrance <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Intelligently saturates (or desaturates if you use negative values) the pixels depending on their original saturation.";
> = 0.15;
uniform float3 VibranceRGBBalance <
	ui_type = "drag";
	ui_min = -10; ui_max = 10;
	ui_label = "RGB Balance";
	ui_tooltip = "A per channel multiplier to the Vibrance strength so you can give more boost to certain colors over others.";
> = float3(1.0, 1.0, 1.0);

#include "ReShade.fxh"

float3 VibrancePass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
  
	const float3 coefLuma = float3(0.212656, 0.715158, 0.072186);
	float luma = dot(coefLuma, color);


	float max_color = max(color.r, max(color.g, color.b)); // Find the strongest color
	float min_color = min(color.r, min(color.g, color.b)); // Find the weakest color

	float color_saturation = max_color - min_color; // The difference between the two is the saturation

/*
	float3 sort = color;
	float2 sort1 = (sort.r > sort.g) ? sort.gr : sort.rg;
	float2 sort2 = (sort.g > sort.b) ? sort.bg : sort.gb;

	sort.gb = (sort1.g > sort2.g) ? float2(sort2.g, sort1.g) : float2(sort1.g, sort2.g); // max is now stored in .b
	sort.r = (sort1.r < sort2.r) ? sort1.r : sort2.r; // sorted : min is .r , med is .g and max is .b
	
	float color_saturation = sort.b - sort.r; // The difference between the two is the saturation
*/

/*	
	float3 sort = color;
	sort.rg = (sort.r > sort.g) ? sort.gr : sort.rg;
	sort.gb = (sort.g > sort.b) ? sort.bg : sort.gb; // max is now stored in .b
	sort.rg = (sort.r > sort.g) ? sort.gr : sort.rg; // sorted : min is .r , med is .g and max is .b
	
	float color_saturation = sort.b - sort.r; // The difference between the two is the saturation
*/

/*
	float3 sort = color;
	sort.rg = (sort.r > sort.g) ? sort.gr : sort.rg;
	sort.gb = (sort.g > sort.b) ? sort.bg : sort.gb; // max is now stored in .b
	
	float color_saturation = sort.b - min(sort.r,sort.g); // The difference between the two is the saturation
*/

	// Extrapolate between luma and original by 1 + (1-saturation) - current
	float3 coeffVibrance = float3(VibranceRGBBalance * Vibrance);
	color = lerp(luma, color, 1.0 + (coeffVibrance * (1.0 - (sign(coeffVibrance) * color_saturation))));

	return color;
}

technique Vibrance
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = VibrancePass;
	}
}
