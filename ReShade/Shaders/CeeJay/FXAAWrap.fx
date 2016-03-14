#include EFFECT_CONFIG(CeeJay)
#include "Common.fx"

#if (USE_FXAA || USE_FXAA_ANTIALIASING)

#pragma message "FXAA by Timothy Lottes (ported by CeeJay)\n"

//TODO make a luma pass

namespace CeeJay
{

float3 FXAA(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = FxaaPixelShader(texcoord, ReShade::BackBuffer, ReShade::PixelSize, float4(0.0f, 0.0f, 0.0f, 0.0f), fxaa_Subpix, fxaa_EdgeThreshold, fxaa_EdgeThresholdMin).rgb;

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color;
}

//TODO make a luma pass
technique FXAA_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = FXAA_ToggleKey; >
{
	pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader  = FXAA;
	}
}

}

#include "PiggyCount.h"
#endif

#include EFFECT_CONFIG_UNDEF(CeeJay)
