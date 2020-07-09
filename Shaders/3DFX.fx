////----------//
////**3DFX**////
//----------////

// !!! adding comments about what this shader seems to do
/*
	Seems to be trying to emulate 4x1 linear filter from
	3DFX Voodoo graphics cards. I think the original shader
	code is here...

	http://leileilol.mancubus.net/shaders/

	Shader is a mixed bag. Seems to just create thin scanlines
	on a increased gamma image. On 3D FPS games (eg: Daggerfall
	Unity) it creates artifacts of outlines of things at certain
	viewing angles. EG: looking at a column, it will create lines
	that twist around the column, or looking at a tree line it
	will create an inverse outline of the tree line at the bottom
	of the screen. So, not sure if this is doing what was intended.
	Or, it might be best for 2D.
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

uniform float DITHERAMOUNT < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Dither Amount [3DFX]";
> = 0.5;

uniform int DITHERBIAS < __UNIFORM_SLIDER_INT1
	ui_min = -16;
	ui_max = 16;
	ui_label = "Dither Bias [3DFX]";
> = -1;

uniform float LEIFX_LINES < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0;
	ui_max = 2.0;
	ui_label = "Lines Intensity [3DFX]";
> = 1.0;

uniform float LEIFX_PIXELWIDTH < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0;
	ui_max = 100.0;
	ui_label = "Pixel Width [3DFX]";
> = 1.5;

uniform float GAMMA_LEVEL < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0;
	ui_max = 3.0;
	ui_label = "Gamma Level [3DFX]";
> = 1.0;

#ifndef FILTCAP
	#define	FILTCAP	  0.04	//[0.0:100.0] //-filtered pixel should not exceed this
#endif

#ifndef FILTCAPG
	#define	FILTCAPG (FILTCAP/2)
#endif

float mod2(float x, float y)
{
	return x - y * floor (x/y);
}

float fmod(float a, float b)
{
  float c = frac(abs(a/b))*abs(b);
  return (a < 0) ? -c : c;   /* if ( a < 0 ) c = 0-c */
}

// !!! making overloaded float2 version
// !!! to do per-component math on parts
// !!! below doing fmod to x & y
float2 fmod(float2 a, float2 b)
{
  float2 c = frac(abs(a/b)) * abs(b);
  return (a < 0) ? -c : c;   /* if ( a < 0 ) c = 0-c */
}

float4 PS_3DFX(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, texcoord);

	float2 res = BUFFER_SCREEN_SIZE;
	
	float2 ditheu = texcoord.xy * res.xy;

	// !!! already set this when declared variable
//	ditheu.x = texcoord.x * res.x;
//	ditheu.y = texcoord.y * res.y;

	// Dither. Total rewrite.
	// NOW, WHAT PIXEL AM I!??

//	int ditx = int(fmod(ditheu.x, 4.0));
//	int dity = int(fmod(ditheu.y, 4.0));
//	int ditdex = ditx * 4 + dity; // 4x4!

	// !!! re-doing this using float2 fmod()
	int2 dit = int2(fmod(ditheu.xy, 4.0));
	int ditdex = dit.x * 4 + dit.y; // 4x4!

//	float3 color;
//	float3 colord;
//	color.r = colorInput.r * 255;
//	color.g = colorInput.g * 255;
//	color.b = colorInput.b * 255;

	// !!! can create var & set it with per-component math
	float3 color = colorInput.rgb * 255.0;

//	int yeh = 0;	// !!! no longer needed, b/c nuked if/else
	int ohyes = 0;

	/*
	// original
	float erroredtable[16] = {
	16,4,13,1,   
	8,12,5,9,
	14,2,15,3,
	6,10,7,11		
	};
	*/
	
	// !!! adding const recommender
	// !!! spacing values to look nicer
	const float erroredtable[16] = {
			16,  4, 13,  1,   
			 8, 12,  5,  9,
			14,  2, 15,  3,
			 6, 10,  7, 11		
		};

	/*
	// original
	// looping through a lookup table matrix
	//for (yeh=ditdex; yeh<(ditdex+16); yeh++) ohyes = pow(erroredtable[yeh-15], 0.72f);
	// Unfortunately, RetroArch doesn't support loops so I have to unroll this. =(
	// Dither method adapted from xTibor on Shadertoy ("Ordered Dithering"), generously
	// put into the public domain.  Thanks!
	if (yeh++==ditdex) ohyes = erroredtable[0];
	else if (yeh++==ditdex) ohyes = erroredtable[1];
	else if (yeh++==ditdex) ohyes = erroredtable[2];
	else if (yeh++==ditdex) ohyes = erroredtable[3];
	else if (yeh++==ditdex) ohyes = erroredtable[4];
	else if (yeh++==ditdex) ohyes = erroredtable[5];
	else if (yeh++==ditdex) ohyes = erroredtable[6];
	else if (yeh++==ditdex) ohyes = erroredtable[7];
	else if (yeh++==ditdex) ohyes = erroredtable[8];
	else if (yeh++==ditdex) ohyes = erroredtable[9];
	else if (yeh++==ditdex) ohyes = erroredtable[10];
	else if (yeh++==ditdex) ohyes = erroredtable[11];
	else if (yeh++==ditdex) ohyes = erroredtable[12];
	else if (yeh++==ditdex) ohyes = erroredtable[13];
	else if (yeh++==ditdex) ohyes = erroredtable[14];
	else if (yeh++==ditdex) ohyes = erroredtable[15];
	*/
	
	// !!! not sure what he's trying to accomplish up above
	// !!! he's looping through to see...
	// !!!      if 0 = 0 .. pick value[0]
	// !!! else if 1 = 1 .. pick value[1]
	// !!! etc
	// !!! it makes no sense and just wastes processing.
	// !!! just pick the value at ditdex, and get
	// !!! on with life.
	// !!! also, he says to pow(value, 0.72f)
	// !!! but doesn't do that.. so I guess the
	// !!! errordtable values are already pow'ed?

	ohyes = erroredtable[ditdex];

	// !!! experimenting with doing the pow'ing suggested
	// !!! in original shader comments above to see what happens
	// !!! after messing around, doesn't seem to make a difference
