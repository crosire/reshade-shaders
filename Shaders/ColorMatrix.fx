/**
 * Color Matrix version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * ColorMatrix allow the user to transform the colors using a color matrix
 */

uniform float3 ColorMatrix_Red <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Red";
	ui_tooltip = "How much of Red, Green and Blue the new red value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.817, 0.183, 0.000);
uniform float3 ColorMatrix_Green <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Green";
	ui_tooltip = "How much of Red, Green and Blue the new green value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.333, 0.667, 0.000);
uniform float3 ColorMatrix_Blue <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Blue";
	ui_tooltip = "How much of Red, Green and Blue the new blue value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.000, 0.125, 0.875);

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

#include "ReShade.fxh"

float3 ColorMatrixPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float3x3 ColorMatrix = float3x3(ColorMatrix_Red, ColorMatrix_Green, ColorMatrix_Blue);
	color = lerp(color, mul(ColorMatrix, color), Strength);

	return saturate(color);
}

technique ColorMatrix
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ColorMatrixPass;
	}
}
