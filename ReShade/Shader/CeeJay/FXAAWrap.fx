#include "Common.fx"
#include CeeJay_SETTINGS_DEF

#if (USE_FXAA == 1 || USE_FXAA_ANTIALIASING == 1)
//TODO make a luma pass

namespace CeeJay
{

float3 FXAA(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = FxaaPixelShader(texcoord, ReShade::BackBuffer, RFX_PixelSize, float4(0.0f, 0.0f, 0.0f, 0.0f), fxaa_Subpix, fxaa_EdgeThreshold, fxaa_EdgeThresholdMin).rgb;

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color;
}

//TODO make a luma pass
technique FXAA_Tech <bool enabled = RFX_Start_Enabled; int toggle = FXAA_ToggleKey; >
{
	pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader  = FXAA;
	}
}

}

#include "ReShade\Shader\CeeJay\PiggyCount.h"
#endif

#include CeeJay_SETTINGS_UNDEF
