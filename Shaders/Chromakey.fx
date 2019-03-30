/*
Chromakey PS v1.3.0 (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/


	  ////////////
	 /// MENU ///
	////////////

#include "ReShadeUI.fxh"

uniform float Threshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.999; ui_step = 0.001;
	ui_category = "Distance adjustment";
> = 0.1;

uniform bool RadialX <
	ui_label = "Horizontally radial depth";
	ui_category = "Radial distance";
> = false;
uniform bool RadialY <
	ui_label = "Vertically radial depth";
	ui_category = "Radial distance";
> = false;

uniform int FOV < __UNIFORM_SLIDER_INT1
	ui_label = "FOV (horizontal)";
	ui_tooltip = "Field of view in degrees";
	#if __RESHADE__ < 40000
		ui_step = 1;
	#endif
	ui_min = 0; ui_max = 170;
	ui_category = "Radial distance";
> = 90;

uniform int Pass <
	ui_label = "Keying type";
	ui_type = "combo";
	ui_items = "Background key\0Foreground key\0";
	ui_category = "Direction adjustment";
> = 0;

uniform int Color <
	ui_label = "Keying color";
	ui_tooltip = "Ultimatte(tm) Super Blue and Green are industry standard colors for chromakey";
	ui_type = "combo";
	ui_items = "Super Blue Ultimatte(tm)\0Green Ultimatte(tm)\0Custom\0";
	ui_category = "Color settings";
> = 0;

uniform float3 CustomColor < __UNIFORM_COLOR_FLOAT3
	ui_label = "Custom color";
	ui_category = "Color settings";
> = float3(1.0, 0.0, 0.0);


	  //////////////
	 /// SHADER ///
	//////////////

#include "ReShade.fxh"

float3 ChromakeyPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Sample depth image
	float Depth = ReShade::GetLinearizedDepth(texcoord);

	// Convert to radial depth
	float2 Size;
	Size.x = tan(radians(FOV*0.5));
	Size.y = Size.x / ReShade::AspectRatio;
	if(RadialX) Depth *= length(float2((texcoord.x-0.5)*Size.x, 1.0));
	if(RadialY) Depth *= length(float2((texcoord.y-0.5)*Size.y, 1.0));

	// Define chromakey color, Ultimatte(tm) Super Blue, Ultimatte(tm) Green, or user color
	float3 Screen;
	switch(Color)
	{
		case 0:{ Screen = float3(0.07, 0.18, 0.72); break; } // Ultimatte(tm) Super Blue
		case 1:{ Screen = float3(0.29, 0.84, 0.36); break; } // Ultimatte(tm) Green
		case 2:{ Screen = CustomColor;              break; } // User defined color
	}

	// Paint the picture
	bool IsItFront = !bool(Pass);

	return (Threshold < Depth ? IsItFront : !IsItFront) ?
	Screen :
	tex2D(ReShade::BackBuffer, texcoord).rgb;
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique Chromakey < ui_tooltip = "Generate green-screen wall based of depth"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromakeyPS;
	}
}
