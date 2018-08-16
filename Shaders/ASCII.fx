  /*------------.
  | :: Ascii :: |
  '------------*/
/*
  Ascii by Christian Cann Schuldt Jensen ~ CeeJay.dk
  (Version 0.8)

	Converts the image to ASCII characters using a greyscale algoritm,
	cherrypicked characters and a custom bitmap font stored in a set of floats.
	
	It has 17 gray levels but uses dithering to greatly increase that number.

History :	
-- Version 0.7 by CeeJay.dk -- 
   Added the 3x5 font
-- Version 0.8 by CeeJay.dk -- 
   Cleaned up settings UI for Reshade 3.x
*/

#include "ReShade.fxh"

  /*------------------.
  | :: UI Settings :: |
  '------------------*/

/*
  uniform float Version <
	ui_label = "Version";
	ui_min = 0.8;
	ui_max = 0.8;
	ui_step = 1.0;
	ui_category = "Author : CeeJay.dk\n\nTo increase the size of the characters on screen simply lower your resolution in-game\n\nTry using this with Nostagia or EGA. It also looks best if you first increase the contrast with Curves.\n\n";
> = float(0.8);
*/
uniform int Ascii_spacing <
	ui_type = "drag";
	ui_min = 0;
	ui_max = 5;
	ui_label = "Character Spacing";
	ui_tooltip = "Determines the spacing between characters. I feel 1 to 3 looks best.";
	ui_category = "Font style";
> = 1;

uniform int Ascii_font <
	ui_type = "drag";
	ui_min = 1;
	ui_max = 2;
	ui_label = "Font Size";
	ui_tooltip = "1 = 5x5 font, 2 = 3x5 font";
	ui_category = "Font style";
> = 1;

/*
uniform int Ascii_font <
	ui_type = "combo";
	ui_label = "Font Size";
	ui_tooltip = "1 = 5x5 font, 2 = 3x5 font";
	ui_category = "Font style";
	ui_items = "5x5 font\03x5 font\0";
> = 1;
*/

uniform int Ascii_font_color_mode < 
	ui_type = "drag";
	ui_min = 0;
	ui_max = 2;
	ui_label = "Font Color Mode";
	ui_tooltip = "0 = Foreground color on background color, 1 = Colorized grayscale, 2 = Full color";
	ui_category = "Color options";
> = 1;

uniform float3 Ascii_font_color <
	ui_type = "color";
	ui_label = "Font Color";
	ui_tooltip = "Choose a font color";
	ui_category = "Color options";
> = float3(1.0, 1.0, 1.0);

uniform float3 Ascii_background_color <
	ui_type = "color";
	ui_label = "Background Color";
	ui_tooltip = "Choose a background color";
	ui_category = "Color options";
> = float3(0.0, 0.0, 0.0);

uniform bool Ascii_swap_colors <
	ui_label = "Swap Colors";
	ui_tooltip = "Swaps the font and background color when you are too lazy to edit the settings above (I know I am)";
	ui_category = "Color options";
> = 0;

uniform bool Ascii_invert_brightness <
	ui_label = "Invert Brightness";
	ui_category = "Color options";
> = 0;

uniform bool Ascii_dithering_temporal <
	ui_label = "Temporal Dithering";
	ui_category = "Dithering";
> = 0;

#define asciiSampler ReShade::BackBuffer

uniform float timer < source = "timer"; >;
uniform float framecount < source = "framecount"; >;


