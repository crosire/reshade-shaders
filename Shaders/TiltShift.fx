/* 
Tilt-Shift PS (c) 2018 Jacob Maximilian Fober, 
(based on TiltShift effect (c) 2016 kingeric1992)

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

uniform bool Line <
	ui_label = "Show Center Line";
> = false;

uniform int Axis <
	ui_label = "Angle";
	ui_type = "drag";
	ui_min = -89; ui_max = 90; ui_step = 1;
> = 0;

uniform float Offset <
	ui_type = "drag";
	ui_min = -1.41; ui_max = 1.41; ui_step = 0.01;
> = 0.05;

uniform float BlurCurve <
	ui_label = "Blur Curve";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 5.0; ui_step = 0.01;
	ui_label = "Blur Curve";
> = 1.0;
uniform float BlurMultiplier <
	ui_label = "Blur Multiplier";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 100.0; ui_step = 0.2;
	ui_label = "Blur Multiplier";
> = 6.0;

#include "ReShade.fxh"

float4 TiltShiftPass1PS(float4 vpos : SV_Position, float2 UvCoord : TexCoord) : SV_Target
{
	float4 Image = tex2D(ReShade::BackBuffer, UvCoord);
	// Grab Aspect Ratio
	float Aspect = ReShade::AspectRatio;
	// Correct Aspect Ratio
	float2 UvCoordAspect = UvCoord;
	UvCoordAspect.y += Aspect * 0.5 - 0.5;
	UvCoordAspect.y /= Aspect;
	// Center coordinates
	UvCoordAspect = UvCoordAspect * 2 - 1;
	// Tilt vector
	float2 TiltVector;
	float Angle = radians(-Axis);
	TiltVector.x = sin(Angle);
	TiltVector.y = cos(Angle);
	// Blur Mask
	float BlurMask = abs(dot(TiltVector, UvCoordAspect) + Offset);

	Image.a = pow(saturate(BlurMask), BlurCurve);
	// Image IS Red IF (Line IS True AND BlurMask < 0.01), ELSE Image IS Image
	Image.rgb = (Line && BlurMask < 0.01) ? float3(1, 0, 0) : Image.rgb;

	return Image;
}

float4 TiltShiftPass2PS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD) : SV_Target
{
	const float Weight[11] =
	{
		0.082607,
		0.080977,
		0.076276,
		0.069041,
		0.060049,
		0.050187,
		0.040306,
		0.031105,
		0.023066,
		0.016436,
		0.011254
	};

	float4 Image = tex2D(ReShade::BackBuffer, UvCoord);
	float BlurAmount = Image.a * BlurMultiplier;
	Image.rgb *= Weight[0];

	float UvOffset = ReShade::PixelSize.x * BlurAmount;
	for (int i = 1; i < 11; i++)
	{
		Image.rgba += tex2D(ReShade::BackBuffer, UvCoord.xy + float2(i * UvOffset, 0)).rgba * Weight[i];
		Image.rgba += tex2D(ReShade::BackBuffer, UvCoord.xy - float2(i * UvOffset, 0)).rgba * Weight[i];
	}

	return Image;
}

float3 TiltShiftPass3PS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD) : SV_Target
{
	const float Weight[11] =
	{
		0.082607,
		0.080977,
		0.076276,
		0.069041,
		0.060049,
		0.050187,
		0.040306,
		0.031105,
		0.023066,
		0.016436,
		0.011254
	};

	float4 Image = tex2D(ReShade::BackBuffer, UvCoord);
	float BlurAmount = Image.a * BlurMultiplier;
	Image.rgb *= Weight[0];

	float UvOffset = ReShade::PixelSize.y * BlurAmount;
	for (int i = 1; i < 11; i++)
	{
		Image.rgb += tex2D(ReShade::BackBuffer, UvCoord.xy + float2(0, i * UvOffset)).rgb * Weight[i];
		Image.rgb += tex2D(ReShade::BackBuffer, UvCoord.xy - float2(0, i * UvOffset)).rgb * Weight[i];
	}

	return Image.rgb;
}

technique TiltShift
{
	pass CircleOfConfusionToAlpha
	{
		VertexShader = PostProcessVS;
		PixelShader = TiltShiftPass1PS;
	}
	pass HorizontalGaussianBlur
	{
		VertexShader = PostProcessVS;
		PixelShader = TiltShiftPass2PS;
	}
	pass VerticalGaussianBlur
	{
		VertexShader = PostProcessVS;
		PixelShader = TiltShiftPass3PS;
	}
}
