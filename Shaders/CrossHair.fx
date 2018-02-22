/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// CrossHair PS

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float Opacity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform int Coefficients <
	ui_label = "Crosshair contrast mode";
	ui_tooltip = "YUV coefficients";
	ui_type = "combo";
	ui_items = "BT.709\0BT.601\0";
> = 0;

uniform bool Stroke <
	ui_tooltip = "Enable black stroke";
> = true;

uniform int OffsetX <
	ui_label = "Offset X";
	ui_tooltip = "Offset Crosshair horizontally in pixels";
	ui_type = "drag";
	ui_min = -16; ui_max = 16;
> = 0;

uniform int OffsetY <
	ui_label = "Offset Y";
	ui_tooltip = "Offset Crosshair vertically in pixels";
	ui_type = "drag";
	ui_min = -16; ui_max = 16;
> = 0;

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// Define CrossHair texture
texture CrossHairTex < source = "crosshair.png"; > {Width = 17; Height = 17; Format = RG8;};
sampler CrossHairSampler { Texture = CrossHairTex; };

// Draw CrossHair
float3 CrossHairPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// CrossHair texture size
	int2 Size = tex2Dsize(CrossHairSampler, 0);

	float3 StrokeColor;
	float2 Pixel = ReShade::PixelSize;
	float2 Screen = ReShade::ScreenSize;
	float2 Offset = Pixel * float2(-OffsetX, OffsetY);

	// Get behind-crosshair color
	float3 Color = tex2D(ReShade::BackBuffer, float2(0.5, 0.5) + Offset).rgb;

	float3 ToYuv[3];
	float3 ToRgb[3];
	if (Coefficients == 0) // BT.709 Matrix
	{
		// RGB to YUV
		ToYuv[0] = float3( 0.2126, 0.7152, 0.0722);
		ToYuv[1] = float3(-0.09991, -0.33609, 0.436);
		ToYuv[2] = float3( 0.615, -0.55861, -0.05639);
		// YUV to RGB
		ToRgb[0] = float3(1.000,  0.000,  1.28033);
		ToRgb[1] = float3(1.000, -0.21482, -0.38059);
		ToRgb[2] = float3(1.000,  2.12798,  0.000);
	}
	else // BT.601 Matrix
	{
		// RGB to YUV
		ToYuv[0] = float3(0.299, 0.587, 0.114);
		ToYuv[1] = float3(-0.14713, -0.28886, 0.436);
		ToYuv[2] = float3(0.615, -0.51499, -0.10001);
		// YUV to RGB
		ToRgb[0] = float3(1.000, 0.000, 1.13983);
		ToRgb[1] = float3(1.000, -0.39465, -0.58060);
		ToRgb[2] = float3(1.000, 2.03211, 0.00000);
	}

	// Convert to YUV
	Color = float3(
		Color.r * ToYuv[0].r + Color.g * ToYuv[0].g + Color.b * ToYuv[0].b,
		Color.r * ToYuv[1].r + Color.g * ToYuv[1].g + Color.b * ToYuv[1].b,
		Color.r * ToYuv[2].r + Color.g * ToYuv[2].g + Color.b * ToYuv[2].b
	);

	// Invert Luma with high-contrast gray
	Color.r = (Color.r > 0.75 || Color.r < 0.25) ? 1.0 - Color.r : Color.r > 0.5 ? 0.25 : 0.75;
	// Invert Chroma
	Color.gb *= -1.0;

	// Convert YUV to RGB
	Color = float3(
		Color.r * ToRgb[0].r + Color.g * ToRgb[0].g + Color.b * ToRgb[0].b,
		Color.r * ToRgb[1].r + Color.g * ToRgb[1].g + Color.b * ToRgb[1].b,
		Color.r * ToRgb[2].r + Color.g * ToRgb[2].g + Color.b * ToRgb[2].b
	);

	// Calculate CrossHair image coordinates relative to the center of the screen
	float2 CrossHairHalfSize = Size / Screen * 0.5;
	float2 texcoordCrossHair = (texcoord - Pixel * 0.5 + Offset - 0.5 + CrossHairHalfSize) * Screen / Size;

	// Sample display image
	float3 Display = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample CrossHair image
	float2 CrossHair = tex2D(CrossHairSampler, texcoordCrossHair).rg;
	// Color the stroke
	Color = lerp(StrokeColor, Color, CrossHair.r);
	// Opacity
	CrossHair *= Opacity;

	// Paint the crosshair
	return lerp(Display, Color, Stroke ? CrossHair.g : CrossHair.r);
}


technique CrossHair
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CrossHairPS;
	}
}
