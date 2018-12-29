/*------------------.
| :: Description :: |
'-------------------/

	Nostalgia (version 1.1)

	Author: CeeJay.dk
	License: MIT

	About:
	In this effect I try to recreate the looks of systems from a bygone era.
	I've started with reducing the color to that of systems with 16 color palette.

	Ideas for future improvement:
	* Try HSL / HCY / Lab or other colorspaces. I'm not sure RGB is the best choice for color matching.
	* Pixelation
	* Scanlines
	* CRT patterns
	* Curvature
	* Dithering (both good and the bad dithering used back then)
	* Levels (might be needed because older system were often displayed on televisions and older monitors - not modern monitors)

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 1.0
	* Color reduction to C64 palette

	Version 1.1 
	* Added ability to set a custom palette
	* Added EGA palette
	+ Improved settings UI
	- Commented much of the code

*/


/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"


/*------------------.
| :: UI Settings :: |
'------------------*/

uniform int Nostalgia_palette <
	ui_type = "combo";
	ui_label = "Palette";
	ui_tooltip = "Choose a palette";
	//ui_category = "";
	ui_items = 
	"Custom\0"
	"C64 palette\0"
	"EGA palette\0";
> = 0;

uniform float3 Nostalgia_color_0 <
	ui_type = "color";
	ui_label = "Color 0";
	ui_category = "Custom palette";
> = float3(  0. ,   0. ,   0. ); //Black;

uniform float3 Nostalgia_color_1 <
	ui_type = "color";
	ui_label = "Color 1";
	ui_category = "Custom palette";
> = float3(255. , 255. , 255. ) / 255.; //White

uniform float3 Nostalgia_color_2 <
	ui_type = "color";
	ui_label = "Color 2";
	ui_category = "Custom palette";
> = float3(136. ,   0. ,   0. ) / 255.; //Red;

uniform float3 Nostalgia_color_3 <
	ui_type = "color";
	ui_label = "Color 3";
	ui_category = "Custom palette";
> = float3(170. , 255. , 238. ) / 255.; //Cyan

uniform float3 Nostalgia_color_4 <
	ui_type = "color";
	ui_label = "Color 4";
	ui_category = "Custom palette";
> = float3(204. ,  68. , 204. ) / 255.; //Violet

uniform float3 Nostalgia_color_5 <
	ui_type = "color";
	ui_label = "Color 5";
	ui_category = "Custom palette";
> = float3(  0. , 204. ,  85. ) / 255.; //Green

uniform float3 Nostalgia_color_6 <
	ui_type = "color";
	ui_label = "Color 6";
	ui_category = "Custom palette";
> = float3(  0. ,   0. , 170. ) / 255.; //Blue

uniform float3 Nostalgia_color_7 <
	ui_type = "color";
	ui_label = "Color 7";
	ui_category = "Custom palette";
> = float3(238. , 238. , 119. ) / 255.; //Yellow 1

uniform float3 Nostalgia_color_8 <
	ui_type = "color";
	ui_label = "Color 8";
	ui_category = "Custom palette";
> = float3(221. , 136. ,  85. ) / 255.; //Orange

uniform float3 Nostalgia_color_9 <
	ui_type = "color";
	ui_label = "Color 9";
	ui_category = "Custom palette";
> = float3(102. ,  68. ,   0. ) / 255.; //Brown

uniform float3 Nostalgia_color_10 <
	ui_type = "color";
	ui_label = "Color 10";
	ui_category = "Custom palette";
> = float3(255. , 119. , 119. ) / 255.; //Yellow 2

uniform float3 Nostalgia_color_11 <
	ui_type = "color";
	ui_label = "Color 11";
	ui_category = "Custom palette";
> =float3( 51. ,  51. ,  51. ) / 255.; //Grey 1

uniform float3 Nostalgia_color_12 <
	ui_type = "color";
	ui_label = "Color 12";
	ui_category = "Custom palette";
> = float3(119. , 119. , 119. ) / 255.; //Grey 2

uniform float3 Nostalgia_color_13 <
	ui_type = "color";
	ui_label = "Color 13";
	ui_category = "Custom palette";
> = float3(170. , 255. , 102. ) / 255.; //Lightgreen

uniform float3 Nostalgia_color_14 <
	ui_type = "color";
	ui_label = "Color 14";
	ui_category = "Custom palette";
> = float3(  0. , 136. , 255. ) / 255.; //Lightblue

uniform float3 Nostalgia_color_15 <
	ui_type = "color";
	ui_label = "Color 15";
	ui_category = "Custom palette";
> = float3(187. , 187. , 187. ) / 255.;  //Grey 3