//	ohyes = pow( ohyes, 0.72f);


	// Adjust the dither thing
//	ohyes = 17 - (ohyes - 1); // invert
//	ohyes *= DITHERAMOUNT;
//	ohyes += DITHERBIAS;

	// !!! again, not sure why he coded like
	// !!! above, but can just pre-subtract
	// !!! the 17 & 1
	ohyes = 16 - ohyes; // invert

	// !!! this might MAD better
	ohyes = ohyes * DITHERAMOUNT + DITHERBIAS;

//	colord.r = color.r + ohyes;
//	colord.g = color.g + (ohyes / 2);
//	colord.b = color.b + ohyes;

	// !!! moving var declaration down to where it's being worked with
	// !!! also altering declaration to streamline with per-component math
	float3 colord = color;
	colord.rb += ohyes;
	colord.g += (ohyes / 2);

	colorInput.rgb = colord.rgb * 0.003921568627451; // divide by 255, i don't trust em

	//
	// Reduce to 16-bit color
	//

	/*
	// original
	float why = 1;
	float3 reduceme = 1;
	float radooct = 32;	// 32 is usually the proper value

	reduceme.r = pow(colorInput.r, why);  
	reduceme.r *= radooct;	
	reduceme.r = float(floor(reduceme.r));	
	reduceme.r /= radooct; 
	reduceme.r = pow(reduceme.r, why);

	reduceme.g = pow(colorInput.g, why);  
	reduceme.g *= radooct * 2;	
	reduceme.g = float(floor(reduceme.g));	
	reduceme.g /= radooct * 2; 
	reduceme.g = pow(reduceme.g, why);

	reduceme.b = pow(colorInput.b, why);  
	reduceme.b *= radooct;	
	reduceme.b = float(floor(reduceme.b));	
	reduceme.b /= radooct; 
	reduceme.b = pow(reduceme.b, why);
	*/
	
	// !!! re-doing this with per-component math
//	float why = 1;
	float3 reduceme = colorInput.rgb;		// !!! can just set this to colorInput.rgb at start
	const float radooct = 32;	// 32 is usually the proper value // !!! making const

//	reduceme = pow(reduceme, why);  		// !!! why = 1, so this is pointless
	reduceme *= radooct;
	reduceme = floor(reduceme);			// !!! shouldn't have to convert floor's output to float
	reduceme /= radooct; 
//	reduceme.r = pow(reduceme.r, why);		// !!! why = 1, so this is pointless
	


	colorInput.rgb = reduceme.rgb;

	// !!! removed braces around this.. not necessary
	// !!! un-tabbed contents one step

	// Add the purple line of lineness here, so the filter process catches it and gets gammaed.
//	{

//	float leifx_linegamma = (LEIFX_LINES / 10);
//	float horzline1 = 	(fmod(ditheu.y, 2.0));
//	if (horzline1 < 1)	leifx_linegamma = 0;

	// !!! re-arranging this
	float leifx_linegamma;
	float horzline1 = 	fmod(ditheu.y, 2.0);	// !!! removed unnecessary parenthesis

	// !!! converting this to if/else
	// !!! b/c no sense in calc'ing leifx_linegamma above
	// !!! if we might just make it 0 here, so calc it here
	if (horzline1 < 1)
		leifx_linegamma = 0;
	else
		leifx_linegamma = LEIFX_LINES / 10;	// !!! removed unnecessary parenthesis

