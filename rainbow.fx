
/*------------------.
| :: Description :: |
'-------------------/
	Rainbow shader 

	https://github.com/Oncorporation/

	Version 2.0 Author: Charles Fettinger
	License: MIT
	

	About: 
	Create a Rainbow Gradient and combine it with the current image. It can be horizontal, vertical or angled. 
	The rainbow can be animated


	Ideas for future improvement:
    *

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 1.0
		! for obs-shaderfilter plugin 3/2019
		* Ability to debug or Apply to Image
		* Ability to Replace Colors via luminance

	Version 2.0
		! Converted to Reshade 11/2019

/*
/*------------------.
| :: UI Settings :: |
'------------------*/

#include "ReShadeUI.fxh"

uniform float Saturation 
< __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Saturation";
	ui_tooltip = "Amount of Color saturation";
> = 0.8; 
uniform float Luminosity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Luminosity";
	ui_tooltip = "Amount of Luminosity, advise to keep at 0.5, 1.0 is white, 0.0 is black";
> = 0.5; 
uniform float Spread < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 10.00;
	ui_label = "Spread";
	ui_tooltip = "Spread is wideness of color and is limited between 0.25 and 10";
> = 0.333; 
uniform float Speed < __UNIFORM_SLIDER_FLOAT1
	ui_min = -10.00; ui_max = 10.00;
	ui_label = "Speed";
	ui_tooltip = "Speed of Animation";
> = 0.010; 
uniform float Alpha_Percentage < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 100.00;
	ui_label = "Alpha Percentage";
	ui_tooltip = "Transparency or Opacity measured from 0% to 100%";
> = 30.00; 
uniform bool Vertical <
	ui_label = "Vertical";
	ui_tooltip = "Direction of Gradient is Vertical, default is Horizontal";
> = false;
uniform bool Rotational <
	ui_label = "Rotational";
	ui_tooltip = "Make Animation rotate";
> = true;
uniform float Rotation_Offset < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 6.28318531;
	ui_label = "Rotation Offset";
	ui_tooltip = "Amount of offset to apply to rotation, between 0 and 6.28318531";
> = 1.625; //<Range(0.0, 6.28318531)>
uniform bool Apply_To_Image <
	ui_label = "Apply To Image";
	ui_tooltip = "Apply Gradient to background color, otherwise just show gradient for debugging.";
> = true;
uniform bool Replace_Image_Color <
	ui_label = "Replace Image Color";
	ui_tooltip = "removes current colors and replaces with generated colors by Luminosity";
> = true;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float elapsed_time < source = "timer"; >;

/*-------------.
| :: Effect :: |
'-------------*/

float hueToRGB(float v1, float v2, float vH) {
	//if (vH < 0.0) vH+= 1.0;
	//if (vH > 1.0) vH -= 1.0;
	vH = frac(vH);
	if ((6.0 * vH) < 1.0) return (v1 + (v2 - v1) * 6.0 * vH);
	if ((2.0 * vH) < 1.0) return (v2);
	if ((3.0 * vH) < 2.0) return (v1 + (v2 - v1) * ((0.6666666666666667) - vH) * 6.0);
	return clamp(v1, 0.0, 1.0);
}

float4 HSLtoRGB(float4 hsl) {
	float4 rgb = float4(0.0, 0.0, 0.0, hsl.w);
	float v1 = 0.0;
	float v2 = 0.0;
	
	if (hsl.y == 0) {
		rgb.xyz = hsl.zzz;
	}
	else {
		
		if (hsl.z < 0.5) {
			v2 = hsl.z * (1 + hsl.y);
		}
		else {
			v2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
		}
		
		v1 = 2.0 * hsl.z - v2;
		
		rgb.x = hueToRGB(v1, v2, hsl.x + (0.3333333333333333));
		rgb.y = hueToRGB(v1, v2, hsl.x);
		rgb.z = hueToRGB(v1, v2, hsl.x - (0.3333333333333333));
		
	}
	
	return rgb;
}

float4 PS_Rainbow(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 lPos = texcoord / clamp(Spread, 0.25, 10.0);
	float time = (elapsed_time * 0.001 * clamp(Speed, -10.0, 10.0)) / clamp(Spread, 0.25, 10.0);	

	//set colors and direction
	float hue = (-1 * lPos.x) / 2.0;

	if (Rotational && (Vertical == false))
	{
		float timeWithOffset = time + Rotation_Offset;
		float sine = sin(timeWithOffset);
		float cosine = cos(timeWithOffset);
		hue = (lPos.x * cosine + lPos.y * sine) * 0.5;
	}

	if (Vertical && (Rotational == false))
	{
		hue = (-1 * lPos.y) * 0.5;
	}	

	hue += time;
	//while (hue < 0.0) hue += 1.0;
	//while (hue > 1.0) hue -= 1.0;
	hue = frac(hue);
	float4 hsl = float4(hue, clamp(Saturation, 0.0, 1.0), clamp(Luminosity, 0.0, 1.0), 1.0);
	float4 rgba = HSLtoRGB(hsl);
	
	if (Apply_To_Image)
	{
		float4 color = tex2D(ReShade::BackBuffer, texcoord);
		float4 original_color = color;
		float4 luma = dot(color,float4(0.30, 0.59, 0.11, 1.0));
		if (Replace_Image_Color)
			color = luma;
		rgba = lerp(original_color, rgba * color,clamp(Alpha_Percentage *.01 ,0,1.0));
		
	}
	return rgba;
}

/*-----------------.
| :: Techniques :: |
'-----------------*/

technique Rainbow < ui_label = "Rainbow Shader"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Rainbow;
    }
}
