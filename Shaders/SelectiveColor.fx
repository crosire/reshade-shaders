/*------------------.
| :: Description :: |
'-------------------/
// Selective Color shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter

Defaults:
defaults: .4,.03,.25,.25, 5.0, true,true, true, true. cuttoff higher = less color, 0 = all 1 = none
/*------------------.
| :: UI Settings :: |
'------------------*/

#include "ReShadeUI.fxh"

uniform float cutoff_Red < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Cutoff Red";
	ui_tooltip = "'Cutoff' - higher = less color, 0 = all 1 = none. Default .4";
> = 0.40;
uniform float cutoff_Green < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Cutoff Green";
	ui_tooltip = "'Cutoff' - higher = less color, 0 = all 1 = none. Default .025";
> = 0.025;
uniform float cutoff_Blue < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Cutoff Blue";
	ui_tooltip = "'Cutoff' - higher = less color, 0 = all 1 = none. Default .25";
> = 0.25;
uniform float cutoff_Yellow < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Cuteoff Yellow";
	ui_tooltip = "'Cutoff' - higher = less color, 0 = all 1 = none. Default .25";
> = 0.25;
uniform float acceptance_Amplifier < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.00; ui_max = 10.00;
	ui_label = "Acceptance Amplifier";
	ui_tooltip = "Default 5.0, increases the amount of color accepted";
> = 5.0;

uniform bool show_Red <
	ui_label = "Show Red";
	ui_tooltip = "True shows red when accepted verse the cutoff. Otherwise no red is shown";
> = true;
uniform bool show_Green <
		ui_label = "Show Green";
	ui_tooltip = "True shows green when accepted verse the cutoff. Otherwise no green is shown";
> = true;
uniform bool show_Blue <
	ui_label = "Show Blue";
	ui_tooltip = "True shows blue when accepted verse the cutoff. Otherwise no blue is shown";
> = true;
uniform bool show_Yellow <
	ui_label = "Show Yellow";
	ui_tooltip = "True shows yellow when accepted verse the cutoff. Otherwise no yellow is shown";
> = true;


#include "ReShade.fxh"

float4 PS_Selective_Color(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
	//float PI		= 3.1415926535897932384626433832795;//acos(-1);
	float4 color		= tex2D(ReShade::BackBuffer, texcoord);

	float luminance		= (color.r + color.g + color.b) * 0.3333;
	float4 gray		= float4(luminance,luminance,luminance, 1.0);

	float redness		= max ( min ( color.r - color.g , color.r - color.b ) / color.r , 0);
	float greenness		= max ( min ( color.g - color.r , color.g - color.b ) / color.g , 0);
	float blueness		= max ( min ( color.b - color.r , color.b - color.g ) / color.b , 0);
	
	float rgLuminance	= (color.r*1.4 + color.g*0.6) * 0.5;
	float rgDiff		= abs(color.r-color.g)*1.4;

 	float yellowness	= 0.1 + rgLuminance * 1.2 - color.b - rgDiff;

	float4 accept;
	accept.r		= show_Red * (redness - cutoff_Red);
	accept.g		= show_Green * (greenness - cutoff_Green);
	accept.b		= show_Blue * (blueness - cutoff_Blue);
	accept[3]		= show_Yellow * (yellowness - cutoff_Yellow);

	float acceptance	= max (accept.r, max(accept.g, max(accept.b, max(accept[3],0))));
	float modAcceptance	= min (acceptance * acceptance_Amplifier, 1);

	float4 result;
	result			= modAcceptance * color + (1.0-modAcceptance) * gray;
	//	result = float4(redness, greenness,blueness,1);

	return result;
}


technique Selective_Color < ui_label = "Selective Color"; >
{
	pass Selective_Color_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Selective_Color;
	}
}