/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-NonCommercial-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-nc-sa/4.0/.
*/

// Chromatic Aberration PS (Prism) v1.2.5
// inspired by Marty McFly YACA shader


	  ////////////
	 /// MENU ///
	////////////

#ifndef PrismLimit
	#define PrismLimit 48 // Maximum sample count
#endif

#include "ReShadeUI.fxh"

uniform int Aberration < __UNIFORM_SLIDER_INT1
	ui_label = "Aberration scale in pixels";
	ui_min = -48; ui_max = 48;
> = 6;

uniform float Curve < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Aberration curve";
	ui_min = 0.0; ui_max = 4.0; ui_step = 0.01;
> = 1.0;

uniform bool Automatic <
	ui_label = "Automatic sample count";
	ui_tooltip = "Amount of samples will be adjusted automatically";
	ui_category = "Performance";
	ui_category_closed = true;
> = true;

uniform int SampleCount < __UNIFORM_SLIDER_INT1
	ui_label = "Samples";
	ui_tooltip = "Amount of samples (only even numbers are accepted, odd numbers will be clamped)";
	ui_min = 6; ui_max = 32;
	ui_category = "Performance";
> = 8;


	  //////////////
	 /// SHADER ///
	//////////////

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

void ChromaticAberrationPS(float4 vois : SV_Position, float2 texcoord : TexCoord, out float3 BluredImage : SV_Target)
{
	// Grab Aspect Ratio
	float Aspect = BUFFER_ASPECT_RATIO;
	// Grab Pixel V size
	float Pixel = BUFFER_RCP_HEIGHT;

	// Adjust number of samples
	// IF Automatic IS True Ceil odd numbers to even with minimum 6, else Clamp odd numbers to even
	float Samples = Automatic ? max(6.0, 2.0 * ceil(abs(Aberration) * 0.5) + 2.0) : floor(SampleCount * 0.5) * 2.0;
	// Clamp maximum sample count
	Samples = min(Samples, PrismLimit);
	// Calculate sample offset
	float Sample = 1.0 / Samples;

	// Convert UVs to centered coordinates with correct Aspect Ratio
	float2 RadialCoord = texcoord - 0.5;
	RadialCoord.x *= Aspect;

	// Generate radial mask from center (0) to the corner of the screen (1)
	float Mask = pow(2.0 * length(RadialCoord) * rsqrt(Aspect * Aspect + 1.0), Curve);

	float OffsetBase = Mask * Aberration * Pixel * 2.0;
	
	// Each loop represents one pass
	if(abs(OffsetBase) < Pixel) BluredImage = tex2D(SamplerColor, texcoord).rgb;
	else
	{
		BluredImage = 0.0;
		for (float P = 0.0; P < Samples; P++)
		{
			float Progress = P / Samples;
			float Offset = OffsetBase * (Progress - 0.5) + 1.0;
	
			// Scale UVs at center
			float2 Position = RadialCoord / Offset;
			// Convert aspect ratio back to square
			Position.x /= Aspect;
			// Convert centered coordinates to UV
			Position += 0.5;
	
			// Multiply texture sample by HUE color
			BluredImage += Spectrum(Progress) * tex2Dlod(SamplerColor, float4(Position, 0.0, 0.0)).rgb;
		}
		BluredImage *= 2.0 / Samples;
	}
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique ChromaticAberration < ui_label = "Chromatic Aberration"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPS;
	}
}
