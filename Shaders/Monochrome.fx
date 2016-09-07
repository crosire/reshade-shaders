/**
 * Monochrome
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Monochrome removes color and makes everything black and white.
 */

uniform float3 Monochrome_conversion_values <
	ui_type = "color";
> = float3(0.21, 0.72, 0.07);
uniform float Monochrome_color_saturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

#include "ReShade.fxh"

float4 MonochromePass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);

	// Calculate monochrome
	float3 grey = dot(Monochrome_conversion_values, color.rgb);

	// Adjust the remaining saturation
	color.rgb = lerp(grey, color.rgb, Monochrome_color_saturation);

	// Return the result
	return saturate(color);
}

technique Monochrome
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MonochromePass;
	}
}
