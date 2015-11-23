NAMESPACE_ENTER(SFX)

#include SFX_SETTINGS_DEF

#if (USE_FXAA == 1 || USE_FXAA_ANTIALIASING == 1)
//TODO make a luma pass

float3 FXAA(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = FxaaPixelShader(texcoord, RFX_backbufferColor, RFX_PixelSize, float4(0.0f, 0.0f, 0.0f, 0.0f), fxaa_Subpix, fxaa_EdgeThreshold, fxaa_EdgeThresholdMin).rgb;

#if (SFX_PIGGY == 1)
	#undef SFX_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color;
}

//TODO make a luma pass
technique FXAA_Tech <bool enabled = RFX_Start_Enabled; int toggle = FXAA_ToggleKey; >
{
	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader  = FXAA;
	}
}

#include "ReShade\SweetFX\PiggyCount.h"
#endif

#include SFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()