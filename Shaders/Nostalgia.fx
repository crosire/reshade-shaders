/*------------------.
| :: Description :: |
'-------------------/

	Nostalgia (version 1.2)

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
	* More Dithering (both good and the bad dithering used back then)
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

	Version 1.2 
	* Added Aek16 palette
	+ Made Nostalgia do color matching in linear space which improves color matching
	* Added checker board dithering
	* Added scanlines

*/


/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"


/*--------------.
| :: Defines :: |
'--------------*/

#ifndef Nostalgia_linear
	#define Nostalgia_linear 1
#endif

/*------------------.
| :: UI Settings :: |
'------------------*/

/*
uniform bool Nostalgia_scanlines
<
	ui_label = "Scanlines";
	//ui_category = "";
> = 1;
*/

uniform int Nostalgia_scanlines
<
	ui_type = "combo";
	ui_label = "Scanlines";
	ui_items = 
	"None\0"
	"Type 1\0"
	"Type 2\0";
	//ui_category = "";
> = 1;

uniform int Nostalgia_color_reduction
<
	ui_type = "combo";
	ui_label = "Color reduction type";
	//ui_tooltip = "Choose a color reduction type";
	//ui_category = "";
	ui_items = 
	"None\0"
	"Palette\0"
	//"Quantize\0"
	;
> = 1;

uniform int Nostalgia_palette
<
	ui_type = "combo";
	ui_label = "Palette";
	ui_tooltip = "Choose a palette";
	//ui_category = "";
	ui_items = 
	"Custom\0"
	"C64 palette\0"
	"EGA palette\0"
	"Aek16 palette";
> = 0;

uniform float3 Nostalgia_color_0
<
	ui_type = "color";
	ui_label = "Color 0";
	ui_category = "Custom palette";
> = float3(  0. ,   0. ,   0. ); //Black;

uniform float3 Nostalgia_color_1
<
	ui_type = "color";
	ui_label = "Color 1";
	ui_category = "Custom palette"; > 
= float3(255. , 255. , 255. ) / 255.; //White

uniform float3 Nostalgia_color_2
<
	ui_type = "color";
	ui_label = "Color 2";
	ui_category = "Custom palette";
> = float3(136. ,   0. ,   0. ) / 255.; //Red;

uniform float3 Nostalgia_color_3
<
	ui_type = "color";
	ui_label = "Color 3";
	ui_category = "Custom palette";
> = float3(170. , 255. , 238. ) / 255.; //Cyan

uniform float3 Nostalgia_color_4
<
	ui_type = "color";
	ui_label = "Color 4";
	ui_category = "Custom palette";
> = float3(204. ,  68. , 204. ) / 255.; //Violet

uniform float3 Nostalgia_color_5
<
	ui_type = "color";
	ui_label = "Color 5";
	ui_category = "Custom palette";
> = float3(  0. , 204. ,  85. ) / 255.; //Green

uniform float3 Nostalgia_color_6
<
	ui_type = "color";
	ui_label = "Color 6";
	ui_category = "Custom palette";
> = float3(  0. ,   0. , 170. ) / 255.; //Blue

uniform float3 Nostalgia_color_7
<
	ui_type = "color";
	ui_label = "Color 7";
	ui_category = "Custom palette";
> = float3(238. , 238. , 119. ) / 255.; //Yellow 1

uniform float3 Nostalgia_color_8
<
	ui_type = "color";
	ui_label = "Color 8";
	ui_category = "Custom palette";
> = float3(221. , 136. ,  85. ) / 255.; //Orange

uniform float3 Nostalgia_color_9 <
	ui_type = "color";
	ui_label = "Color 9";
	ui_category = "Custom palette";
> = float3(102. ,  68. ,   0. ) / 255.; //Brown

uniform float3 Nostalgia_color_10
<
	ui_type = "color";
	ui_label = "Color 10";
	ui_category = "Custom palette";
> = float3(255. , 119. , 119. ) / 255.; //Yellow 2

uniform float3 Nostalgia_color_11
<
	ui_type = "color";
	ui_label = "Color 11";
	ui_category = "Custom palette";
> = float3( 51. ,  51. ,  51. ) / 255.; //Grey 1

uniform float3 Nostalgia_color_12
<
	ui_type = "color";
	ui_label = "Color 12";
	ui_category = "Custom palette";
