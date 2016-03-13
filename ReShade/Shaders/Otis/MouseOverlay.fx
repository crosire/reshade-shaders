///////////////////////////////////////////////////////////////////
// This effects simply shows the mouse coordinates on the screen. It can be used in combination
// of effects which use the mousecoordinates supplied by ReShade so you can better see what
// you're doing.
///////////////////////////////////////////////////////////////////

#include EFFECT_CONFIG(Otis)
#include "Common.fx"

#if USE_MOUSEOVERLAY

#pragma message "MouseOverlay by Otis\n"

namespace Otis
{
	float4 PS_MouseCoordOverlay(float4 vpos:SV_Position, float2 texcoord: TEXCOORD) :SV_Target
	{
		return all(abs(ReShade::MouseCoords-vpos.xy) < MOL_CursorSize) ? float4(MOL_CursorColor, 1.0) : tex2D(ReShade::BackBuffer, texcoord);
	}

	technique MouseOverlay_Tech < bool enabled = false; int toggle = MOL_ToggleKey; >
	{
		pass MouseOverlay { VertexShader = ReShade::VS_PostProcess; PixelShader = PS_MouseCoordOverlay;	/* renders to backbuffer*/ }
	}
}
#endif

#include EFFECT_CONFIG_UNDEF(Otis)
