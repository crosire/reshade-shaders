/*
Lumakey PS v1.0.0 (c) 2020 Charles Fettinger
https://github.com/Oncorporation/reshade-shaders

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.

	About:
	Choose color(s) to Key out colors	
	Typical GreenScreen Technology used with SplitScreen to create extreme effects
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"


	  ////////////
	 /// MENU ///
	////////////

uniform float3 Color < __UNIFORM_COLOR_FLOAT3
	ui_label = "Color To Be Removed";
	ui_category = "Color Target";
> = float3(0.0, 0.0, 0.0);

uniform float similarity < __UNIFORM_SLIDER_FLOAT1
	ui_min = -1.50; ui_max = 2.0; ui_step = 0.001;
	ui_label = "Similar color targeting";
	ui_category = "Color Target";
> = 0.075;
uniform float smoothness < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.001;
	ui_label = "Smoothness of targeting";
	ui_category = "Color Target";
> = 0.02;

uniform int KeyColor < __UNIFORM_RADIO_INT1
	ui_label = "Keying color";
	ui_tooltip = "Ultimatte(tm) Super Blue and Green are industry standard colors for chromakey";
	ui_items = "Super Blue Ultimatte(tm)\0Green Ultimatte(tm)\0Custom\0";
	ui_category = "Color Output";
> = 1;

uniform float3 CustomKeyColor < __UNIFORM_COLOR_FLOAT3
	ui_label = "Custom Key Color";
	ui_tooltip = "Custom Color used as chromakey, must be chosen as KeyColor Custom";
	ui_category = "Color Output";
> = float3(1.0, 0.0, 0.0);

uniform bool invertAlphaChannel <
	ui_label = "Invert Alpha Channel";
	ui_category = "Color Output";
> = false;


uniform float gamma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 10.00; ui_step = 0.001;
	ui_label = "Gamma Amount";
	ui_tooltip = "Adjust brightness with gamma";
	ui_category = "Source Color Adjustments";
> = 1.0;

uniform float contrast < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 10.00; ui_step = 0.001;
	ui_label = "Contrast Amount";
	ui_tooltip = "How much contrast affects gamma";
	ui_category = "Source Color Adjustments";
> = 1.0;

uniform float brightness < __UNIFORM_SLIDER_FLOAT1
	ui_min = -2.50; ui_max = 2.50; ui_step = 0.01;
	ui_label = "Brightness Addition";
	ui_tooltip = "How much brightness to add or remove with negative";
	ui_category = "Source Color Adjustments";
> = 0.0;



	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

float4 CalcColor(float4 rgba)
{
	return float4(pow(rgba.rgb, float3(gamma, gamma, gamma)) * contrast + brightness, rgba.a);
}

float GetColorDist(float3 rgb)
{
	return distance(Color.rgb, rgb);
}

float4 ProcessColorKey(float4 rgba, float3 screen)
{
	float colorDist = GetColorDist(rgba.rgb);
	float keyAmount = saturate(max(colorDist - similarity, 0.0) / smoothness);

	//calc alpha of smoothing areas - does not work yet
	/*float cLo = smoothstep(similarity - smoothness, similarity, colorDist);
	float cHi = 1. - smoothstep(similarity, similarity + smoothness, colorDist);

	float amask = cLo * cHi;

	if (invertAlphaChannel)
	{
		amask = 1.0 - amask;
	}
	//rgba.a *= clamp(amask,0.0,1.0);
	*/
	float4 returnColor = float4(CalcColor(rgba).rgb, 1.0);
	if (keyAmount < 1.0) {
		returnColor = float4(screen,smoothstep(1.0, 0.0, keyAmount));
	}

	return returnColor;

	//return lerp(float4(screen, 1 - keyAmount), float4(CalcColor(rgba).rgb, 1.0 + keyAmount), keyAmount);
}

	  //////////////
	 /// SHADER ///
	//////////////

float4 PSColorKeyRGBA(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Define chromakey color, Ultimatte(tm) Super Blue, Ultimatte(tm) Green, or user color
	float3 Screen;
	switch(KeyColor)
	{
		case 0:{ Screen = float3(0.07, 0.18, 0.72); break; } // Ultimatte(tm) Super Blue
		case 1:{ Screen = float3(0.29, 0.84, 0.36); break; } // Ultimatte(tm) Green
		case 2:{ Screen = CustomKeyColor;           break; } // User defined color
	}

	float4 rgba =  tex2D(ReShade::BackBuffer, texcoord);// * float4(Color,1.0);
	return ProcessColorKey(rgba, Screen);
}

	  //////////////
	 /// OUTPUT ///
	//////////////

technique ColorKey < ui_tooltip = "Generate chromakey based on chosen color(s)"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PSColorKeyRGBA;
	}
}
