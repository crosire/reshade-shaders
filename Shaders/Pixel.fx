#include "ReShade.fxh"
#include "ReShadeUI.fxh"

/*
Pixel.fx
This is a shader that just reduces the apparent screen resolution.
Have fun!
*/

uniform float _ResolutionX <
	ui_type = "input";
	ui_tooltip = "Sets the screen width in pixels. For best results, use an integer that cleanly divides your screen resolution.";
> = 480.0;

float4 PS_Pixel (float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 temp = texcoord;
	float2 ratio = float2(1/_ResolutionX, 16/(9*_ResolutionX));
	temp -= (texcoord % ratio) - (0.5/_ResolutionX);
	float4 col = tex2D(ReShade::BackBuffer, temp);
	return col;
}

technique Pixel{
	pass Pixel{
		VertexShader=PostProcessVS;
		PixelShader = PS_Pixel;
	}
}