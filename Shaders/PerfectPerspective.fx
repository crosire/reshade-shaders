/*
Copyright (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Perfect Perspective PS ver. 2.0

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float3 Color <
	ui_label = "Borders Color";
	ui_type = "Color";
> = float3(0.027, 0.027, 0.027);

uniform int FOV <
	ui_label = "Field of View";
	ui_tooltip = "Match in-game Field of View";
	ui_type = "drag";
	ui_min = 45; ui_max = 120;
> = 90;

uniform int Type <
	ui_label = "Type of FOV";
	ui_tooltip = "If image bulges in movement, change it to Diagonal. When proportions are distorted, choose Vertical";
	ui_type = "combo";
	ui_items = "Horizontal FOV\0Diagonal FOV\0Vertical FOV\0";
> = 0;

uniform float Zooming <
	ui_label = "Adjust Borders Size";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 3.0; ui_step = 0.001;
> = 1.0;

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// Stereographic-Gnomonic lookup function
// Input data:
	// SqrTanFOVq >> squared tangent of quater FOV angle
	// Coordinates >> UV coordinates (from -1, to 1), where (0,0) is at the center of the screen
float Formula(float SqrTanFOVq, float2 Coordinates)
{
	float Result = 1.0 - SqrTanFOVq;
	Result /= 1.0 - SqrTanFOVq * (Coordinates.x * Coordinates.x + (Coordinates.y * Coordinates.y));
	return Result;
}

// Shader pass
float3 PerfectPerspectivePS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Get Pixel Position
	float2 SphCoord = texcoord;
	// Get Aspect Ratio
	float AspectR = 1.0 / ReShade::AspectRatio;

	// Convert FOV type..
	float FovType = 1.0;
		if (Type == 1) // ..to diagonal
		{
			FovType = sqrt(AspectR * AspectR + 1.0);
		}
		else if (Type == 2) // ..to vertical
		{
			FovType = AspectR;
		}

	// Convert 1/4 FOV to radians and calc tangent squared
	float SqrTanFOVq = float(FOV) * 0.25;
		SqrTanFOVq = radians(SqrTanFOVq);
		SqrTanFOVq = tan(SqrTanFOVq);
		SqrTanFOVq *= SqrTanFOVq;

	// Convert UV to Radial Coordinates
	SphCoord = SphCoord * 2.0 - 1.0;
	// Aspect Ratio correction
	SphCoord.y *= AspectR;
	// Zoom in image and adjust FOV type (pass 1 of 2)
	SphCoord *= Zooming / FovType;

	// Stereographic-Gnomonic lookup
	SphCoord *= Formula(SqrTanFOVq, SphCoord);

	// Adjust FOV type (pass 2 of 2)
	SphCoord *= FovType;

	// Aspect Ratio back to square
	SphCoord.y /= AspectR;

	// Back to UV Coordinates
	SphCoord = SphCoord * 0.5 + 0.5;

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
