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
//For more information about license agreement contact me:
//https://www.facebook.com/MartyMcModding
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Copyright (c) 2009-2015 Gilcher Pascal aka Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Credits :: prod80 (for some ideas, color hue fx, 3 strip technicolor)
//Credits :: Ubisoft (Reinhard tonemapping, Haarm Peter Duiker Tonemap, Filmiccurve, Spherical Tonemap)
//Credits :: Ryosuke (Colormod Contrast/Gamma/Saturation controls)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include EFFECT_CONFIG(MartyMcFly)
#include "Common.fx"

#if USE_LUT || USE_SKYRIMTONEMAP || USE_TECHNICOLOR || USE_COLORMOOD || USE_CROSSPROCESS || USE_REINHARD || USE_COLORMOD || USE_SPHERICALTONEMAP || USE_HPD || USE_FILMICCURVE || USE_WATCHDOG_TONEMAP || USE_SINCITY || USE_COLORHUEFX

#pragma message "Various Color Correction Effects by prod80, Ubisoft, Ryosuke and Marty McFly\n"

namespace MartyMcFly
{
namespace ColorCorrection
{

#define LumCoeff 	float3(0.212656, 0.715158, 0.072186)

#if USE_LUT
texture   texLUT    < string source = "ReShade/Shaders/MartyMcFly/Textures/mclut.png"; > {Width = 256; Height = 1; Format = RGBA8;};

sampler2D SamplerLUT
{
	Texture = texLUT;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
#endif

float smootherstep(float edge0, float edge1, float x)
{
   	x = clamp((x - edge0)/(edge1 - edge0), 0.0, 1.0);
   	return x*x*x*(x*(x*6 - 15) + 10);
}

float3 Hue(in float3 RGB)
{
   	// Based on work by Sam Hocevar and Emil Persson
   	float Epsilon = 1e-10;
   	float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
   	float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
   	float C = Q.x - min(Q.w, Q.y);
   	float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
   	return float3(H, C, Q.x);
}

float3 TechniPass_prod80(float3 colorInput)
{

	float3 colStrength = float3(ColStrengthR,ColStrengthG,ColStrengthB);
	float3 tsource = saturate(colorInput.rgb);
	float3 ttemp = 1 - tsource;
	float3 ttarget = ttemp.grg;
	float3 ttarget2 = ttemp.bbr;
	float3 ttemp2 = tsource.rgb * ttarget.rgb;
	ttemp2.rgb *= ttarget2.rgb;

	ttemp.rgb = ttemp2.rgb * colStrength;
	ttemp2.rgb *= TechniBrightness;

	ttarget.rgb = ttemp.grg;
	ttarget2.rgb = ttemp.bbr;

	ttemp.rgb = tsource.rgb - ttarget.rgb;
	ttemp.rgb += ttemp2.rgb;
	ttemp2.rgb = ttemp.rgb - ttarget2.rgb;

	colorInput.rgb = lerp(tsource.rgb, ttemp2.rgb, TechniStrength);

	colorInput.rgb = lerp(dot(colorInput.rgb, 0.333), colorInput.rgb, TechniSat); 
	
	return colorInput.rgb;

}

float3 SkyrimTonemapPass( float3 color )
{
	float	grayadaptation = dot(color.xyz, LumCoeff);

	#if (POSTPROCESS==1)
	color.xyz =  color.xyz / (grayadaptation * EAdaptationMaxV1 + EAdaptationMinV1);
	float cgray = dot( color.xyz, LumCoeff);
	cgray = pow(cgray, EContrastV1);
	float3 poweredcolor = pow( abs(color.xyz), EColorSaturationV1);
	float newgray = dot(poweredcolor.xyz, LumCoeff);
	color.xyz = poweredcolor.xyz * cgray / (newgray + 0.0001);
	float3	luma =  color.xyz;
	float	lumamax = 300.0;
	color.xyz = ( color.xyz * (1.0 +  color.xyz / lumamax)) / ( color.xyz + EToneMappingCurveV1);	
	#endif

	#if (POSTPROCESS==2)
	color.xyz =  color.xyz / (grayadaptation * EAdaptationMaxV2 + EAdaptationMinV2);
	float3 xncol = normalize( color.xyz);
	float3 scl =  color.xyz / xncol.xyz;
	scl = pow(scl, EIntensityContrastV2);
	xncol.xyz = pow(xncol.xyz, EColorSaturationV2);
	color.xyz = scl*xncol.xyz;
	float	lumamax = EToneMappingOversaturationV2;
	color.xyz = ( color.xyz * (1.0 +  color.xyz / lumamax)) / ( color.xyz + EToneMappingCurveV2);
 	color.xyz*=4;
	#endif

	#if (POSTPROCESS==3)
	color.xyz *= 35;
	float	lumamax = EToneMappingOversaturationV3;
	color.xyz = ( color.xyz * (1.0 +  color.xyz / lumamax)) / ( color.xyz + EToneMappingCurveV3);
	#endif

	#if (POSTPROCESS == 4)
	color.xyz =  color.xyz / (grayadaptation * EAdaptationMaxV4 + EAdaptationMinV4);
	float Y = dot( color.xyz, float3(0.299, 0.587, 0.114)); //0.299 * R + 0.587 * G + 0.114 * B;
	float U = dot( color.xyz, float3(-0.14713, -0.28886, 0.436)); //-0.14713 * R - 0.28886 * G + 0.436 * B;
	float V = dot( color.xyz, float3(0.615, -0.51499, -0.10001)); //0.615 * R - 0.51499 * G - 0.10001 * B;
	Y = pow(Y, EBrightnessCurveV4);
	Y = Y * EBrightnessMultiplierV4;
	color.xyz = V * float3(1.13983, -0.58060, 0.0) + U * float3(0.0, -0.39465, 2.03211) + Y;
	color.xyz = max( color.xyz, 0.0);
	color.xyz =  color.xyz / ( color.xyz + EBrightnessToneMappingCurveV4);
	#endif

	#if (POSTPROCESS == 5)
	float hnd = 1;
	float2 hndtweak = float2( 3.1 , 1.5 );
        color.xyz *= lerp( hndtweak.x, hndtweak.y, hnd );
	float3 xncol = normalize( color.xyz);
	float3 scl =  color.xyz/xncol.xyz;
	scl = pow(scl, EIntensityContrastV5);
	xncol.xyz = pow(xncol.xyz, EColorSaturationV5);
	color.xyz = scl*xncol.xyz;
	color.xyz *= HCompensateSatV5; // compensate for darkening caused my EcolorSat above
	color.xyz =  color.xyz / ( color.xyz + EToneMappingCurveV5);
	color.xyz *= 4;
	#endif

	#if (POSTPROCESS==6)
	//Postprocessing V6 by Kermles
	//tuned by the master himself for ME 1.4, thanks man!!!
	//hd6/ppv2///////////////////////////////////////////
	float 	EIntensityContrastV6 = EIntensityContrastV6Day;
	float 	EColorSaturationV6 = EColorSaturationV6Day;
	float 	HCompensateSatV6 = HCompensateSatV6Day;
	float 	EToneMappingCurveV6 = EToneMappingCurveV6Day;
	float 	EBrightnessV6 = EBrightnessV6Day;
	float 	EToneMappingOversaturationV6 = EToneMappingOversaturationV6Day;
	float 	EAdaptationMaxV6 = EAdaptationMaxV6Day;
	float 	EAdaptationMinV6 = EAdaptationMinV6Day;
	float	lumamax = EToneMappingOversaturationV6;
	//kermles////////////////////////////////////////////
	float4 	ncolor;					//temporary variable for color adjustments		
	//begin pp code/////////////////////////////////////////////////
	//ppv2 modified by kermles//////////////////////////////////////
		
	grayadaptation = clamp(grayadaptation, 0, 50);
	color.xyz *= EBrightnessV6;
	float3 xncol = normalize( color.xyz);
	float3 scl =  color.xyz/xncol.xyz;
	scl = pow(saturate(scl), EIntensityContrastV6);
	xncol.xyz = pow(xncol.xyz, EColorSaturationV6);
	color.xyz = scl*xncol.xyz;
	color.xyz *= HCompensateSatV6;
	color.xyz = ( color.xyz * (1.0 +  color.xyz/lumamax))/( color.xyz + EToneMappingCurveV6);
	color.xyz /= grayadaptation*EAdaptationMaxV6+EAdaptationMinV6;
	//rerun ppv2////////////////////////////////////////////////////
	color.xyz *= EBrightnessV6;
	xncol = normalize( color.xyz);
	scl =  color.xyz/xncol.xyz;
	scl = saturate(scl);
	scl = pow(scl, EIntensityContrastV6);
	xncol.xyz = pow(xncol.xyz, EColorSaturationV6);
	color.xyz = scl*xncol.xyz;
	color.xyz *= HCompensateSatV6;
	color.xyz = ( color.xyz * (1.0 +  color.xyz/lumamax))/( color.xyz + EToneMappingCurveV6);
	#endif

	return color;

}

float3 MoodPass( float3 colorInput )
{
	float3 colInput = colorInput;
	float3 colMood = 1.0f;
	colMood.r = moodR;
	colMood.g = moodG;
	colMood.b = moodB;
	float fLum = ( colInput.r + colInput.g + colInput.b ) / 3;
	colMood = lerp(0, colMood, saturate(fLum * 2.0));
	colMood = lerp(colMood, 1, saturate(fLum - 0.5) * 2.0);
	float3 colOutput = lerp(colInput, colMood, saturate(fLum * fRatio));
	colorInput=max(0, colOutput);
	return colorInput;
}

float3 CrossPass(float3 color)
{
	float2 CrossMatrix [3] = {
		float2 (1.03, 0.04),
		float2 (1.09, 0.01),
		float2 (0.78, 0.13),
 		};

	float3 image1 = color;
	float3 image2 = color;
	float gray = dot(float3(0.5,0.5,0.5), image1);  
	image1 = lerp (gray, image1,CrossSaturation);
	image1 = lerp (0.35, image1,CrossContrast);
	image1 +=CrossBrightness;
	image2.r = image1.r * CrossMatrix[0].x + CrossMatrix[0].y;
	image2.g = image1.g * CrossMatrix[1].x + CrossMatrix[1].y;
	image2.b = image1.b * CrossMatrix[2].x + CrossMatrix[2].y;
	color = lerp(image1, image2, CrossAmount);
	return color;
}

float3 ReinhardToneMapping(in float3 x)
{
	const float W =  ReinhardWhitepoint;	// Linear White Point Value
    	const float K =  ReinhardScale;        // Scale

    	// gamma space or not?
    	return (1 + K * x / (W * W)) * x / (x + K);
}

float3 HaarmPeterDuikerFilmicToneMapping(in float3 x)
{
    	x = max( (float3)0.0f, x - 0.004f );
    	return pow( abs( ( x * ( 6.2f * x + 0.5f ) ) / ( x * ( 6.2f * x + 1.7f ) + 0.06 ) ), 2.2f );
}

float3 CustomToneMapping(in float3 x)
{
	const float A = 0.665f;
	const float B = 0.09f;
	const float C = 0.004f;
	const float D = 0.445f;
	const float E = 0.26f;
	const float F = 0.025f;
	const float G = 0.16f;//0.145f;
	const float H = 1.1844f;//1.15f;

    // gamma space or not?
	return (((x*(A*x+B)+C)/(x*(D*x+E)+F))-G) / H;
}

float3 ColorFilmicToneMapping(in float3 x)
{
	// Filmic tone mapping
	const float3 A = float3(0.55f, 0.50f, 0.45f);	// Shoulder strength
	const float3 B = float3(0.30f, 0.27f, 0.22f);	// Linear strength
	const float3 C = float3(0.10f, 0.10f, 0.10f);	// Linear angle
	const float3 D = float3(0.10f, 0.07f, 0.03f);	// Toe strength
	const float3 E = float3(0.01f, 0.01f, 0.01f);	// Toe Numerator
	const float3 F = float3(0.30f, 0.30f, 0.30f);	// Toe Denominator
	const float3 W = float3(2.80f, 2.90f, 3.10f);	// Linear White Point Value
	const float3 F_linearWhite = ((W*(A*W+C*B)+D*E)/(W*(A*W+B)+D*F))-(E/F);
	float3 F_linearColor = ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-(E/F);

    // gamma space or not?
	return pow(saturate(F_linearColor * 1.25 / F_linearWhite),1.25);
}

float3 ColormodPass( float3 color )
{
	color.xyz = (color.xyz - dot(color.xyz, 0.333)) * ColormodChroma + dot(color.xyz, 0.333);
	color.xyz = saturate(color.xyz);
	color.x = (pow(color.x, ColormodGammaR) - 0.5) * ColormodContrastR + 0.5 + ColormodBrightnessR;
	color.y = (pow(color.y, ColormodGammaG) - 0.5) * ColormodContrastG + 0.5 + ColormodBrightnessB;
	color.z = (pow(color.z, ColormodGammaB) - 0.5) * ColormodContrastB + 0.5 + ColormodBrightnessB;
	return color;	
}

float3 SphericalPass( float3 color )
{
	float3 signedColor = color.rgb * 2.0 - 1.0;
	float3 sphericalColor = sqrt(1.0 - signedColor.rgb * signedColor.rgb);
	sphericalColor = sphericalColor * 0.5 + 0.5;
	sphericalColor *= color.rgb;
	color.rgb += sphericalColor.rgb * sphericalAmount;
	color.rgb *= 0.95;
	return color;
}

float3 SincityPass(float3 color)
{
	float sinlumi = dot(color.rgb, float3(0.30f,0.59f,0.11f));
	if(color.r > (color.g + 0.2f) && color.r > (color.b + 0.025f))
	{
		color.rgb = float3(sinlumi, 0, 0)*1.5;
	}
	else
	{
		color.rgb = sinlumi;
	}
	return color;
}

float3 colorhuefx_prod80( float3 color )
{
	
	float3 fxcolor = saturate( color.xyz );
	float greyVal = dot( fxcolor.xyz, LumCoeff.xyz );
	float3 HueSat = Hue( fxcolor.xyz );
	float colorHue = HueSat.x;
	float colorInt = HueSat.z - HueSat.y * 0.5;
	float colorSat = HueSat.y / ( 1.0 - abs( colorInt * 2.0 - 1.0 ) * 1e-10 );

	//When color intensity not based on original saturation level
   	if ( Use_COLORSAT == 0 )   colorSat = 1.0f;

	float hueMin_1 = hueMid - hueRange;
	float hueMax_1 = hueMid + hueRange;
	float hueMin_2 = 0.0f;
	float hueMax_2 = 0.0f;


   	if ( hueMin_1 < 0.0 )
   	{
   		hueMin_2 = 1.0f + hueMin_1;
   		hueMax_2 = 1.0f + hueMid;
   
      		if ( colorHue >= hueMin_1 && colorHue <= hueMid )
         		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, smootherstep( hueMin_1, hueMid, colorHue ) * ( colorSat * satLimit ));
      		else if ( colorHue >= hueMid && colorHue <= hueMax_1 )
        		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, ( 1.0f - smootherstep( hueMid, hueMax_1, colorHue )) * ( colorSat * satLimit ));
      		else if ( colorHue >= hueMin_2 && colorHue <= hueMax_2 )
         		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, smootherstep( hueMin_2, hueMax_2, colorHue ) * ( colorSat * satLimit ));
      		else
         		fxcolor.xyz = greyVal.xxx;
   	}

