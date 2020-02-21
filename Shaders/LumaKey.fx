/*
Lumakey PS v1.0.0 (c) 2020 Charles Fettinger
https://github.com/Oncorporation/reshade-shaders

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.

	About:
	Uses Luminance to Key out colors
	This is good for removing skies, or dark areas or when exact colors are imperfect for keying

*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"


	  ////////////
	 /// MENU ///
	////////////


uniform float lumaMax < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max =1.05; ui_step = 0.001;
	ui_label = "Maximum Luminance Accepted";
	ui_category = "Luminance Options";
> = 1.05;

uniform float lumaMaxSmooth < __UNIFORM_SLIDER_FLOAT1
	ui_min = -0.05; ui_max =1.00; ui_step = 0.001;
	ui_label = "Maximum Luminance Smooth or fade in";
	ui_category = "Luminance Options";
> = 0.10;

uniform float lumaMin < __UNIFORM_SLIDER_FLOAT1
	ui_min = -0.05; ui_max =1.00; ui_step = 0.001;
	ui_label = "Minimum Luminance Accepted";
	ui_category = "Luminance Options";
> = 0.00;

uniform float lumaMinSmooth < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max =1.00; ui_step = 0.001;
	ui_label = "Minimum Luminance Smooth or fade in";
	ui_category = "Luminance Options";
> = 0.00;

uniform bool invertImageColor <
	ui_label = "Invert Image Color";
	ui_category = "Adjustments";
> = false;
uniform bool invertAlphaChannel <
	ui_label = "Invert Alpha Channel";
	ui_category = "Adjustments";
> = false;

uniform float4 AddColor < __UNIFORM_COLOR_FLOAT3
	ui_label = "Add Color";
	ui_category = "Adjustments";
> = float4(1.0, 1.0, 1.0, 1.0);

uniform int Color < __UNIFORM_RADIO_INT1
	ui_label = "Keying color";
	ui_tooltip = "Ultimatte(tm) Super Blue and Green are industry standard colors for chromakey";
	ui_items = "Super Blue Ultimatte(tm)\0Green Ultimatte(tm)\0Custom\0";
	ui_category = "Color settings";
> = 1;

uniform float3 CustomKeyColor < __UNIFORM_COLOR_FLOAT3
	ui_label = "Custom Key Color";
	ui_category = "Color settings";
> = float3(1.0, 0.0, 0.0);



	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

float4 InvertColor(float4 rgba_in)
{	
	// could use (white - rgba_in) - this is an example
	rgba_in.r = 1.0 - rgba_in.r;
	rgba_in.g = 1.0 - rgba_in.g;
	rgba_in.b = 1.0 - rgba_in.b;
	rgba_in.a = 1.0 - rgba_in.a;
	return rgba_in;
}

	  //////////////
	 /// SHADER ///
	//////////////

float3 LumakeyPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Define chromakey color, Ultimatte(tm) Super Blue, Ultimatte(tm) Green, or user color
	float3 Screen;
	switch(Color)
	{
		case 0:{ Screen = float3(0.07, 0.18, 0.72); break; } // Ultimatte(tm) Super Blue
		case 1:{ Screen = float3(0.29, 0.84, 0.36); break; } // Ultimatte(tm) Green
		case 2:{ Screen = CustomKeyColor;              break; } // User defined color
	}

	float4 rgba = tex2D(ReShade::BackBuffer, texcoord);
	// Developer Options
	const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);
	//const float3 coefLuma = float3(0.299,0.587,0.114) lower res monitors

	if (invertImageColor)
	{
		rgba = InvertColor(rgba);
	}
	float luminance = dot(rgba * AddColor, coefLuma);

	//intensity = min(max(intensity,minIntensity),maxIntensity);
	float clo = smoothstep(lumaMin, lumaMin + lumaMinSmooth, luminance);
	float chi = 1. - smoothstep(lumaMax - lumaMaxSmooth, lumaMax, luminance);

	float amask = clo * chi;

	if (invertAlphaChannel)
	{
		amask = 1.0 - amask;
	}	
	rgba *= AddColor;
	rgba.a = clamp(amask,0.0,1.0);

	//return lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, Screen, DepthMask);
	return lerp(Screen,rgba.rgb, rgba.a);
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique LumaKey < ui_tooltip = "Generate green-screen based on luminance"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LumakeyPS;
	}
}
