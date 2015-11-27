NAMESPACE_ENTER(OFX)
#include OFX_SETTINGS_DEF

#if USE_EMPHASIZE
///////////////////////////////////////////////////////////////////
// This effect works like a simple DoF for desaturating what otherwise would have been blurred.
//
// It works by determining whether a pixel is outside the emphasize zone using the depth buffer
// if so, the pixel is desaturated and blended with the color specified in the cfg file. 
///////////////////////////////////////////////////////////////////
float CalculateDepthDiffCoC(float2 texcoord : TEXCOORD)
{
	const float scenedepth = tex2D(RFX_depthTexColor, texcoord).r;
	const float scenefocus =  EMZ_ManualFocusDepth;
	const float desaturateFullRange = EMZ_FocusRangeDepth+EMZ_FocusEdgeDepth;
	const float depthdiff = abs(scenedepth-scenefocus);
	return saturate((depthdiff > desaturateFullRange) ? 1.0 : smoothstep(scenefocus, scenefocus+desaturateFullRange, scenefocus + depthdiff));
}

void PS_OFX_EMZ_Desaturate(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	const float depthDiffCoC = CalculateDepthDiffCoC(texcoord.xy);	
	const float4 colFragment = tex2D(RFX_backbufferColor, texcoord);
	const float greyscaleAverage = (colFragment.x + colFragment.y + colFragment.z) / 3.0;
	float4 desColor = float4(greyscaleAverage, greyscaleAverage, greyscaleAverage, depthDiffCoC);
	desColor = lerp(desColor, float4(EMZ_BlendColor, depthDiffCoC), EMZ_BlendFactor);
	outFragment = lerp(colFragment, desColor, saturate(depthDiffCoC * EMZ_EffectFactor));
}

technique OFX_EMZ_Tech <bool enabled = false; int toggle = EMZ_ToggleKey; >
{
	pass OFX_EMZ_Desaturate
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_EMZ_Desaturate;
	}
}
#endif

#include OFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()