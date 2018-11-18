/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Perfect Perspective PS ver. 2.4.0

  ////////////////////
 /////// MENU ///////
////////////////////

#ifndef ShaderAnalyzer
uniform int FOV <
	ui_label = "Corrected Field of View";
	ui_tooltip = "This setting should match \n
		"your in-game Field of View";
	ui_type = "drag";
	ui_min = 45; ui_max = 120; ui_step = 0.2;
	ui_category = "Distortion Correction";
> = 90;

uniform float Vertical <
	ui_label = "Vertical Curviness Amount";
	ui_tooltip = "1  -  Spherical projection \n"
		"0  -  Cylindrical projection";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_category = "Distortion Correction";
> = 0.5;

uniform int Type <
	ui_label = "Type of FOV (Field of View)";
	ui_tooltip = "If the image bulges in movement (too high FOV), \n
		"change it to 'Diagonal'.\n"
		"When proportions are distorted at the periphery \n
		"(too low FOV), choose 'Vertical'";
	ui_type = "combo";
	ui_items = "Horizontal FOV\0Diagonal FOV\0Vertical FOV\0";
	ui_category = "Distortion Correction";
> = 0;

uniform float Zooming <
	ui_label = "Borders Scale";
	ui_tooltip = "Adjust image scale to see cropped areas";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 3.0; ui_step = 0.001;
	ui_category = "Borders Settings";
> = 1.0;

uniform float4 Color <
	ui_label = "Color of Borders";
	ui_tooltip = "Use Alpha to adjust opacity";
	ui_type = "Color";
	ui_category = "Borders Settings";
> = float4(0.027, 0.027, 0.027, 0.0);

uniform bool Borders <
	ui_label = "Mirrored Borders";
	ui_tooltip = "Choose between original or mirrored\n"
		"image at the borders";
	ui_category = "Borders Settings";
> = true;

uniform bool Debug <
	ui_label = "Display Resolution Scale Map";
	ui_tooltip = "Color map of the Resolution Scale \n"
		" Red    -  Undersampling \n"
		" Green  -  Supersampling \n"
		" Blue   -  Neutral sampling";
	ui_category = "Debug Tools";
> = false;

uniform int2 ResScale <
	ui_label = "D.S.R. Scale Factor";
	ui_tooltip = "Dynamic Super Resolution (DSR), \n"
		"simulates application running beyond\n"
		"native screen resolution\n"
		"\n"
		"First Value - Native Screen Resolution\n"
		"Second Value - D.S.R. Scaled Resolution";
	ui_type = "drag";
	ui_min = 16; ui_max = 16384; ui_step = 0.2;
	ui_category = "Debug Tools";
> = int2(1920, 1920);
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
	// Get Screen Pixel Size
	float2 ScrPixelSize = ReShade::PixelSize;

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

	// Get Pixel Size in stereographic coordinates
	float2 PixelSize = fwidth(SphCoord);

	// Outside borders check with Anti-Aliasing
	float2 AtBorders = smoothstep( 1 - PixelSize, PixelSize + 1, abs(SphCoord) );

	// Back to UV Coordinates
	SphCoord = SphCoord * 0.5 + 0.5;

	// Sample display image
	float3 Display = tex2D(SamplerColor, SphCoord).rgb;

	// Mask outside-border pixels or mirror
	Display = lerp(
		Display, 
		lerp(
			Borders ? Display : tex2D(SamplerColor, texcoord).rgb, 
			Color.rgb, 
			Color.a
		), 
		max(AtBorders.x, AtBorders.y)
	);

	// Output type choice
	if (Debug)
	{
		// Calculate radial screen coordinates before and after perspective transformation
		float4 RadialCoord = float4(texcoord, SphCoord) * 2 - 1;
		// Correct vertical aspect ratio
		RadialCoord.yw *= AspectR;

		// Define Mapping color
		float3 UnderSmpl = float3(1, 0, 0.2); // Red
		float3 SuperSmpl = float3(0, 1, 0.5); // Green
		float3 NeutralSmpl = float3(0, 0.5, 1); // Blue

		// Calculate Pixel Size difference...
		float PixelScale = fwidth( length(RadialCoord.xy) );
		// ...and simulate Dynamic Super Resolution (DSR) scalar
		PixelScale /= float(ResScale.y) / float(ResScale.x) * fwidth( length(RadialCoord.zw) );
		PixelScale -= 1;

		// Generate supersampled-undersampled color map
		float3 ResMap = lerp(
			SuperSmpl,
			UnderSmpl,
			saturate(ceil(PixelScale))
		);

		// Create black-white gradient mask of scale-neutral pixels
		PixelScale = 1 - abs(PixelScale);
		PixelScale = saturate(PixelScale * 4 - 3); // Clamp to more representative values

		// Color neutral scale pixels
		ResMap = lerp(ResMap, NeutralSmpl, PixelScale);

		// Blend color map with display image
		Display = normalize(ResMap) * (0.8 * max( max(Display.r, Display.g), Display.b ) + 0.2);
	}

	return Display;
}

technique PerfectPerspective
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PerfectPerspectivePS;
	}
}
