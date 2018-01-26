/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Perfect Perspective PS

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float Strength <
	ui_tooltip = "Distortion scale. 0 is Linear perspective and 1 is Stereographic perspective.";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform float3 Color <
	ui_label = "Background Color";
	ui_type = "Color";
> = float3(0.027, 0.027, 0.027);

uniform int FOV <
	ui_label = "Field of View";
	ui_tooltip = "In-game horizontal Field of View";
	ui_type = "drag";
	ui_min = 60; ui_max = 110;
> = 90;

uniform int Type <
	ui_label = "Type of alignment";
	ui_type = "combo";
	ui_items = "horizontal\0diagonal\0vertical\0";
> = 0;


  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

float3 PerfectPerspectivePS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Convert FOV to half-radians and calc cotangent
	float ctanFOVh = radians(FOV * 0.5);
	ctanFOVh = 1.0 / tan(ctanFOVh);
	// Get Aspect Ratio
	float AspectR = ReShade::AspectRatio;
	float Edge;
	float2 SphCoord = texcoord;


	// Horizontal
	if (Type == 0)
	{
		Edge = 1.0;
	}

	// Diagonal
	else if (Type == 1)
	{
		Edge = length(
			float2(1.0, 1.0 / AspectR)
		);
	}

	// Vertical
	else if (Type == 2)
	{
		Edge = 1.0 / AspectR;
	}


	// Convert UV to Radial Coordinates
	SphCoord = SphCoord * 2.0 - 1.0;

	// Aspect Ratio correction
	SphCoord.y /= AspectR;

	// Stereographic transform
	SphCoord *=
		(1.0 + length( float3(SphCoord, ctanFOVh) ))
		/ 
		(1.0 + length( float2(Edge, ctanFOVh) ))
	;

	// Aspect Ratio back to square
	SphCoord.y *= AspectR;

	// Back to UV Coordinates
	SphCoord = (SphCoord + 1.0) * 0.5;

	// Distortion correction amount
	SphCoord = lerp(texcoord, SphCoord, Strength);

	// Sample display image
	float3 Display = tex2D(ReShade::BackBuffer, SphCoord).rgb;


	// Mask out outside-border pixels
	if (SphCoord.x < 1.0 && SphCoord.x > 0.0 && SphCoord.y < 1.0 && SphCoord.y > 0.0)
	{
		return Display;
	}
	else
	{
		return Color;
	}
}


technique PerfectPerspective
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PerfectPerspectivePS;
	}
}
