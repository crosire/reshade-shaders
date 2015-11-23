NAMESPACE_ENTER(BFX)

#include BFX_SETTINGS_DEF

#if USE_DisplayDepth

void PS_DisplayDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
	color.rgb = tex2D(RFX_depthTexColor,texcoord).rrr;
}

technique Depth_Tech < enabled = false; toggle = Depth_ToggleKey;>
{
	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_DisplayDepth;
	}
}

#endif

#include BFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()