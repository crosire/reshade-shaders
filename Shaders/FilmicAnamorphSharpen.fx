/*
Filmic Anamorph Sharpen PS v1.1.10 (c) 2018 Jacob Maximilian Fober

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
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
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
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.001;
> = 0.65;

uniform float Offset <
	ui_label = "High-pass offset";
	ui_tooltip = "High-pass cross offset in pixels";
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.01;
> = 0.1;

uniform int Contrast <
	ui_label = "Edges mask";
	ui_tooltip = "Depth high-pass mask amount";
	ui_type = "drag";
	ui_min = 0; ui_max = 2000; ui_step = 1;
> = 128;

uniform bool Preview <
	ui_label = "Preview";
	ui_tooltip = "Preview sharpen layer and mask for adjustment. If you don't see red strokes, try changing Preprocessor Definitions in the Settings tab.";
	ui_category = "Debug View";
> = false;

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

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
float3 FilmicAnamorphSharpenPS(float4 vois : SV_Position, float2 UvCoord : TexCoord) : SV_Target
{
	float2 Pixel = ReShade::PixelSize;

	float2 DepthPixel = Pixel * Offset + Pixel;
	Pixel *= Offset;
	// Sample display image
	float3 Source = tex2D(ReShade::BackBuffer, UvCoord).rgb;
	// Sample display depth image
	float SourceDepth = ReShade::GetLinearizedDepth(UvCoord);

	float2 NorSouWesEst[4] = {
		float2(UvCoord.x, UvCoord.y + Pixel.y),
		float2(UvCoord.x, UvCoord.y - Pixel.y),
		float2(UvCoord.x + Pixel.x, UvCoord.y),
		float2(UvCoord.x - Pixel.x, UvCoord.y)
	};

	float2 DepthNorSouWesEst[4] = {
		float2(UvCoord.x, UvCoord.y + DepthPixel.y),
		float2(UvCoord.x, UvCoord.y - DepthPixel.y),
		float2(UvCoord.x + DepthPixel.x, UvCoord.y),
		float2(UvCoord.x - DepthPixel.x, UvCoord.y)
	};

	// Choose luma coefficient, if True BT.709 Luma, else BT.601 Luma
	float3 LumaCoefficient = (Coefficient == 0) ?
	float3( 0.2126,  0.7152,  0.0722) : float3( 0.299,  0.587,  0.114);

	// Luma high-pass color
	// Luma high-pass depth
	float HighPassColor;
	float DepthMask;

	for (int s = 0; s < 4; s++)
	{
		HighPassColor += dot(tex2D(ReShade::BackBuffer, NorSouWesEst[s]).rgb, LumaCoefficient);
		DepthMask += ReShade::GetLinearizedDepth(NorSouWesEst[s])
		+ ReShade::GetLinearizedDepth(DepthNorSouWesEst[s]);
	}

	HighPassColor = 0.5 - 0.5 * (HighPassColor * 0.25 - dot(Source, LumaCoefficient));

	DepthMask = 1.0 - DepthMask * 0.125 + SourceDepth;
	DepthMask = min(1.0, DepthMask) + 1.0 - max(1.0, DepthMask);
	DepthMask = saturate(Contrast * DepthMask + 1.0 - Contrast);

	// Sharpen strength
	HighPassColor = lerp(0.5, HighPassColor, Strength * DepthMask);

	// Clamping sharpen
	HighPassColor = max(min(HighPassColor, Clamp), 1 - Clamp);

	float3 Sharpen = float3(
		Overlay(Source.r, HighPassColor),
		Overlay(Source.g, HighPassColor),
		Overlay(Source.b, HighPassColor)
	);

	if (Preview) // Preview mode ON
	{
		float PreviewChannel = lerp(HighPassColor, HighPassColor * DepthMask, 0.5);
		return float3(
			1.0 - DepthMask * (1.0 - HighPassColor), 
			PreviewChannel, 
			PreviewChannel
		);
	}
	else
	{
		return Sharpen;
	}
}

technique FilmicAnamorphSharpen
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmicAnamorphSharpenPS;
	}
}