float3 AsciiPass( float2 tex )
{

  /*-------------------------.
  | :: Sample and average :: |
  '-------------------------*/
	
	float2 Ascii_font_size = float2(0.0,0.0); //3x5
	float num_of_chars = 0. ; 
	
  if (Ascii_font == 2){
		Ascii_font_size = float2(3.0,5.0); //3x5
		num_of_chars = 14. ; 
  } else { //Ascii_font == 1
		Ascii_font_size = float2(5.0,5.0); //5x5
		num_of_chars = 17.; 
  }
  
  
  float2 Ascii_block = Ascii_font_size + float(Ascii_spacing);
  float2 cursor_position = trunc((ReShade::ScreenSize / Ascii_block) * tex) * (Ascii_block / ReShade::ScreenSize);


/*
	//-- Pattern 1 --
  float3 color = tex2D(asciiSampler, cursor_position + float2(3.5,4.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2(2.5,2.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2(4.5,1.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2(5.5,3.5) * ReShade::PixelSize).rgb;
  
  color *= 0.25;
*/
/*

	//-- Pattern 1b --
  float3 color = tex2D(asciiSampler, cursor_position + float2(2.5,0.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2(0.5,4.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2(6.5,2.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2(4.5,6.5) * ReShade::PixelSize).rgb;
  
  color *= 0.25;
*/
	

  //-- Pattern 2 - Sample ALL the pixels! --
  float3 color = tex2D(asciiSampler, cursor_position + float2( 1.5, 1.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 1.5, 3.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 1.5, 5.5) * ReShade::PixelSize).rgb;
  //color += tex2D(asciiSampler, cursor_position + float2( 0.5, 6.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 3.5, 1.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 3.5, 3.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 3.5, 5.5) * ReShade::PixelSize).rgb;
  //color += tex2D(asciiSampler, cursor_position + float2( 2.5, 6.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 5.5, 1.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 5.5, 3.5) * ReShade::PixelSize).rgb;
  color += tex2D(asciiSampler, cursor_position + float2( 5.5, 5.5) * ReShade::PixelSize).rgb;
  //color += tex2D(asciiSampler, cursor_position + float2( 4.5, 6.5) * ReShade::PixelSize).rgb;
  //color += tex2D(asciiSampler, cursor_position + float2( 6.5, 0.5) * ReShade::PixelSize).rgb;
  //color += tex2D(asciiSampler, cursor_position + float2( 6.5, 2.5) * ReShade::PixelSize).rgb;
  //color += tex2D(asciiSampler, cursor_position + float2( 6.5, 4.5) * ReShade::PixelSize).rgb;
  //color += tex2D(asciiSampler, cursor_position + float2( 6.5, 6.5) * ReShade::PixelSize).rgb;

  color /= 9.0;


/*	
	//-- Pattern 3 - Just one --
	float3 color = tex2D(asciiSampler, cursor_position + float2(4.0,4.0) * ReShade::PixelSize)	.rgb;
*/
	
  /*------------------------.
  | :: Make it grayscale :: |
  '------------------------*/
  
  float luma = 0;
    luma = dot(color,float3(0.2126, 0.7152, 0.0722));
  
  float gray = luma;

	if (Ascii_invert_brightness){
		gray = 1.0 - gray;
	}
  
  //gray = smoothstep(0.0,1.0,gray); //increase contrast
  //gray = lerp(1.0-luma,gray, 0.);
  //gray = cursor_position.x; //horizontal test gradient
  //gray = cursor_position.y; //vertical test gradient
  //gray = (cursor_position.x + cursor_position.y) * 0.5; //diagonal test gradient
  
  /*-------------------.
  | :: Get position :: |
  '-------------------*/
	
	float2 p = frac((ReShade::ScreenSize / Ascii_block) * tex);  //p is the position of the current pixel inside the character

	p = trunc(p * Ascii_block);
	//p = trunc(p * Ascii_block - float2(1.5,1.5)) ;

  float x = (Ascii_font_size.x * p.y + p.x);
  
  /*----------------.
  | :: Dithering :: |
  '----------------*/

  if (Ascii_dithering_temporal == 1){
	float even_frame = (frac(framecount * 0.5) < 0.25) ? -1.0 : 1.0;
    //float even_frame = (frac(timer / (1000. / 59.9 * 2.)) <= 0.50) ? -1.0 : 1.0;
  }

  //TODO : Try make an ordered dither rather than the random dither. Random looks a bit too noisy for my taste.	

  //Pseudo Random Number Generator
  // -- PRNG 1 - Reference --
  float seed = dot(cursor_position, float2(12.9898,78.233)); //I could add more salt here if I wanted to
  float sine = sin(seed); //cos also works well. Sincos too if you want 2D noise.
  float noise = frac(sine * 43758.5453 + cursor_position.y);

  //Calculate how big the shift should be
  //float dither_shift = (2.0 / num_of_chars) * pingpong.y; // Using noise to determine shift.
  //float dither_shift = (2.0 / num_of_chars) * even_frame; // Using noise to determine shift.
  
  float dither_shift = (2.0 / num_of_chars); // Using noise to determine shift.
  float dither_shift_half = (dither_shift * 0.5); // The noise should vary between +- 0.5
  dither_shift = dither_shift * noise - dither_shift_half; // MAD

  //shift the color by dither_shift
  gray += dither_shift; //subpixel dithering

  /*---------------------------.
  | :: Convert to character :: |
  '---------------------------*/
	
   float n = 0;
   
	if (Ascii_font == 2){
		// -- 3x5 bitmap font by CeeJay.dk --
		//float num_of_chars = 14. ; // I moved this up
		// .:^"+cSoFA2O8

		float n12   = (gray < (2./num_of_chars))  ? 4096.			: 1040.  	 	; // . or :
		float n34   = (gray < (4./num_of_chars))  ? 5136.			: 5200.     ; // ; or s
		float n56   = (gray < (6./num_of_chars))  ? 2728.			: 11088.		; // * or o
		float n78   = (gray < (8./num_of_chars))  ? 14478.  	: 11114.		; // S or O 
		float n910  = (gray < (10./num_of_chars)) ? 23213. : 15211.	      ; // X or D
		float n1112 = (gray < (12./num_of_chars)) ? 23533. : 31599.	      ; // H or 0
		float n13 = 31727.; // 8
		
		/* Font reference :
		
		3  ^ 42.
		3  - 448.
		3  i (short) 9232.
		3  ; 5136. ++
		4  " 45.
		4  i 9346.
		4  s 5200. ++
		5  + 1488.
		5  * 2728. ++
		6  c 25200.
		6  o 11088. ++
		7  v 11112.
		7  S 14478. ++
		8  O 11114. ++
		9  F 5071.
		9  5 (rounded) 14543.
		9  X 23213. ++
		10 A 23530.
		10 D 15211. +
		11 H 23533. +
		11 5 (square) 31183.
		11 2 (square) 29671. ++
		
		5 (rounded) 14543.
		*/

		float n1234     = (gray < (3./num_of_chars))  ? n12   : n34;
		float n5678     = (gray < (7./num_of_chars))  ? n56   : n78;
		float n9101112  = (gray < (11./num_of_chars)) ? n910  : n1112;

		float n12345678 = (gray < (5./num_of_chars)) ? n1234 : n5678;
		float n910111213 = (gray < (13./num_of_chars)) ? n9101112 : n13;

		n = (gray < (9./num_of_chars)) ? n12345678 : n910111213;

	} else { // Ascii_font == 1 , the 5x5 font
	
		// -- 5x5 bitmap font by CeeJay.dk --
		//float num_of_chars = 17. ; // I moved this up
		// .:^"~cvo*wSO8Q0#

		float n12   = (gray < (2./num_of_chars))  ? 4194304.  : 131200.  ; // . or :
		float n34   = (gray < (4./num_of_chars))  ? 324.      : 330.     ; // ^ or "
		float n56   = (gray < (6./num_of_chars))  ? 283712.   : 12650880.; // ~ or c  10627072 283712
		float n78   = (gray < (8./num_of_chars))  ? 4532768.  : 13191552.; // v or o
		float n910  = (gray < (10./num_of_chars)) ? 10648704. : 11195936.; // * or w
		float n1112 = (gray < (12./num_of_chars)) ? 15218734. : 15255086.; // S or O
		float n1314 = (gray < (14./num_of_chars)) ? 15252014. : 32294446.; // 8 or Q
		float n1516 = (gray < (16./num_of_chars)) ? 15324974. : 11512810.; // 0 or #

		float n1234     = (gray < (3./num_of_chars))  ? n12   : n34;
		float n5678     = (gray < (7./num_of_chars))  ? n56   : n78;
		float n9101112  = (gray < (11./num_of_chars)) ? n910  : n1112;
		float n13141516 = (gray < (15./num_of_chars)) ? n1314 : n1516;

		float n12345678 = (gray < (5./num_of_chars)) ? n1234 : n5678;
		float n910111213141516 = (gray < (13./num_of_chars)) ? n9101112 : n13141516;

		n = (gray < (9./num_of_chars)) ? n12345678 : n910111213141516; 
	}


	/*--------------------------------.
  	| :: Decode character bitfield :: |
 	'--------------------------------*/
  
	float character = 0.0;
	
	//test values
	//n = -(exp2(24.)-1.0); //-(2^24-1) All bits set - a white 5x5 box

	float lit = (gray <= (1./num_of_chars)) //if black then set all pixels to black (the space character)
		? 0.0
		: 1.0 ;

	float signbit = (n < 0.0) //is n negative? (I would like to test for negative 0 here too but can't)
		? lit 
		: 0.0 ;

	signbit = (x > 23.5) //is this the first pixel in the character?
		? signbit
		: 0.0 ;

	//character = floor( frac( abs( 0.5*n*exp2(-x))) * 2.0);
	//character = floor( frac( abs( n*exp2(-x-1.0))) * 2.0);
	//character = float( frac( abs( n*exp2(-x-1.0))) >= 0.5);

	//Division exp2
	//character = float( frac( abs( n/exp2(x+1.0))) > 0.50); //works on intel and Ipad - not on AMD

	//character = float( frac( abs( n/exp2(x+1.0))) >= 0.50); //works on AMD - not on intel (wait now it works on intel)      

	//Division pow
	//character = float( frac( abs( n/pow(2.0,x+1.0))) >= 0.50); //works on AMD and intel

	//Multiply exp2
	//character = float( frac( abs( n*exp2(-x-1.0))) >= 0.5); //works on AMD and intel

	//Tenary Division exp2
	//character = ( frac( abs( n/exp2(x+1.0))) >= 0.5) ? lit : signbit; //works on AMD and intel

	//Tenary Multiply exp2
	character = ( frac( abs( n*exp2(-x-1.0))) >= 0.5) ? lit : signbit; //works on AMD and intel

	//if (clamp(p.x, 0.0, 4.0) != p.x || clamp(p.y, 0.0, 4.0) != p.y)
	if (clamp(p.x, 0.0, Ascii_font_size.x - 1.0) != p.x || clamp(p.y, 0.0, Ascii_font_size.y - 1.0) != p.y)
  character = 0.0;

  /*---------------.
  | :: Colorize :: |
  '----------------*/
  
	if (Ascii_swap_colors){
		if (Ascii_font_color_mode  == 2){
			color = (character) ? character * color : Ascii_font_color;
		} else if (Ascii_font_color_mode  == 1){
			color = (character) ? (Ascii_background_color) * gray : Ascii_font_color;	
		} else { // Ascii_font_color_mode == 0 
			color = (character) ? (Ascii_background_color) : Ascii_font_color;
		}
	} else {
			
	if (Ascii_font_color_mode  == 2){
		color = (character) ? character * color : Ascii_background_color;
		} else if (Ascii_font_color_mode  == 1) {
			color = (character) ? (Ascii_font_color) * gray : Ascii_background_color;	
		} else {// Ascii_font_color_mode == 0 
			color = (character) ? (Ascii_font_color) : Ascii_background_color;
		}
	}
		

	//colorInput.rgb = saturate(colorInput.rgb);
	//colorInput.rgb = pow(colorInput.rgb, 0.5);
	//colorInput.rgb = sqrt(colorInput.rgb);
    
  /*-------------.
  | :: Return :: |
  '-------------*/
	
	//color = gray;
  return saturate(color);
}