> = float3(119. , 119. , 119. ) / 255.; //Grey 2

uniform float3 Nostalgia_color_13
<
	ui_type = "color";
	ui_label = "Color 13";
	ui_category = "Custom palette";
> = float3(170. , 255. , 102. ) / 255.; //Lightgreen

uniform float3 Nostalgia_color_14
<
	ui_type = "color";
	ui_label = "Color 14";
	ui_category = "Custom palette";
> = float3(  0. , 136. , 255. ) / 255.; //Lightblue

uniform float3 Nostalgia_color_15
<
	ui_type = "color";
	ui_label = "Color 15";
	ui_category = "Custom palette";
> = float3(187. , 187. , 187. ) / 255.;  //Grey 3

/*
uniform bool Nostalgia_linear //Can't currently make a UI setting for this since I need the preprocessor for that and it does not accept uniforms from the UI
<
	ui_label = "Linear";
	//ui_category = "Color options";
> = 0;
*/

/*--------------.
| :: Sampler :: |
'--------------*/

sampler Linear
{
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
};


/*-------------.
| :: Effect :: |
'-------------*/

float3 PS_Nostalgia(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color;

	#if Nostalgia_linear == 1
		color = tex2D(Linear, texcoord.xy).rgb;
	#else
		color = tex2D(ReShade::BackBuffer, texcoord.xy).rgb;
	#endif

	if (Nostalgia_color_reduction)
	{
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

		if (Nostalgia_palette == 3) //aek16 ( http://eastfarthing.com/blog/2016-05-06-palette/ )
		{
			palette[0] 	= float3(0.247059,	0.196078,	0.682353); //
			palette[0] 	= float3(0.890196,	0.054902,	0.760784); //
			palette[0] 	= float3(0.729412,	0.666667,	1.000000); //
			palette[0] 	= float3(1.,		1.000000,	1.      ); //White
			palette[0] 	= float3(1.000000,	0.580392,	0.615686); //
			palette[0] 	= float3(0.909804,	0.007843,	0.000000); //
			palette[0] 	= float3(0.478431,	0.141176,	0.239216); //
			palette[0] 	= float3(0.,		0.		,	0.		); //Black
			palette[0] 	= float3(0.098039,	0.337255,	0.282353); //
			palette[0] 	= float3(0.415686,	0.537255,	0.152941); //
			palette[0] 	= float3(0.086275,	0.929412,	0.458824); //
			palette[0] 	= float3(0.196078,	0.756863,	0.764706); //
			palette[0] 	= float3(0.019608,	0.498039,	0.756863); //
			palette[0] 	= float3(0.431373,	0.305882,	0.137255); //
			palette[0] 	= float3(0.937255,	0.890196,	0.019608); //
			palette[0] 	= float3(0.788235,	0.560784,	0.298039); //
		}

		// :: Dither :: //
		
		//Calculate grid position
		float grid_position = frac(dot(texcoord, ReShade::ScreenSize * 0.5) + 0.25); //returns 0.25 and 0.75

		//Calculate how big the shift should be
		float dither_shift = (0.25) * (1.0 / (pow(2,2.0) - 1.0)); // 0.25 seems good both when using math and when eyeballing it. So does 0.75 btw.

		//Shift the individual colors differently, thus making it even harder to see the dithering pattern
		float3 dither_shift_RGB = float3(dither_shift, dither_shift, dither_shift); //subpixel dithering

		//modify shift acording to grid position.
		dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

		//shift the color by dither_shift
		//color.rgb += lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.
		color.rgb += dither_shift_RGB;

		
		// :: Color matching :: //
		
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

		color = closest_color; //return the pixel
	}

	if (Nostalgia_scanlines == 1)
	{
		color *= frac(texcoord.y * (ReShade::ScreenSize.y * 0.5)) + 0.5; //Scanlines
	}
	if (Nostalgia_scanlines == 2)
	{
		float grey  = dot(color,float(1.0/3.0));
		color = (frac(texcoord.y * (ReShade::ScreenSize.y * 0.5)) < 0.25) ? color : color * ((-grey*grey+grey+grey) * 0.5 + 0.5);
	}

	return color; //return the pixel
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
		
		#if Nostalgia_linear == 1
			SRGBWriteEnable = true;
		#endif	
		
		ClearRenderTargets = false;
	}
}