   	else if ( hueMax_1 > 1.0 )
   	{
   		hueMin_2 = 0.0f - ( 1.0f - hueMid );
   		hueMax_2 = hueMax_1 - 1.0f;

      		if ( colorHue >= hueMin_1 && colorHue <= hueMid )
         		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, smootherstep( hueMin_1, hueMid, colorHue ) * ( colorSat * satLimit ));
      		else if ( colorHue >= hueMid && colorHue <= hueMax_1 )
         		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, ( 1.0f - smootherstep( hueMid, hueMax_1, colorHue )) * ( colorSat * satLimit ));
      		else if ( colorHue >= hueMin_2 && colorHue <= hueMax_2 )
         		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, ( 1.0f - smootherstep( hueMin_2, hueMax_2, colorHue )) * ( colorSat * satLimit ));
      		else
         		fxcolor.xyz = greyVal.xxx;
   	}	
   
	else
   	{
      		if ( colorHue >= hueMin_1 && colorHue <= hueMid )
        		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, smootherstep( hueMin_1, hueMid, colorHue ) * ( colorSat * satLimit ));
      		else if ( colorHue > hueMid && colorHue <= hueMax_1 )
         		fxcolor.xyz = lerp( greyVal.xxx, fxcolor.xyz, ( 1.0f - smootherstep( hueMid, hueMax_1, colorHue )) * ( colorSat * satLimit ));
      		else
         		fxcolor.xyz = greyVal.xxx;
   	}

   	color.xyz = lerp( color.xyz, fxcolor.xyz, fxcolorMix );

	return color.xyz;

}

