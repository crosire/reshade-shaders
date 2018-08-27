/**
 * Monochrome
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Monochrome removes color and makes everything black and white.
 */

#include "ReShade.fxh"

uniform int Monochrome_preset <
	ui_type = "combo";
	ui_label = "Preset";
	ui_tooltip = "Choose a preset";
	//ui_category = "";
	ui_items = "Custom\0Monitor or modern TV\0Equal weight\0Agfa 200X\0Agfapan 25\0Agfapan 100\0Agfapan 400\0Ilford Delta 100\0Ilford Delta 400\0Ilford Delta 400 Pro & 3200\0Ilford FP4\0Ilford HP5\0Ilford Pan F\0Ilford SFX\0Ilford XP2 Super\0Kodak Tmax 100\0Kodak Tmax 400\0Kodak Tri-X\0";
> = 0;

uniform float3 Custom_Coefficients <
	ui_type = "color";
	ui_label = "Custom Coefficients";
> = float3(0.21, 0.72, 0.07);

/*
uniform bool Normalize <
	ui_label = "Normalize";
	ui_tooltip = "Normalize the coefficients?";
> = false;
*/

uniform float ColorSaturation <
	ui_label = "Saturation";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

float3 MonochromePass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 Coefficients = float3(0.21, 0.72, 0.07);
	if (Monochrome_preset == 0) Coefficients = Custom_Coefficients; //Custom
	if (Monochrome_preset == 1)	Coefficients = float3(0.21, 0.72, 0.07); //sRGB monitor
	if (Monochrome_preset == 2)	Coefficients = float3(0.3333333, 0.3333334, 0.3333333); //Equal weight
	if (Monochrome_preset == 3)	Coefficients = float3(0.18, 0.41, 0.41); //Agfa 200X
	if (Monochrome_preset == 4)	Coefficients = float3(0.25, 0.39, 0.36); //Agfapan 25
	if (Monochrome_preset == 5)	Coefficients = float3(0.21, 0.40, 0.39); //Agfapan 100
	if (Monochrome_preset == 6)	Coefficients = float3(0.20, 0.41, 0.39); //Agfapan 400 
	if (Monochrome_preset == 7)	Coefficients = float3(0.21, 0.42, 0.37); //Ilford Delta 100
	if (Monochrome_preset == 8)	Coefficients = float3(0.22, 0.42, 0.36); //Ilford Delta 400
	if (Monochrome_preset == 9)	Coefficients = float3(0.31, 0.36, 0.33); //Ilford Delta 400 Pro & 3200
	if (Monochrome_preset == 10) Coefficients = float3(0.28, 0.41, 0.31); //Ilford FP4
	if (Monochrome_preset == 11) Coefficients = float3(0.23, 0.37, 0.40); //Ilford HP5
	if (Monochrome_preset == 12) Coefficients = float3(0.33, 0.36, 0.31); //Ilford Pan F
	if (Monochrome_preset == 13) Coefficients = float3(0.36, 0.31, 0.33); //Ilford SFX
	if (Monochrome_preset == 14) Coefficients = float3(0.21, 0.42, 0.37); //Ilford XP2 Super
	if (Monochrome_preset == 15) Coefficients = float3(0.24, 0.37, 0.39); //Kodak Tmax 100
	if (Monochrome_preset == 16) Coefficients = float3(0.27, 0.36, 0.37); //Kodak Tmax 400
	if (Monochrome_preset == 17) Coefficients = float3(0.25, 0.35, 0.40); //Kodak Tri-X

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
