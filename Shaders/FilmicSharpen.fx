/*
Filmic Sharpen PS v1.0.9 (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float Strength <
	ui_label = "Sharpen strength";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 100.0; ui_step = 0.01;
> = 60.0;

uniform int Coefficient <
	ui_label = "Luma coefficient";
	ui_tooltip = "Change if objects with relatively same brightness but different color get sharpened";
	ui_type = "combo";
	ui_items = "BT.709\0BT.601\0";
> = 0;

uniform float Clamp <
	ui_label = "Sharpen clamping";
	ui_type = "drag";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.001;
> = 0.65;

uniform float Offset <
	ui_label = "High-pass offset";
	ui_tooltip = "High-pass cross offset in pixels";
	ui_type = "drag";
	ui_min = 0.01; ui_max = 2; ui_step = 0.01;
> = 0.1;

uniform bool Preview <
	ui_label = "Preview sharpen layer";
	ui_category = "Debug View";
> = false;

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// RGB to YUV709
static const float3 ToYUV709 = float3(0.2126, 0.7152, 0.0722);
// RGB to YUV601
static const float3 ToYUV601 = float3(0.299, 0.587, 0.114);

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	float MinA = min(LayerA, 0.5);
	float MinB = min(LayerB, 0.5);
	float MaxA = max(LayerA, 0.5);
	float MaxB = max(LayerB, 0.5);
	return 2 * (MinA * MinB + MaxA + MaxB - MaxA * MaxB) - 1.5;
}

// Sharpen pass
float3 FilmicSharpenPS(float4 vois : SV_Position, float2 UvCoord : TexCoord) : SV_Target
{
	float2 Pixel = ReShade::PixelSize * Offset;
	// Sample display image
	float3 Source = tex2D(ReShade::BackBuffer, UvCoord).rgb;

	float2 NorSouWesEst[4] = {
		float2(UvCoord.x, UvCoord.y + Pixel.y),
		float2(UvCoord.x, UvCoord.y - Pixel.y),
		float2(UvCoord.x + Pixel.x, UvCoord.y),
		float2(UvCoord.x - Pixel.x, UvCoord.y)
	};

	// Choose luma coefficient, if True BT.709 Luma, else BT.601 Luma
	float3 LumaCoefficient = bool(Coefficient) ? ToYUV709 : ToYUV601;

	// Luma high-pass
	float HighPass;

	for (int s = 0; s < 4; s++)
	{
		HighPass += dot(tex2D(ReShade::BackBuffer, NorSouWesEst[s]).rgb, LumaCoefficient);
	}

	HighPass = 0.5 - 0.5 * (HighPass * 0.25 - dot(Source, LumaCoefficient));

	// Sharpen strength
	HighPass = lerp(0.5, HighPass, Strength);

	// Clamping sharpen
	HighPass = (Clamp != 1) ? max(min(HighPass, Clamp), 1 - Clamp) : HighPass;

	float3 Sharpen = float3(
		Overlay(Source.r, HighPass),
		Overlay(Source.g, HighPass),
		Overlay(Source.b, HighPass)
	);

	return (Preview) ? HighPass : Sharpen;
}

technique FilmicSharpen
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmicSharpenPS;
	}
}
