/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-NonCommercial-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-nc-sa/4.0/.
*/

// Chromatic Aberration PS (Prism) v1.2.1
// inspired by Marty McFly YACA shader

  ////////////////////
 /////// MENU ///////
////////////////////

#ifndef ShaderAnalyzer

uniform int Aberration <
	ui_label = "Aberration scale in pixels";
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = -48; ui_max = 48;
> = 6;

uniform float Curve <
	ui_label = "Aberration curve";
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = 0.0; ui_max = 4.0; ui_step = 0.01;
> = 1.0;

uniform bool Automatic <
	ui_label = "Automatic sample count";
	ui_tooltip = "Amount of samples will be adjusted automatically";
	ui_category = "Performance";
> = true;

uniform int SampleCount <
	ui_label = "Samples";
	ui_tooltip = "Amount of samples (only even numbers are accepted, odd numbers will be clamped)";
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = 6; ui_max = 32;
	ui_category = "Performance";
> = 8;

#endif

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// Special Hue generator by JMF
float3 Spectrum(float Hue)
{
	float Hue4 = Hue * 4.0;
	float3 HueColor = abs(Hue4 - float3(1.0, 2.0, 1.0));
	HueColor = saturate(1.5 - HueColor);
	HueColor.xz += saturate(Hue4 - 3.5);
	HueColor.z = 1.0 - HueColor.z;
	return HueColor;
}

// Define screen texture with mirror tiles
sampler SamplerColor
{
	Texture = ReShade::BackBufferTex;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

void ChromaticAberrationPS(float4 vois : SV_Position, float2 texcoord : TexCoord,
out float3 BluredImage : SV_Target)
{
	// Grab Aspect Ratio
	float Aspect = ReShade::AspectRatio;
	// Grab Pixel V size
	float Pixel = ReShade::PixelSize.y;

	// Adjust number of samples
	// IF Automatic IS True Ceil odd numbers to even with minimum 6, else Clamp odd numbers to even
	int Samples = Automatic ? max(6, 2 * ceil(abs(Aberration) * 0.5) + 2) : floor(SampleCount * 0.5) * 2;
	// Clamp maximum sample count
	Samples = min(Samples, 48);

	// Convert UVs to radial coordinates with correct Aspect Ratio
	float2 RadialCoord = texcoord * 2.0 - 1.0;
	RadialCoord.x *= Aspect;

	// Generate radial mask from center (0) to the corner of the screen (1)
	float Mask = pow(length(RadialCoord) * rsqrt(Aspect * Aspect + 1.0), Curve);

	float OffsetBase = Mask * Aberration * Pixel * 2.0;
	
	// Each loop represents one pass
	if (abs(OffsetBase) < Pixel)
	{
		BluredImage = tex2D(SamplerColor, texcoord).rgb;
	}
	else
	{
		for (int P = 0; P < Samples && P <= 48; P++)
		{
			// Calculate current sample
			float CurrentProgress = float(P) / float(Samples);

			float Offset = OffsetBase * (CurrentProgress - 0.5) + 1.0;

			// Scale UVs at center
			float2 Position = RadialCoord / Offset;
			// Convert aspect ratio back to square
			Position.x /= Aspect;
			// Convert radial coordinates to UV
			Position = Position * 0.5 + 0.5;

			// Multiply texture sample by HUE color
			BluredImage += Spectrum(CurrentProgress) * tex2Dlod(SamplerColor, float4(Position, 0, 0)).rgb;
		}
		BluredImage = BluredImage / Samples * 2.0;
	}
}

technique ChromaticAberration
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPS;
	}
}
