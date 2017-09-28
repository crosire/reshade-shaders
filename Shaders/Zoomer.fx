/**
 * Zoomer version 1.0
 * Original by ErwanDouaille
 */
uniform bool buttondown < source = "mousebutton"; keycode = 2; toggle = true; >;
uniform float2 mousepoint < source = "mousepoint"; >;

uniform float zoom <
	ui_type = "drag";
	ui_min = 0.01; ui_max = 1.0;
	ui_tooltip = "Zoom";
> = 0.2;

#include "ReShade.fxh"

float3 ZoomerPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 mousePosition = float2(0.5, 0.5); 
    float2 zoomArea = mousePosition + (texcoord-mousePosition)*zoom;
	if (buttondown)
		zoomArea = texcoord;
	float3 color = tex2D(ReShade::BackBuffer, zoomArea).rgb;;
	
	return color;
}

technique Zoomer
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ZoomerPass;
	}
}