float4 ColorCorrectionPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);

#if(USE_LUT == 1)	
	color.x = tex2D(SamplerLUT, float2(saturate(color.x),0)).x;
	color.y = tex2D(SamplerLUT, float2(saturate(color.y),0)).y;
	color.z = tex2D(SamplerLUT, float2(saturate(color.z),0)).z;
#endif

#if USE_TECHNICOLOR
	color.xyz = TechniPass_prod80(color.xyz);
#endif

#if USE_SKYRIMTONEMAP
	color.xyz = SkyrimTonemapPass(color.xyz);
#endif

#if USE_COLORMOOD
	color.xyz = MoodPass(color.xyz);
#endif
 
#if USE_CROSSPROCESS
	color.xyz = CrossPass(color.xyz);
#endif
	
#if USE_REINHARD
	color.xyz = ReinhardToneMapping(color.xyz);
#endif

#if USE_HPD
	color.xyz = HaarmPeterDuikerFilmicToneMapping(color.xyz);
#endif
	
#if USE_FILMICCURVE
	color.xyz = CustomToneMapping(color.xyz);
#endif

#if USE_WATCHDOG_TONEMAP
	color.xyz = ColorFilmicToneMapping(color.xyz);
#endif

#if USE_COLORMOD
	color.xyz = ColormodPass(color.xyz);
#endif

#if USE_SPHERICALTONEMAP
	color.xyz = SphericalPass(color.xyz);
#endif

#if USE_SINCITY
	color.xyz = SincityPass(color.xyz);
#endif

#if USE_COLORHUEFX
	color.xyz = colorhuefx_prod80(color.xyz);
#endif

	return color;
}

technique ColorCorrection_Tech < enabled = RESHADE_START_ENABLED; >
{
	pass MartyMcFly_ColorCorrection_Pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = ColorCorrectionPass;
	}
}

#undef LumCoeff

}
}

#endif

#include EFFECT_CONFIG_UNDEF(MartyMcFly)
