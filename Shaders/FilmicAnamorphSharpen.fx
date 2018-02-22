/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Filmic Anamorph Sharpen PS

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float Strength <
	ui_label = "Sharpen strength";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 3.0; ui_step = 0.005;
> = 1.0;

uniform bool Preview <
	ui_label = "Preview";
	ui_tooltip = "Preview sharpen layer and mask for adjustment";
> = false;

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
> = 1.0;

uniform int Offset <
	ui_label = "High-pass offset";
	ui_tooltip = "High-pass cross offset in pixels";
	ui_type = "drag";
	ui_min = 0; ui_max = 2;
> = 1;

uniform int Contrast <
	ui_label = "Edges mask";
	ui_tooltip = "Depth high-pass mask amount";
	ui_type = "drag";
	ui_min = 0; ui_max = 2000; ui_step = 1;
> = 1618;

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	float MinA = min(LayerA, 0.5) * 2;
	float MinB = min(LayerB, 0.5) * 2;

	float MaxA = 1 - (max(LayerA, 0.5) * 2 - 1);
	float MaxB = 1 - (max(LayerB, 0.5) * 2 - 1);

	float Result = (MinA * MinB + 1 - MaxA * MaxB) * 0.5;
	return Result;
}

// Convert RGB to YUV.luma
float Luma(float3 Source, float3 Coefficients)
{
	float3 Result = Source * Coefficients;
	return Result.r + Result.g + Result.b;
}

// Define screen texture with mirror tiles
texture TexColorBuffer : COLOR;
sampler SamplerColor
{
	Texture = TexColorBuffer;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

// Define depth texture with mirror tiles
texture TexDepthBuffer : DEPTH;
sampler SamplerDepth
{
	Texture = TexDepthBuffer;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

// Sharpen pass
float3 FilmicAnamorphSharpenPS(float4 vois : SV_Position, float2 UvCoord : TexCoord) : SV_Target
{
	float2 Pixel = ReShade::PixelSize;

	float2 DepthPixel = Pixel * float(Offset + 1);
	Pixel *= float(Offset);
	// Sample display image
	float3 Source = tex2D(SamplerColor, UvCoord).rgb;
	// Sample display depth image
	float SourceDepth = tex2D(SamplerDepth, UvCoord).r;

	float2 North = float2(UvCoord.x, UvCoord.y + Pixel.y);
	float2 South = float2(UvCoord.x, UvCoord.y - Pixel.y);
	float2 West = float2(UvCoord.x + Pixel.x, UvCoord.y);
	float2 East = float2(UvCoord.x - Pixel.x, UvCoord.y);

	float2 DepthNorth = float2(UvCoord.x, UvCoord.y + DepthPixel.y);
	float2 DepthSouth = float2(UvCoord.x, UvCoord.y - DepthPixel.y);
	float2 DepthWest = float2(UvCoord.x + DepthPixel.x, UvCoord.y);
	float2 DepthEast = float2(UvCoord.x - DepthPixel.x, UvCoord.y);

	// Choose luma coefficient, if True BT.709 Luma, else BT.601 Luma
	float3 LumaCoefficient = (Coefficient == 0) ? float3( 0.2126,  0.7152,  0.0722) : float3( 0.299,  0.587,  0.114);

	// Luma high-pass color
	float HighPassColor;
	HighPassColor  = Luma(tex2D(SamplerColor, North).rgb, LumaCoefficient);
	HighPassColor += Luma(tex2D(SamplerColor, South).rgb, LumaCoefficient);
	HighPassColor += Luma(tex2D(SamplerColor, West).rgb, LumaCoefficient);
	HighPassColor += Luma(tex2D(SamplerColor, East).rgb, LumaCoefficient);
	HighPassColor *= 0.25;
	HighPassColor = 1 - HighPassColor;
	HighPassColor = (HighPassColor + Luma(Source, LumaCoefficient)) * 0.5;
	
	// Luma high-pass depth
	float DepthMask;
	DepthMask  = tex2D(SamplerDepth, DepthNorth).r;
	DepthMask += tex2D(SamplerDepth, DepthSouth).r;
	DepthMask += tex2D(SamplerDepth, DepthWest).r;
	DepthMask += tex2D(SamplerDepth, DepthEast).r;
	DepthMask += tex2D(SamplerDepth, North).r;
	DepthMask += tex2D(SamplerDepth, South).r;
	DepthMask += tex2D(SamplerDepth, West).r;
	DepthMask += tex2D(SamplerDepth, East).r;
	DepthMask *= 0.125;

	DepthMask = 1.0 - DepthMask;
	DepthMask = (DepthMask + SourceDepth);
	DepthMask = min(1.0, DepthMask) + 1.0 - max(1.0, DepthMask);
	DepthMask = 1.0 - Contrast * (1.0 - DepthMask);
	DepthMask = saturate(DepthMask);

	// Sharpen strength
	HighPassColor = lerp(0.5, HighPassColor, Strength * DepthMask);

	// Clamping sharpen
	HighPassColor = min(HighPassColor, Clamp);
	HighPassColor = max(HighPassColor, 1 - Clamp);

	float3 Sharpen;
	Sharpen.r = Overlay(Source.r, HighPassColor);
	Sharpen.g = Overlay(Source.g, HighPassColor);
	Sharpen.b = Overlay(Source.b, HighPassColor);

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
