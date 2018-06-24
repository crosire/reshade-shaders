/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Perfect Perspective PS ver. 2.2.7

  ////////////////////
 /////// MENU ///////
////////////////////

#ifndef ShaderAnalyzer
uniform int FOV <
	ui_label = "Field of View";
	ui_tooltip = "Match in-game Field of View";
	ui_type = "drag";
	ui_min = 45; ui_max = 120;
	ui_category = "Distortion";
> = 90;

uniform float Vertical <
	ui_label = "Vertical Amount";
	ui_tooltip = "0.0 - cylindrical projection, 1.0 - spherical";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_category = "Distortion";
> = 0.618;

uniform int Type <
	ui_label = "Type of FOV";
	ui_tooltip = "If image bulges in movement, change it to Diagonal. When proportions are distorted, choose Vertical";
	ui_type = "combo";
	ui_items = "Horizontal FOV\0Diagonal FOV\0Vertical FOV\0";
	ui_category = "Distortion";
> = 0;

uniform float4 Color <
	ui_label = "Color";
	ui_tooltip = "Use Alpha to adjust opacity";
	ui_type = "Color";
	ui_category = "Borders";
> = float4(0.027, 0.027, 0.027, 0.902);

uniform bool Borders <
	ui_label = "Mirrored Borders";
	ui_category = "Borders";
> = true;

uniform float Zooming <
	ui_label = "Border Scale";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 3.0; ui_step = 0.001;
	ui_category = "Borders";
> = 1.0;
#endif

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// Define screen texture with mirror tiles
sampler SamplerColor
{
	Texture = ReShade::BackBufferTex;
	AddressU = MIRROR;
	AddressV = MIRROR;
};

// Stereographic-Gnomonic lookup function by Jacob Max Fober
// Input data:
	// FOV >> Camera Field of View in degrees
	// Coordinates >> UV coordinates (from -1, to 1), where (0,0) is at the center of the screen
float Formula(float2 Coordinates)
{
	// Convert 1/4 FOV to radians and calc tangent squared
	float SqrTanFOVq = tan(radians(float(FOV) * 0.25));
	SqrTanFOVq *= SqrTanFOVq;
	return (1.0 - SqrTanFOVq) / (1.0 - SqrTanFOVq * dot(Coordinates, Coordinates));
}

// Shader pass
float3 PerfectPerspectivePS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Get Aspect Ratio
	float AspectR = 1.0 / ReShade::AspectRatio;

	// Convert FOV type..
	float FovType = (Type == 1) ? sqrt(AspectR * AspectR + 1.0) : Type == 2 ? AspectR : 1.0;

	// Convert UV to Radial Coordinates
	float2 SphCoord = texcoord * 2.0 - 1.0;
	// Aspect Ratio correction
	SphCoord.y *= AspectR;
	// Zoom in image and adjust FOV type (pass 1 of 2)
	SphCoord *= Zooming / FovType;

	// Stereographic-Gnomonic lookup, vertical distortion amount and FOV type (pass 2 of 2)
	SphCoord *= Formula(float2(SphCoord.x, sqrt(Vertical) * SphCoord.y)) * FovType;

	// Aspect Ratio back to square
	SphCoord.y /= AspectR;

	// Get Pixel Size in steregoraphic coordinates
	float2 PixelSize = fwidth(SphCoord);

	// Outside borders check with Anti-Aliasing
	float2 AtBorders = smoothstep( 1 - PixelSize, PixelSize + 1, abs(SphCoord) );

	// Back to UV Coordinates
	SphCoord = SphCoord * 0.5 + 0.5;

	// Sample display image
	float3 Display = tex2D(SamplerColor, SphCoord).rgb;

	// Mask outside-border pixels or mirror
	return lerp(
		Display, 
		lerp(
			Borders ? Display : tex2D(SamplerColor, texcoord).rgb, 
			Color.rgb, 
			Color.a
		), 
		max(AtBorders.x, AtBorders.y)
	);
}

technique PerfectPerspective
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PerfectPerspectivePS;
	}
}
