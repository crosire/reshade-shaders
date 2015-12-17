#include "Common.fx"
#include CeeJay_SETTINGS_DEF

#if (USE_LUMASHARPEN == 1)

/*
   _____________________

     LumaSharpen 1.5.0
   _____________________

  by Christian Cann Schuldt Jensen ~ CeeJay.dk

  It blurs the original pixel with the surrounding pixels and then subtracts this blur to sharpen the image.
  It does this in luma to avoid color artifacts and allows limiting the maximum sharpning to avoid or lessen halo artifacts.

  This is similar to using Unsharp Mask in Photoshop.

  Compiles with 3.0
*/

   /*-----------------------------------------------------------.
  /                      Developer settings                     /
  '-----------------------------------------------------------*/
#define CoefLuma float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
//#define CoefLuma float3(0.299, 0.587, 0.114)       // BT.601 luma coefficient (SD Television)
//#define CoefLuma float3(1.0/3.0, 1.0/3.0, 1.0/3.0) // Equal weight coefficient

   /*-----------------------------------------------------------.
  /                          Main code                          /
  '-----------------------------------------------------------*/

namespace CeeJay
{

float3 LumaSharpenPass(float2 tex)
{
  // -- Get the original pixel --
  float3 ori = myTex2D(s0, tex).rgb;       // ori = original pixel

  // -- Combining the strength and luma multipliers --
  float3 sharp_strength_luma = (CoefLuma * sharp_strength); //I'll be combining even more multipliers with it later on

   /*-----------------------------------------------------------.
  /                       Sampling patterns                     /
  '-----------------------------------------------------------*/
  //   [ NW,   , NE ] Each texture lookup (except ori)
  //   [   ,ori,    ] samples 4 pixels
  //   [ SW,   , SE ]

  // -- Pattern 1 -- A (fast) 7 tap gaussian using only 2+1 texture fetches.
  #if pattern == 1

	// -- Gaussian filter --
	//   [ 1/9, 2/9,    ]     [ 1 , 2 ,   ]
	//   [ 2/9, 8/9, 2/9]  =  [ 2 , 8 , 2 ]
	//   [    , 2/9, 1/9]     [   , 2 , 1 ]

	float3 blur_ori = myTex2D(s0, tex + (float2(px,py) / 3.0) * offset_bias).rgb;  // North West
	blur_ori += myTex2D(s0, tex + (float2(-px,-py) / 3.0) * offset_bias).rgb; // South East

	//blur_ori += myTex2D(s0, tex + float2(px,py) / 3.0 * offset_bias); // North East
	//blur_ori += myTex2D(s0, tex + float2(-px,-py) / 3.0 * offset_bias); // South West

	blur_ori /= 2;  //Divide by the number of texture fetches

	sharp_strength_luma *= 1.5; // Adjust strength to aproximate the strength of pattern 2

  #endif

  // -- Pattern 2 -- A 9 tap gaussian using 4+1 texture fetches.
  #if pattern == 2

	// -- Gaussian filter --
	//   [ .25, .50, .25]     [ 1 , 2 , 1 ]
	//   [ .50,   1, .50]  =  [ 2 , 4 , 2 ]
	//   [ .25, .50, .25]     [ 1 , 2 , 1 ]


	float3 blur_ori = myTex2D(s0, tex + float2(px,-py) * 0.5 * offset_bias).rgb; // South East
	blur_ori += myTex2D(s0, tex + float2(-px,-py) * 0.5 * offset_bias).rgb;  // South West
	blur_ori += myTex2D(s0, tex + float2(px,py) * 0.5 * offset_bias).rgb; // North East
	blur_ori += myTex2D(s0, tex + float2(-px,py) * 0.5 * offset_bias).rgb; // North West

	blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches

  #endif

  // -- Pattern 3 -- An experimental 17 tap gaussian using 4+1 texture fetches.
  #if pattern == 3

	// -- Gaussian filter --
	//   [   , 4 , 6 ,   ,   ]
	//   [   ,16 ,24 ,16 , 4 ]
	//   [ 6 ,24 ,   ,24 , 6 ]
	//   [ 4 ,16 ,24 ,16 ,   ]
	//   [   ,   , 6 , 4 ,   ]

	float3 blur_ori = myTex2D(s0, tex + float2(0.4*px,-1.2*py)* offset_bias).rgb;  // South South East
	blur_ori += myTex2D(s0, tex + float2(-1.2*px,-0.4*py) * offset_bias).rgb; // West South West
	blur_ori += myTex2D(s0, tex + float2(1.2*px,0.4*py) * offset_bias).rgb; // East North East
	blur_ori += myTex2D(s0, tex + float2(-0.4*px,1.2*py) * offset_bias).rgb; // North North West

	blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches

	sharp_strength_luma *= 0.51;
  #endif

  // -- Pattern 4 -- A 9 tap high pass (pyramid filter) using 4+1 texture fetches.
  #if pattern == 4

	// -- Gaussian filter --
	//   [ .50, .50, .50]     [ 1 , 1 , 1 ]
	//   [ .50,    , .50]  =  [ 1 ,   , 1 ]
	//   [ .50, .50, .50]     [ 1 , 1 , 1 ]

	float3 blur_ori = myTex2D(s0, tex + float2(0.5 * px,-py * offset_bias)).rgb;  // South South East
	blur_ori += myTex2D(s0, tex + float2(offset_bias * -px,0.5 * -py)).rgb; // West South West
	blur_ori += myTex2D(s0, tex + float2(offset_bias * px,0.5 * py)).rgb; // East North East
	blur_ori += myTex2D(s0, tex + float2(0.5 * -px,py * offset_bias)).rgb; // North North West

	//blur_ori += (2 * ori); // Probably not needed. Only serves to lessen the effect.

	blur_ori /= 4.0;  //Divide by the number of texture fetches

	sharp_strength_luma *= 0.666; // Adjust strength to aproximate the strength of pattern 2
  #endif

   /*-----------------------------------------------------------.
  /                            Sharpen                          /
  '-----------------------------------------------------------*/

  // -- Calculate the sharpening --
  float3 sharp = ori - blur_ori;  //Subtracting the blurred image from the original image

  #if 0 //older CeeJay 1.4 code (included here because the new code while faster can be difficult to understand)
	// -- Adjust strength of the sharpening --
	float sharp_luma = dot(sharp, sharp_strength_luma); //Calculate the luma and adjust the strength

	// -- Clamping the maximum amount of sharpening to prevent halo artifacts --
	sharp_luma = clamp(sharp_luma, -sharp_clamp, sharp_clamp);  //TODO Try a curve function instead of a clamp
  
  #else //new code
	// -- Adjust strength of the sharpening and clamp it--
	float4 sharp_strength_luma_clamp = float4(sharp_strength_luma * (0.5 / sharp_clamp),0.5); //Roll part of the clamp into the dot

	//sharp_luma = saturate((0.5 / sharp_clamp) * sharp_luma + 0.5); //scale up and clamp
	float sharp_luma = saturate(dot(float4(sharp,1.0), sharp_strength_luma_clamp)); //Calculate the luma, adjust the strength, scale up and clamp
	sharp_luma = (sharp_clamp * 2.0) * sharp_luma - sharp_clamp; //scale down
  #endif

  // -- Combining the values to get the final sharpened pixel	--
  float3 outputcolor = ori + sharp_luma;    // Add the sharpening to the the original.

   /*-----------------------------------------------------------.
  /                     Returning the output                    /
  '-----------------------------------------------------------*/
  #if show_sharpen == 1
	//outputcolor = abs(sharp * 4.0);
	outputcolor = saturate(0.5 + (sharp_luma * 4.0)).rrr;
  #endif

  return saturate(outputcolor);

}

float3 LumaSharpenWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = LumaSharpenPass(texcoord);

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color;
}

technique LumaSharpen_Tech <bool enabled = RFX_Start_Enabled; int toggle = LumaSharpen_ToggleKey; >
{
	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = LumaSharpenWrap;
	}
}

}

#include "ReShade\CeeJay\PiggyCount.h"
#endif

#include CeeJay_SETTINGS_UNDEF
