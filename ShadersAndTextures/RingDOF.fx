//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//LICENSE AGREEMENT AND DISTRIBUTION RULES:
//1 Copyrights of the Master Effect exclusively belongs to author - Gilcher Pascal aka Marty McFly.
//2 Master Effect (the SOFTWARE) is DonateWare application, which means you may or may not pay for this software to the author as donation.
//3 If included in ENB presets, credit the author (Gilcher Pascal aka Marty McFly).
//4 Software provided "AS IS", without warranty of any kind, use it on your own risk. 
//5 You may use and distribute software in commercial or non-commercial uses. For commercial use it is required to warn about using this software (in credits, on the box or other places). Commercial distribution of software as part of the games without author permission prohibited.
//6 Author can change license agreement for new versions of the software.
//7 All the rights, not described in this license agreement belongs to author.
//8 Using the Master Effect means that user accept the terms of use, described by this license agreement.
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// For more information about license agreement contact me:
// https://www.facebook.com/MartyMcModding
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Advanced Depth of Field 4.2 by Marty McFly 
// Version for release
// Copyright © 2008-2015 Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Credits :: Matso (Matso DOF), PetkaGtA, gp65cj042
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

uniform bool DOF_AUTOFOCUS <
	ui_tooltip = "Enables automated focus recognition based on samples around autofocus center.";
> = true;
uniform bool DOF_MOUSEDRIVEN_AF <
	ui_tooltip = "Enables mouse driven auto-focus. If 1 the AF focus point is read from the mouse coordinates, otherwise the DOF_FOCUSPOINT is used.";
> = false;
uniform float2 DOF_FOCUSPOINT < __UNIFORM_SLIDER_FLOAT2
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "X and Y coordinates of autofocus center. Axes start from upper left screen corner.";
> = float2(0.5, 0.5);
uniform int DOF_FOCUSSAMPLES < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 10;
	ui_tooltip = "Amount of samples around the focus point for smoother focal plane detection.";
> = 6;
uniform float DOF_FOCUSRADIUS < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.02; ui_max = 0.20;
	ui_tooltip = "Radius of samples around the focus point.";
> = 0.05;
uniform float DOF_NEARBLURCURVE <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 1000.0;
	ui_tooltip = "Curve of blur closer than focal plane. Higher means less blur.";
> = 1.60;
uniform float DOF_FARBLURCURVE <
	ui_type = "drag";
	ui_min = 0.05; ui_max = 5.0;
	ui_tooltip = "Curve of blur behind focal plane. Higher means less blur.";
> = 2.00;
uniform float DOF_MANUALFOCUSDEPTH < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Depth of focal plane when autofocus is off. 0.0 means camera, 1.0 means infinite distance.";
> = 0.02;
uniform float DOF_INFINITEFOCUS <
	ui_type = "drag";
	ui_min = 0.01; ui_max = 1.0;
	ui_tooltip = "Distance at which depth is considered as infinite. 1.0 is standard.\nLow values only produce out of focus blur when focus object is very close to the camera. Recommended for gaming.";
> = 1.00;
uniform float DOF_BLURRADIUS <
	ui_type = "drag";
	ui_min = 2.0; ui_max = 100.0;
	ui_tooltip = "Maximal blur radius in pixels.";
> = 15.0;

// Ring DOF Settings
uniform int iRingDOFSamples < __UNIFORM_SLIDER_INT1
	ui_min = 5; ui_max = 30;
	ui_tooltip = "Samples on the first ring. The other rings around have more samples.";
> = 6;
uniform int iRingDOFRings < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 8;
	ui_tooltip = "Ring count";
> = 4;
uniform float fRingDOFThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 3.0;
	ui_tooltip = "Threshold for bokeh brightening. Above this value, everything gets much much brighter.\n1.0 is maximum value for LDR games like GTASA, higher values work only on HDR games like Skyrim etc.";
> = 0.7;
uniform float fRingDOFGain < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1; ui_max = 30.0;
	ui_tooltip = "Amount of brightening for pixels brighter than threshold.";
> = 27.0;
uniform float fRingDOFBias < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Bokeh bias";
> = 0.0;
uniform float fRingDOFFringe < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Amount of chromatic aberration";
> = 0.5;

uniform bool hasDepth < source = "bufready_depth"; >;

/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if bADOF_ImageGrainEnable
texture texNoise < source = "mcnoise.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerNoise { Texture = texNoise; };
#endif
#if bADOF_ShapeTextureEnable
texture texMask < source = "mcmask.png"; > { Width = iADOF_ShapeTextureSize; Height = iADOF_ShapeTextureSize; Format = R8; };
sampler SamplerMask { Texture = texMask; };
#endif

#define DOF_RENDERRESMULT 0.6

texture texHDR1 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; };
texture texHDR2 { Width = BUFFER_WIDTH * DOF_RENDERRESMULT; Height = BUFFER_HEIGHT * DOF_RENDERRESMULT; Format = RGBA8; }; 
sampler SamplerHDR1 { Texture = texHDR1; };
sampler SamplerHDR2 { Texture = texHDR2; };

