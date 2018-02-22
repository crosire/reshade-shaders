/*
Chromakey PS (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

  ////////////////////
 /////// MENU ///////
////////////////////

uniform int Curve <
	ui_label = "Depth curve";
	ui_tooltip = "Keep high if you want to key far plane, for separation of nearby objects use low values";
	ui_type = "drag";
	ui_min = 1; ui_max = 32;
> = 16;

uniform float Threshold <
	ui_label = "Threshold";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.999; ui_step = 0.001;
> = 0.76;

uniform int Pass <
	ui_label = "Keying type";
	ui_type = "combo";
	ui_items = "Background key\0Foreground key\0";
> = 0;

uniform int Color <
	ui_label = "Keying color";
	ui_tooltip = "Ultimatte(tm) Super Blue and Green are industry standard colors for chromakey";
	ui_type = "combo";
	ui_items = "Super Blue Ultimatte(tm)\0Green Ultimatte(tm)\0Custom\0";
> = 0;

uniform float3 CustomColor <
	ui_type = "color";
	ui_label = "Custom color";
> = float3(1.0, 0.0, 0.0);

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

float3 ChromakeyPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Sample display image
	float3 Display = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample depth image
	float Depth = tex2D(ReShade::DepthBuffer, texcoord).r;

	// Define chromakey color, Ultimatte(tm) Super Blue, Ultimatte(tm) Green, or user color
	float3 Screen = (Color == 0) ? float3(0.07, 0.18, 0.72) : Color == 1 ? float3(0.29, 0.84, 0.36) : CustomColor;

	// Paint the picture
	bool IsItFront = (Pass == 0);
	return (
		Threshold < pow(Depth, Curve) ? IsItFront : !IsItFront
	) ? Screen : Display;
}

technique Chromakey
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromakeyPS;
	}
}
