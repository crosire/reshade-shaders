NAMESPACE_ENTER(CeeJay)

#ifndef RFX_duplicate
#include CeeJay_SETTINGS_DEF
#endif

#if (USE_CA == 1)

  /*---------------------------.
  | :: Chromatic Aberration :: |
  '---------------------------*/
/*
Chromatic Aberration

Distorts the image by shifting each color component, which creates color artifacts similar to those in a very cheap lens or a cheap sensor.

Version 1.0 by CeeJay.dk
- First version.
*/

// The Radial part is not yet finished.

/* //Settings for unfinished part of the effect
#define Chromatic_Type       2  //[1|2|3] 1 = Original, 2 = New, 3 = TV style
#define Chromatic_Ratio   1.00  //[0.15 to 6.00]  Sets a width to height ratio. 1.00 (1/1) is perfectly round, while 1.60 (16/10) is 60 % wider than it's high.
#define Chromatic_Radius  1.00  //[-1.00 to 3.00] lower values = stronger radial effect from center
#define Chromatic_Amount -1.00  //[-2.00 to 1.00] Strength of black. -2.00 = Max Black, 1.00 = Max White.
#define Chromatic_Slope      8  //[2 to 16] How far away from the center the change should start to really grow strong (odd numbers cause a larger fps drop than even numbers)
#define Chromatic_Center float2(0.500, 0.500)  //[0.000 to 1.000, 0.000 to 1.000] Center of effect for VignetteType 1. 2 and 3 do not obey this setting.
*/

#ifndef Chromatic_mode
  #define Chromatic_mode 1
#endif

float4 ChromaticAberrationPass( float4 colorInput, float2 tex )
{
  float3 color = float3(0.0,0.0,0.0);
  
  /*------------------.
  | :: Color shift :: |
  '------------------*/
  #if Chromatic_mode == 1 // Color shift
  
	color.r = myTex2D(s0, tex + (RFX_PixelSize * Chromatic_shift)).r;
	color.g = colorInput.g;
	color.b = myTex2D(s0, tex - (RFX_PixelSize * Chromatic_shift)).b;
  
  #else
  /*-------------.
  | :: Radial :: |
  '-------------*/
  
	//Set the center
		float2 distance_xy = tex - Chromatic_Center;

		//Adjust the ratio
		distance_xy *= float2((RFX_PixelSize.y / RFX_PixelSize.x),Chromatic_Ratio);

		//Calculate the distance
		distance_xy /= Chromatic_Radius;
		float distance = dot(distance_xy,distance_xy);
		
		//sample the color components
		color.r = myTex2D(s0, Chromatic_Center + distance_xy).r;
		color.g = myTex2D(s0, tex).g;
		color.b = myTex2D(s0, Chromatic_Center + distance_xy).b;

		//Apply the vignette
		//colorInput.rgb *= (1.0 + pow(distance, Chromatic_Slope * 0.5) * Chromatic_Amount); //pow - multiply
  
  #endif
  
  colorInput.rgb = lerp(colorInput.rgb, color, Chromatic_strength); //Adjust the strength of the effect

  return saturate(colorInput);
}

float3 ChromaticAberrationWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 color = myTex2D(s0, texcoord);

	color = ChromaticAberrationPass(color,texcoord);

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color.rgb;
}

technique CA_Tech <bool enabled = 
#if (CA_TimeOut > 0)
1; int toggle = CA_ToggleKey; timeout = CA_TimeOut; >
#else
RFX_Start_Enabled; int toggle = CA_ToggleKey; >
#endif
{
	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = ChromaticAberrationWrap;
	}
}

#include "ReShade\CeeJay\PiggyCount.h"
#endif

#ifndef RFX_duplicate
#include CeeJay_SETTINGS_UNDEF
#endif

NAMESPACE_LEAVE()