/*-------------.
| :: Effect :: |
'-------------*/

float4 PS_Nostalgia(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, texcoord.xy);
	float3 color = colorInput.rgb;

	float3 palette[16] = //Custom palette
	{
		Nostalgia_color_0,
		Nostalgia_color_1,
		Nostalgia_color_2,
		Nostalgia_color_3,
		Nostalgia_color_4,
		Nostalgia_color_5,
		Nostalgia_color_6,
		Nostalgia_color_7,
		Nostalgia_color_8,
		Nostalgia_color_9,
		Nostalgia_color_10,
		Nostalgia_color_11,
		Nostalgia_color_12,
		Nostalgia_color_13,
		Nostalgia_color_14,
		Nostalgia_color_15
	};

	if (Nostalgia_palette == 1) //C64 palette from http://www.c64-wiki.com/index.php/Color
	{
		palette[0]  = float3(  0. ,   0. ,   0. ) / 255.; //Black
		palette[1]  = float3(255. , 255. , 255. ) / 255.; //White
		palette[2]  = float3(136. ,   0. ,   0. ) / 255.; //Red
		palette[3]  = float3(170. , 255. , 238. ) / 255.; //Cyan
		palette[4]  = float3(204. ,  68. , 204. ) / 255.; //Violet
		palette[5]  = float3(  0. , 204. ,  85. ) / 255.; //Green
		palette[6]  = float3(  0. ,   0. , 170. ) / 255.; //Blue
		palette[7]  = float3(238. , 238. , 119. ) / 255.; //Yellow 1
		palette[8]  = float3(221. , 136. ,  85. ) / 255.; //Orange
		palette[9]  = float3(102. ,  68. ,   0. ) / 255.; //Brown
		palette[10] = float3(255. , 119. , 119. ) / 255.; //Yellow 2
		palette[11] = float3( 51. ,  51. ,  51. ) / 255.; //Grey 1
		palette[12] = float3(119. , 119. , 119. ) / 255.; //Grey 2
		palette[13] = float3(170. , 255. , 102. ) / 255.; //Lightgreen
		palette[14] = float3(  0. , 136. , 255. ) / 255.; //Lightblue
		palette[15] = float3(187. , 187. , 187. ) / 255.; //Grey 3
	}

	if (Nostalgia_palette == 2) //EGA palette
	{
		palette[0] 	= float3(0.0,		0.0,		0.0		); //Black
		palette[1] 	= float3(0.0,		0.0,		0.666667); //Blue
		palette[2] 	= float3(0.0,		0.666667,	0.0		); //Green
		palette[3] 	= float3(0.0,		0.666667,	0.666667); //Cyan
		palette[4] 	= float3(0.666667,	0.0,		0.0		); //Red
		palette[5] 	= float3(0.666667,	0.0,		0.666667); //Magenta
		palette[6] 	= float3(0.666667,	0.333333,	0.0		); //Brown 
		palette[7] 	= float3(0.666667,	0.666667,	0.666667); //Light gray
		palette[8] 	= float3(0.333333,	0.333333,	0.333333); //Dark gray
		palette[9] 	= float3(0.333333,	0.333333,	1.0		); //Bright blue
		palette[10]	= float3(0.333333,	1.0,		0.333333); //Bright green
		palette[11]	= float3(0.333333,	1.0,		1.0		); //Bright cyan
		palette[12]	= float3(1.0,		0.333333,	0.333333); //Bright red
		palette[13]	= float3(1.0,		0.333333,	1.0		); //Bright magenta
		palette[14]	= float3(1.0,		1.0,		0.333333); //Bright yellow
		palette[15]	= float3(1.0,		1.0,		1.0		); //White
	}

	float3 diff = color - palette[0]; //find the difference in color compared to color 0
	
	float dist = dot(diff,diff); //squared distance of difference - we don't need to calculate the square root of this

	float closest_dist = dist; //this has to be the closest distance so far as it's the first we have checked
	float3 closest_color = palette[0]; //and closest color so far is this one

	for (int i = 1 ; i <= 15 ; i++) //for colors 1 to 15
	{
		diff = color - palette[i]; //find the difference in color
	
		dist = dot(diff,diff); //squared distance of difference - we don't need to calculate the square root of this
    
		if (dist < closest_dist) //is the distance closer than the previously closest distance?
		{ 
			closest_dist = dist; //closest distance is now this distance
			closest_color = palette[i]; //closest color is now this color
		}
	}	

	colorInput.rgb = closest_color; //return the pixel
	return colorInput; //return the pixel
}


/*----------------.
| :: Technique :: |
'----------------*/

technique Nostalgia
{
	pass NostalgiaPass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Nostalgia;
	}
}