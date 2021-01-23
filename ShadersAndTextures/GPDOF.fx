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


// GP65CJ042 DOF Settings
uniform int iGPDOFQuality < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 7;
	ui_tooltip = "0 = only slight gaussian farblur but no bokeh. 1-7 bokeh blur, higher means better quality of blur but less fps. ";
> = 6;
uniform bool bGPDOFPolygonalBokeh <
	ui_tooltip = "Enables polygonal bokeh shape, e.g. POLYGON_NUM 5 means pentagonal bokeh shape. Setting this value to false results in circular bokeh shape.";
> = true;
uniform int iGPDOFPolygonCount < __UNIFORM_SLIDER_INT1
	ui_min = 3; ui_max = 9;
	ui_tooltip = "Controls the amount pf polygons for polygonal bokeh shape. 3 = triangular, 4 = square, 5 = pentagonal etc.";
> = 5;
uniform float fGPDOFBias < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 20.0;
	ui_tooltip = "Shifts bokeh weighting to bokeh shape edge. Set to 0 for even bright bokeh shapes, raise it for darker bokeh shapes in center and brighter on edge.";
> = 10.0;
uniform float fGPDOFBiasCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 3.0;
	ui_tooltip = "Power of Bokeh Bias. Raise for more defined bokeh outlining on bokeh shape edge.";
> = 2.0;
uniform float fGPDOFBrightnessThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 2.0;
	ui_tooltip = "Threshold for bokeh brightening. Above this value, everything gets much much brighter.\n1.0 is maximum value for LDR games like GTASA, higher values work only on HDR games like Skyrim etc.";
> = 0.5;
uniform float fGPDOFBrightnessMultiplier < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Amount of brightening for pixels brighter than fGPDOFBrightnessThreshold.";
> = 2.0;
uniform float fGPDOFChromaAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.4;
	ui_tooltip = "Amount of color shifting applied on blurred areas. ";
> = 0.15;

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

// GP65CJ042 DOF
void PS_GPDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 blurcolor = tex2D(SamplerHDR1, texcoord);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = max(0.0, blurAmount - 0.1) * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	discRadius *= (centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	float3 distortion = float3(-1.0, 0.0, 1.0);
	distortion *= fGPDOFChromaAmount;

	float4 chroma1 = tex2D(SamplerHDR1, texcoord + discRadius * ReShade::PixelSize * distortion.x);
	chroma1.w = smoothstep(0.0, centerDepth, chroma1.w);
	blurcolor.x = lerp(blurcolor.x, chroma1.x, chroma1.w);

	float4 chroma2 = tex2D(SamplerHDR1, texcoord + discRadius * ReShade::PixelSize * distortion.z);
	chroma2.w = smoothstep(0.0, centerDepth, chroma2.w);
	blurcolor.z = lerp(blurcolor.z, chroma2.z, chroma2.w);

	blurcolor.w = centerDepth;
	hdr2R = blurcolor;
}
void PS_GPDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
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

	blurcolor.w = dot(blurcolor.xyz, 0.3333);
	blurcolor.w = max((blurcolor.w - fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
	blurcolor.xyz *= (1.0 + blurcolor.w * blurAmount);
	blurcolor.xyz *= lerp(1.0, 0.0, saturate(fGPDOFBias));
	blurcolor.w = 1.0;

	int sampleCycle = 0;
	int sampleCycleCounter = 0;
	int sampleCounterInCycle = 0;
	float basedAngle = 360.0 / iGPDOFPolygonCount;
	float2 currentVertex, nextVertex;

	int	dofTaps = bGPDOFPolygonalBokeh ? (iGPDOFQuality * (iGPDOFQuality + 1) * iGPDOFPolygonCount / 2.0) : (iGPDOFQuality * (iGPDOFQuality + 1) * 4);

	for (int i = 0; i < dofTaps; i++)
	{
		//dumb step incoming
		bool dothatstep = sampleCounterInCycle == 0;
		if (sampleCycle != 0)
		{
			if (sampleCounterInCycle % sampleCycle == 0)
				dothatstep = true;
		}
		//until here
		//ask yourself why so complicated? if(sampleCounterInCycle % sampleCycle == 0 ) gives warnings when sampleCycle=0
		//but it can only be 0 when sampleCounterInCycle is also 0 so it essentially is no division through 0 even if
		//the compiler believes it, it's 0/0 actually but without disabling shader optimizations this is the only way to workaround that.

		if (dothatstep)
		{
			sampleCounterInCycle = 0;
			sampleCycleCounter++;

			if (bGPDOFPolygonalBokeh)
			{
				sampleCycle += iGPDOFPolygonCount;
				currentVertex.xy = float2(1.0, 0.0);
				sincos(basedAngle* 0.017453292, nextVertex.y, nextVertex.x);
			}
			else
			{
				sampleCycle += 8;
			}
		}

		sampleCounterInCycle++;

		float2 sampleOffset;

		if (bGPDOFPolygonalBokeh)
		{
			float sampleAngle = basedAngle / float(sampleCycleCounter) * sampleCounterInCycle;
			float remainAngle = frac(sampleAngle / basedAngle) * basedAngle;

			if (remainAngle < 0.000001)
			{
				currentVertex = nextVertex;
				sincos((sampleAngle + basedAngle) * 0.017453292, nextVertex.y, nextVertex.x);
			}

			sampleOffset = lerp(currentVertex.xy, nextVertex.xy, remainAngle / basedAngle);
		}
		else
		{
			float sampleAngle = 0.78539816 / float(sampleCycleCounter) * sampleCounterInCycle;
			sincos(sampleAngle, sampleOffset.y, sampleOffset.x);
		}

		sampleOffset *= sampleCycleCounter;

		float4 tap = tex2Dlod(SamplerHDR2, float4(texcoord + sampleOffset * discRadius * ReShade::PixelSize / iGPDOFQuality, 0, 0));

		float brightMultipiler = max((dot(tap.xyz, 0.333) - fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
		tap.xyz *= 1.0 + brightMultipiler * abs(tap.w * 2.0 - 1.0);

		tap.w = (tap.w >= centerDepth * 0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0), 4.0);
		float BiasCurve = 1.0 + fGPDOFBias * pow(abs((float)sampleCycleCounter / iGPDOFQuality), fGPDOFBiasCurve);

		blurcolor.xyz += tap.xyz * tap.w * BiasCurve;
		blurcolor.w += tap.w * BiasCurve;

	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = lerp(noblurcolor.xyz, blurcolor.xyz, smoothstep(1.2, 2.0, discRadius));
}

/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique GP65CJ042DOF
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass GPDOF1 { VertexShader = PostProcessVS; PixelShader = PS_GPDOF1; RenderTarget = texHDR2; }
	pass GPDOF2 { VertexShader = PostProcessVS; PixelShader = PS_GPDOF2; /* renders to backbuffer*/ }
}