/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform float2 MouseCoords < source = "mousepoint"; >;

float GetCoC(float2 coords)
{
	float scenedepth = ReShade::GetLinearizedDepth(coords);
	float scenefocus, scenecoc = 0.0;

	if (DOF_AUTOFOCUS)
	{
		scenefocus = 0.0;

		float2 focusPoint = DOF_MOUSEDRIVEN_AF ? MouseCoords * ReShade::PixelSize : DOF_FOCUSPOINT;

		[loop]
		for (int r = DOF_FOCUSSAMPLES; 0 < r; r--)
		{
			sincos((6.2831853 / DOF_FOCUSSAMPLES) * r, coords.y, coords.x);
			coords.y *= ReShade::AspectRatio;
			scenefocus += ReShade::GetLinearizedDepth(coords * DOF_FOCUSRADIUS + focusPoint);
		}
		scenefocus /= DOF_FOCUSSAMPLES;
	}
	else
	{
		scenefocus = DOF_MANUALFOCUSDEPTH;
	}

	scenefocus = smoothstep(0.0, DOF_INFINITEFOCUS, scenefocus);
	scenedepth = smoothstep(0.0, DOF_INFINITEFOCUS, scenedepth);

	float farBlurDepth = scenefocus * pow(4.0, DOF_FARBLURCURVE);

	if (scenedepth < scenefocus)
	{
		scenecoc = (scenedepth - scenefocus) / scenefocus;
	}
	else
	{
		scenecoc = (scenedepth - scenefocus) / (farBlurDepth - scenefocus);
		scenecoc = saturate(scenecoc);
	}

	return saturate(scenecoc * 0.5 + 0.5);
}

/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void PS_Focus(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	float4 scenecolor = tex2D(ReShade::BackBuffer, texcoord);
	scenecolor.w = GetCoC(texcoord);
	hdr1R = scenecolor;
}

// RING DOF
void PS_RingDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 scenecolor = tex2D(SamplerHDR1, texcoord);

	float centerDepth = scenecolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	float2 blurRadius = discRadius * ReShade::PixelSize / iRingDOFRings;
	scenecolor.x = tex2Dlod(SamplerHDR1, float4(texcoord + float2( 0.000,  1.0) * fRingDOFFringe * discRadius * ReShade::PixelSize, 0, 0)).x;
	scenecolor.y = tex2Dlod(SamplerHDR1, float4(texcoord + float2(-0.866, -0.5) * fRingDOFFringe * discRadius * ReShade::PixelSize, 0, 0)).y;
	scenecolor.z = tex2Dlod(SamplerHDR1, float4(texcoord + float2( 0.866, -0.5) * fRingDOFFringe * discRadius * ReShade::PixelSize, 0, 0)).z;

	scenecolor.w = centerDepth;
	hdr2R = scenecolor;
}
void PS_RingDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);
	if (!hasDepth)
	{
		blurcolor = noblurcolor;
		return;
	}
	
	blurcolor = tex2D(SamplerHDR2, texcoord);

	float centerDepth = GetCoC(texcoord);

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	if (discRadius < 1.2)
	{
		blurcolor = float4(noblurcolor.xyz, centerDepth);
		return;
	}

	blurcolor.w = 1.0;

	float s = 1.0;
	int ringsamples;

	[loop]
	for (int g = 1; g <= iRingDOFRings; g += 1)
	{
		ringsamples = g * iRingDOFSamples;

		[loop]
		for (int j = 0; j < ringsamples; j += 1)
		{
			float step = 6.283 / ringsamples;
			float2 sampleoffset = 0.0;
			sincos(j * step, sampleoffset.y, sampleoffset.x);
			float4 tap = tex2Dlod(SamplerHDR2, float4(texcoord + sampleoffset * ReShade::PixelSize * discRadius * g / iRingDOFRings, 0, 0));

			float tapluma = dot(tap.xyz, 0.333);
			float tapthresh = max((tapluma - fRingDOFThreshold) * fRingDOFGain, 0.0);
			tap.xyz *= 1.0 + tapthresh * blurAmount;

			tap.w = (tap.w >= centerDepth * 0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0), 4.0);
			tap.w *= lerp(1.0, g / iRingDOFRings, fRingDOFBias);
			blurcolor.xyz += tap.xyz * tap.w;
			blurcolor.w += tap.w;
		}
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = lerp(noblurcolor.xyz, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius)); // smooth transition between full res color and lower res blur
	blurcolor.w = centerDepth;
}

/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique RingDOF
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass RingDOF1 { VertexShader = PostProcessVS; PixelShader = PS_RingDOF1; RenderTarget = texHDR2; }
	pass RingDOF2 { VertexShader = PostProcessVS; PixelShader = PS_RingDOF2; /* renders to backbuffer*/ }
}
