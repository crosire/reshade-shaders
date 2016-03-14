#include EFFECT_CONFIG(CeeJay)
#include "Common.fx"

#if USE_DisplayDepth

namespace CeeJay
{

void PS_DisplayDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
	color.rgb = tex2D(ReShade::LinearizedDepth,texcoord).rrr;
}

technique Depth_Tech < enabled = false; toggle = Depth_ToggleKey;>
{
	pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_DisplayDepth;
	}
}

}

#endif

#include EFFECT_CONFIG_UNDEF(CeeJay)