//	colorInput.r += leifx_linegamma;
//	colorInput.g += leifx_linegamma;
//	colorInput.b += leifx_linegamma;	

	// !!! can do all this with per-component math
	colorInput.rgb += leifx_linegamma;
//	}

   return colorInput;
}

float4 PS_3DFX1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, texcoord);

//	float2 pixel = BUFFER_PIXEL_SIZE;
//	float3 pixel1 = tex2D(ReShade::BackBuffer, texcoord + float2((pixel.x), 0)).rgb;
//	float3 pixel2 = tex2D(ReShade::BackBuffer, texcoord + float2(-pixel.x, 0)).rgb;
//	float3 pixelblend; // !!! not used

	// !!! making cleaner offsets
	// !!! and getting rid of pointless +0 math
	// !!! (P)ositive, (N)egative
	float2 texcoordP = texcoord;
	float2 texcoordN = texcoord;
	texcoordP.x += BUFFER_PIXEL_SIZE.x;
	texcoordN.x -= BUFFER_PIXEL_SIZE.x;
	float3 pixel1 = tex2D(ReShade::BackBuffer, texcoordP).rgb;
	float3 pixel2 = tex2D(ReShade::BackBuffer, texcoordN).rgb;

	/*
	// original
	// New filter
	{
		float3 pixeldiff;
		float3 pixelmake;		
		float3 pixeldiffleft;

		pixelmake.rgb = 0;
		pixeldiff.rgb = pixel2.rgb- colorInput.rgb;

		pixeldiffleft.rgb = pixel1.rgb - colorInput.rgb;

		if (pixeldiff.r > FILTCAP) 		pixeldiff.r = FILTCAP;
		if (pixeldiff.g > FILTCAPG) 		pixeldiff.g = FILTCAPG;
		if (pixeldiff.b > FILTCAP) 		pixeldiff.b = FILTCAP;

		if (pixeldiff.r < -FILTCAP) 		pixeldiff.r = -FILTCAP;
		if (pixeldiff.g < -FILTCAPG) 		pixeldiff.g = -FILTCAPG;
		if (pixeldiff.b < -FILTCAP) 		pixeldiff.b = -FILTCAP;

		if (pixeldiffleft.r > FILTCAP) 		pixeldiffleft.r = FILTCAP;
		if (pixeldiffleft.g > FILTCAPG) 	pixeldiffleft.g = FILTCAPG;
		if (pixeldiffleft.b > FILTCAP) 		pixeldiffleft.b = FILTCAP;

		if (pixeldiffleft.r < -FILTCAP) 	pixeldiffleft.r = -FILTCAP;
		if (pixeldiffleft.g < -FILTCAPG) 	pixeldiffleft.g = -FILTCAPG;
		if (pixeldiffleft.b < -FILTCAP) 	pixeldiffleft.b = -FILTCAP;

		pixelmake.rgb = (pixeldiff.rgb / 4) + (pixeldiffleft.rgb / 16);
		colorInput.rgb = (colorInput.rgb + pixelmake.rgb);
	}	
	*/
	
	// !!! removed pointless braces
	// !!! un-tabbled contents up a step
	float3 pixeldiff = pixel2.rgb - colorInput.rgb;
	float3 pixeldiffleft = pixel1.rgb - colorInput.rgb;

	// !!! all the if statements were just
	// !!! over-engineered clamp / saturation
	float3 rangemax = float3( FILTCAP, FILTCAPG, FILTCAP );
	float3 rangemin = -rangemax;

	pixeldiff = clamp( pixeldiff, rangemin, rangemax );
	pixeldiffleft = clamp( pixeldiffleft, rangemin, rangemax );

	float3 pixelmake = (pixeldiff / 4) + (pixeldiffleft / 16);
	colorInput.rgb += pixelmake.rgb;

	return colorInput;
}

float4 PS_3DFX2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, texcoord);

	// Gamma scanlines
	// the Voodoo drivers usually supply a 1.3 gamma setting whether people liked it or not
	// but it was enough to brainwash the competition for looking 'too dark'

//	colorInput.r = pow(abs(colorInput.r), 1.0 / GAMMA_LEVEL);
//	colorInput.g = pow(abs(colorInput.g), 1.0 / GAMMA_LEVEL);
//	colorInput.b = pow(abs(colorInput.b), 1.0 / GAMMA_LEVEL);

	// !!! can do this all in one shot with per-component math
	colorInput.rgb = pow(abs(colorInput.rgb), 1.0 / GAMMA_LEVEL);

	return colorInput;
}

technique LeiFx_Tech
{
	pass LeiFx
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_3DFX;
	}
	pass LeiFx1
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_3DFX1;
	}
	pass LeiFx2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_3DFX1;
	}
	pass LeiFx3
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_3DFX1;
	}
	pass LeiFx4
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_3DFX1;
	}
	pass LeiFx5
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_3DFX2;
	}
}
