/**
 * Monochrome
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Monochrome removes color and makes everything black and white.
 */

uniform float3 Coefficients <
	ui_type = "color";
> = float3(0.21, 0.72, 0.07);
uniform float ColorSaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

#include "ReShade.fxh"

float3 MonochromePass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	// Calculate monochrome
	float3 grey = dot(Coefficients, color);

	// Adjust the remaining saturation
	color = lerp(grey, color, ColorSaturation);

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
