///////////////////////////////////////////////////////
// Ported from Reshade v2.x. Original by CeeJay.
// Displays the depth buffer: further away is more white than close by. 
// Use this to configure the depth buffer preprocessor settings
// in Reshade's settings. (The RESHADE_DEPTH_INPUT_* ones)
///////////////////////////////////////////////////////

#include "Reshade.fxh"

void PS_DisplayDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
	color.rgb = ReShade::GetLinearizedDepth(texcoord).rrr;

	float dither_bit  = 8.0;  //Number of bits per channel. Should be 8 for most monitors.
   
	//color = (tex.x*0.3+0.1); //draw a gradient for testing.
	//#define dither_method 2 //override method for testing purposes

	/*------------------------.
	| :: Ordered Dithering :: |
	'------------------------*/
	//Calculate grid position
	float grid_position = frac( dot(texcoord, (ReShade::ScreenSize * float2(1.0/16.0,10.0/36.0)  )+(0.25) ) );

	//Calculate how big the shift should be
	float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0));

	//Shift the individual colors differently, thus making it even harder to see the dithering pattern
	float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

	//modify shift acording to grid position.
	dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

	//shift the color by dither_shift
	color.rgb += dither_shift_RGB;
}

technique DisplayDepth
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DisplayDepth;
	}
}
