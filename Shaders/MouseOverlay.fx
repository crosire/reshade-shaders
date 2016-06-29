///////////////////////////////////////////////////////////////////
// This effects simply shows the mouse coordinates on the screen. It can be used in combination
// of effects which use the mousecoordinates supplied by ReShade so you can better see what
// you're doing.
///////////////////////////////////////////////////////////////////
// By Otis / Infuse Project
///////////////////////////////////////////////////////////////////

uniform int CursorSize <
	ui_type = "drag";
	ui_min = 1; ui_max = 100;
	ui_tooltip = "The x and y size of the element displayed at the location of the mouse coordinates, in pixels";
> = 3;
uniform float3 CursorColor <
	ui_type = "color";
	ui_tooltip = "Specifies the color of the element displayed at the location of the mouse coordinates. (r, g, b)";
> = float3(1.0, 0.0, 0.0);

#include "Reshade.fxh"

uniform float2 MouseCoords < source = "mousepoint"; > ;

float4 PS_MouseCoordOverlay(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return all(abs(MouseCoords - vpos.xy) < CursorSize) ? float4(CursorColor, 1.0) : tex2D(ReShade::BackBuffer, texcoord);
}

technique MouseOverlay
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_MouseCoordOverlay;
	}
}
