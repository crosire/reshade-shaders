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

// MATSO DOF Settings
uniform bool bMatsoDOFChromaEnable <
	ui_tooltip = "Enables chromatic aberration.";
> = true;
uniform float fMatsoDOFChromaPow < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.2; ui_max = 3.0;
	ui_tooltip = "Amount of chromatic aberration color shifting.";
> = 1.4;
uniform float fMatsoDOFBokehCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.5; ui_max = 20.0;
	ui_tooltip = "Bokeh curve";
> = 8.0;
uniform int iMatsoDOFBokehQuality < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 10;
	ui_tooltip = "Blur quality as control value over tap count.";
> = 2;
uniform float fMatsoDOFBokehAngle < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0; ui_max = 360; ui_step = 1;
	ui_tooltip = "Rotation angle of bokeh shape.";
> = 0;

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

// MATSO DOF
float4 GetMatsoDOFCA(sampler col, float2 tex, float CoC)
{
	float3 chroma = pow(float3(0.5, 1.0, 1.5), fMatsoDOFChromaPow * CoC);

	float2 tr = ((2.0 * tex - 1.0) * chroma.r) * 0.5 + 0.5;
	float2 tg = ((2.0 * tex - 1.0) * chroma.g) * 0.5 + 0.5;
	float2 tb = ((2.0 * tex - 1.0) * chroma.b) * 0.5 + 0.5;
	
	float3 color = float3(tex2Dlod(col, float4(tr,0,0)).r, tex2Dlod(col, float4(tg,0,0)).g, tex2Dlod(col, float4(tb,0,0)).b) * (1.0 - CoC);
	
	return float4(color, 1.0);
}
float4 GetMatsoDOFBlur(int axis, float2 coord, sampler SamplerHDRX)
{
	float4 blurcolor = tex2D(SamplerHDRX, coord.xy);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0;

	blurcolor = 0.0;

	const float2 tdirs[4] = { 
		float2(-0.306,  0.739),
		float2( 0.306,  0.739),
		float2(-0.739,  0.306),
		float2(-0.739, -0.306)
	};

	for (int i = -iMatsoDOFBokehQuality; i < iMatsoDOFBokehQuality; i++)
	{
		float2 taxis =  tdirs[axis];

		taxis.x = cos(fMatsoDOFBokehAngle * 0.0175) * taxis.x - sin(fMatsoDOFBokehAngle * 0.0175) * taxis.y;
		taxis.y = sin(fMatsoDOFBokehAngle * 0.0175) * taxis.x + cos(fMatsoDOFBokehAngle * 0.0175) * taxis.y;
		
		float2 tcoord = coord.xy + (float)i * taxis * discRadius * ReShade::PixelSize * 0.5 / iMatsoDOFBokehQuality;

		float4 ct = bMatsoDOFChromaEnable ? GetMatsoDOFCA(SamplerHDRX, tcoord.xy, discRadius * ReShade::PixelSize.x * 0.5 / iMatsoDOFBokehQuality) : tex2Dlod(SamplerHDRX, float4(tcoord.xy, 0, 0));

		// my own pseudo-bokeh weighting
		float b = dot(ct.rgb, 0.333) + length(ct.rgb) + 0.1;
		float w = pow(abs(b), fMatsoDOFBokehCurve) + abs((float)i);

		blurcolor.xyz += ct.xyz * w;
		blurcolor.w += w;
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.w = centerDepth;
	return blurcolor;
}

void PS_MatsoDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(2, texcoord, SamplerHDR1);	
}
void PS_MatsoDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	hdr1R = GetMatsoDOFBlur(3, texcoord, SamplerHDR2);	
}
void PS_MatsoDOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(0, texcoord, SamplerHDR1);	
}
void PS_MatsoDOF4(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 blurcolor : SV_Target)
{
	float4 noblurcolor = tex2D(ReShade::BackBuffer, texcoord);
	if (!hasDepth)
	{
		blurcolor = noblurcolor;
		return;
	}
	
	blurcolor = GetMatsoDOFBlur(1, texcoord, SamplerHDR2);
	float centerDepth = GetCoC(texcoord); //fullres coc data

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 

	//not 1.2 - 2.0 because matso's has a weird bokeh weighting that is almost like a tonemapping and border between blur and no blur appears to harsh
	blurcolor.xyz = lerp(noblurcolor.xyz,blurcolor.xyz,smoothstep(0.2,2.0,discRadius)); 
}

/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique MatsoDOF
{
	pass Focus { VertexShader = PostProcessVS; PixelShader = PS_Focus; RenderTarget = texHDR1; }
	pass MatsoDOF1 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF1; RenderTarget = texHDR2; }
	pass MatsoDOF2 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF2; RenderTarget = texHDR1; }
	pass MatsoDOF3 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF3; RenderTarget = texHDR2; }
	pass MatsoDOF4 { VertexShader = PostProcessVS; PixelShader = PS_MatsoDOF4; /* renders to backbuffer*/ }
}
