///////////////////////////////////////////////////////////////////
// This effects simply shows the mouse coordinates on the screen. It can be used in combination
// of effects which use the mousecoordinates supplied by ReShade so you can better see what
// you're doing.
///////////////////////////////////////////////////////////////////

#include "Reshade.fxh"

// Constants
#define MOL_ToggleKey VK_PAUSE

// Variables. 
uniform int CursorSize < ui_type="int"; ui_min=1; ui_max=100; ui_tooltip="The x and y size of the element displayed at the location of the mouse coordinates, in pixels"> = 3;
uniform float3 CursorColor < ui_type="float3"; ui_tooltip="Specifies the color of the element displayed at the location of the mouse coordinates. (r, g, b)"> = float3(1.0, 0.0, 0.0);
//uniform int _toggleKey < ui_type="int"; ui_min=0; ui_max=255; ui_tooltip="Toggle key for this effect"> = VK_PAUSE;

// Code
float4 PS_MouseCoordOverlay(float4 vpos:SV_Position, float2 texcoord: TEXCOORD) :SV_Target
{
	return all(abs(MouseCoords-vpos.xy) < CursorSize) ? float4(CursorColor, 1.0) : tex2D(BackBuffer, texcoord);
}

technique MouseOverlay < bool enabled = false; int toggle = MOL_ToggleKey; >
{
	pass MouseOverlayPass { VertexShader = VS_PostProcess; PixelShader = PS_MouseCoordOverlay;	/* renders to backbuffer*/ }
}