float3 PS_Ascii(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{  
	float3 color = AsciiPass(texcoord);
	return color.rgb;
}


technique ASCII {
	pass ASCII {
		VertexShader=PostProcessVS;
		PixelShader=PS_Ascii;
	}
}


/*
  .---------------------.
  | :: Character set :: |
  '---------------------'

Here are some various chacters and gradients I created in my quest to get the best look

 .'~:;!>+=icjtJY56SXDQKHNWM
 .':!+ijY6XbKHNM
 .:%oO$8@#M
 .:+j6bHM
 .:coCO8@
 .:oO8@
 .:oO8
 :+#

 .:^"~cso*wSO8Q0# 
 .:^"~csoCwSO8Q0#
 .:^"~c?o*wSO8Q0#

n value // # of pixels // character
-----------//----//-------------------
4194304.   //  1 // . (bottom aligned) *
131200.    //  2 // : (middle aligned) *
4198400.   //  2 // : (bottom aligned)
132.			 //  2 // ' 
2228352.   //  3 // ;
4325504.   //  3 // i (short)
14336.     //  3 // - (small)
324.       //  3 // ^
4329476.   //  4 // i (tall)
330.       //  4 // "
31744.     //  5 // - (larger)
283712.    //  5 // ~
10627072.  //  5 // x
145536.    //  5 // * or + (small and centered) 
6325440.   //  6 // c (narrow - left aligned)
12650880.  //  6 // c (narrow - center aligned)
9738240.   //  6 // n (left aligned)
6557772.   //  7 // s (tall)
8679696.   //  7 // f
4532768.   //  7 // v (1st)
4539936.   //  7 // v (2nd)
4207118.   //  7 // ?
-17895696. //  7 // %
6557958.   //  7 // 3  
6595776.   //  8 // o (left aligned)
13191552.  //  8 // o (right aligned)
14714304.  //  8 // c (wide)
12806528.  //  9 // e (right aligned)
332772.    //  9 // * (top aligned)
10648704.  //  9 // * (bottom aligned)
4357252.   //  9 // +
-18157904. //  9 // X
11195936.  // 10 // w
483548.    // 10 // s (thick)
15218734.  // 11 // S 
31491134.  // 11 // C   
15238702.  // 11 // C (rounded)
22730410.  // 11 // M (more like a large m)
10648714.  // 11 // * (larger)
4897444.   // 11 // * (2nd larger)
14726438.  // 11 // @ (also looks like a large e)
23385164.  // 11 // &
15255086.  // 12 // O
16267326.  // 13 // S (slightly larger)
15252014.  // 13 // 8
15259182.  // 13 // 0  (O with dot in the middle)
15517230.  // 13 // Q (1st)
-18405232. // 13 // M
-11196080. // 13 // W
32294446.  // 14 // Q (2nd)
15521326.  // 14 // Q (3rd)
32298542.  // 15 // Q (4th)
15324974.  // 15 // 0 or Ø
16398526.  // 15 // $
11512810.  // 16 // #
-33061950. // 17 // 5 or S (stylized)
-33193150. // 19 // $ (stylized)
-33150782. // 19 // 0 (stylized)



Idea! - try :  .';"~cvo*wSO8Q0# 
by making shades close to each other use characters that are far from each other visually I might space out the dots and create a smoother looking gradient.
Especially with dithering enabled.

Instead of
 .:.:.:.
 :.:.:.:
 .:.:.:.
 :.:.:.:

I might use
 .'.'.'.
 '.'.'.'
 .'.'.'.
 '.'.'.'

UPDATE: That didn't work. It looks messy when characters differ in position like this.
*/
