NAMESPACE_ENTER(OFX)

#include OFX_SETTINGS_DEF

#if USE_DEPTHHAZE
///////////////////////////////////////////////////////////////////
// This effect works like a one-side DoF for distance haze, which slightly
// blurs far away elements. A normal DoF has a focus point and blurs using
// two planes. 
//
// It works by first blurring the screen buffer using 2-pass block blur and
// then blending the blurred result into the screen buffer based on depth
// it uses depth-difference for extra weight in the blur method so edges
// of high-contrasting lines with high depth diffence don't bleed.
///////////////////////////////////////////////////////////////////

float CalculateWeight(float distanceFromSource, float sourceDepth, float neighborDepth)
{
	return (1.0 - abs(sourceDepth - neighborDepth)) * (1/distanceFromSource) * neighborDepth;
}

void PS_OFX_DEH_BlockBlurHorizontal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(RFX_backbufferColor, texcoord);
	float colorDepth = tex2D(RFX_depthTexColor,texcoord).r;
	float n = 1.0f;

	[loop]
	for(float i = 1; i < 5; ++i) 
	{
		float2 sourceCoords = texcoord + float2(i * RFX_PixelSize.x, 0.0);
		float weight = CalculateWeight(i, colorDepth, tex2D(RFX_depthTexColor, sourceCoords).r);
		color += (tex2D(RFX_backbufferColor, sourceCoords) * weight);
		n+=weight;
		
		sourceCoords = texcoord - float2(i * RFX_PixelSize.x, 0.0);
		weight = CalculateWeight(i, colorDepth, tex2D(RFX_depthTexColor,sourceCoords).r);
		color += (tex2D(RFX_backbufferColor, sourceCoords) * weight);
		n+=weight;
	}
	outFragment = color/n;
}

void PS_OFX_DEH_BlockBlurVertical(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 color = tex2D(OFX_SamplerFragmentBuffer1, texcoord);
	float colorDepth = tex2D(RFX_depthTexColor,texcoord).r;
	float n=1.0f;
	
	[loop]
	for(float j = 1; j < 5; ++j) 
	{
		float2 sourceCoords = texcoord + float2(0.0, j * RFX_PixelSize.y);
		float weight = CalculateWeight(j, colorDepth, tex2D(RFX_depthTexColor,sourceCoords).r);
		color += (tex2D(OFX_SamplerFragmentBuffer1, sourceCoords) * weight);
		n+=weight;

		sourceCoords = texcoord - float2(0.0, j * RFX_PixelSize.y);
		weight = CalculateWeight(j, colorDepth, tex2D(RFX_depthTexColor,sourceCoords).r);
		color += (tex2D(OFX_SamplerFragmentBuffer1, sourceCoords) * weight);
		n+=weight;
	}
	outFragment = color/n;
}

void PS_OFX_DEH_BlendBlurWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	fragment = lerp(tex2D(RFX_backbufferColor, texcoord), tex2D(OFX_SamplerFragmentBuffer2, texcoord), 
					clamp( tex2D(RFX_depthTexColor,texcoord).r * DEH_EffectStrength, 0, 1)); 
}

technique OFX_DEH_Tech <bool enabled = false; int toggle = DEH_ToggleKey; >
{
	// 3 passes. First 2 passes blur screenbuffer into OFX_FragmentBuffer2 using 2 pass block blur with 10 samples each (so 2 passes needed)
	// 3rd pass blends blurred fragments based on depth with screenbuffer.
	pass OFX_DEH_Pass0
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_DEH_BlockBlurHorizontal;
		RenderTarget = OFX_FragmentBuffer1;
	}

	pass OFX_DEH_Pass1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_DEH_BlockBlurVertical;
		RenderTarget = OFX_FragmentBuffer2;
	}
	
	pass OFX_DEH_Pass2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_OFX_DEH_BlendBlurWithNormalBuffer;
	}
}
#endif

#include OFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()