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
}

technique DisplayDepth
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DisplayDepth;
	}
}
