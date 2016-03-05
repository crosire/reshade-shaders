#include EFFECT_CONFIG(CeeJay)
#include "Common.fx"

#if USE_SMAA

#pragma message "SMAA by Jorge Jimenez, Jose I. Echevarria, Belen Masia, Fernando Navarro, Diego Gutierrez and CeeJay\n"

namespace CeeJay
{

////////////////////////////
// Vertex shader wrappers //
////////////////////////////

void SMAAEdgeDetectionVSWrap(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	ReShade::VS_PostProcess(id, position, texcoord);
	SMAAEdgeDetectionVS(texcoord, offset);
}

void SMAABlendingWeightCalculationVSWrap(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	ReShade::VS_PostProcess(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}

void SMAANeighborhoodBlendingVSWrap(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	ReShade::VS_PostProcess(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}

///////////////////////////
// Pixel shader wrappers //
///////////////////////////

#ifndef __RESHADE__//GPU_SHADERANALYZER //GPU Shaderanalyzer requires that DX9-style pixel shaders output a float4
	#define OUTPUT_FLOAT float4
	#define OUTPUT_COMPONENT rrrr
	#define OUTPUT_FLOAT2 float4
	#define OUTPUT_COMPONENT2 rgrg
	#define OUTPUT_FLOAT3 float4
	#define OUTPUT_COMPONENT3 rgbr
#else
	#define OUTPUT_FLOAT float
	#define OUTPUT_COMPONENT r
	#define OUTPUT_FLOAT2 float2
	#define OUTPUT_COMPONENT2 rg
	#define OUTPUT_FLOAT3 float3
	#define OUTPUT_COMPONENT3 rgb
#endif

#if SMAA_EDGE_DETECTION == 1
	OUTPUT_FLOAT2 SMAALumaEdgeDetectionPSWrap(
		float4 position : SV_Position,
		float2 texcoord : TEXCOORD0,
		float4 offset[3] : TEXCOORD1) : SV_Target
	{
		return SMAALumaEdgeDetectionPS(texcoord, offset, ReShade::BackBuffer
		#if SMAA_PREDICATION == 1
		, predicationSampler
		#endif
		).OUTPUT_COMPONENT2;
	}
#elif SMAA_EDGE_DETECTION == 3
	OUTPUT_FLOAT2 SMAADepthEdgeDetectionPSWrap(
		float4 position : SV_Position,
		float2 texcoord : TEXCOORD0,
		float4 offset[3] : TEXCOORD1) : SV_Target
	{
		return SMAADepthEdgeDetectionPS(texcoord, offset, ReShade::OriginalDepth).OUTPUT_COMPONENT2;
	}
#else //SMAA_EDGE_DETECTION == 2	
	OUTPUT_FLOAT2 SMAAColorEdgeDetectionPSWrap(
		float4 position : SV_Position,
		float2 texcoord : TEXCOORD0,
		float4 offset[3] : TEXCOORD1) : SV_Target
	{
		return SMAAColorEdgeDetectionPS(texcoord, offset, ReShade::BackBuffer
		#if SMAA_PREDICATION == 1
		, predicationSampler
		#endif
		).OUTPUT_COMPONENT2;
	}
#endif

float4 SMAABlendingWeightCalculationPSWrap(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesSampler, areaSampler, searchSampler, 0.0);
}

OUTPUT_FLOAT3 SMAANeighborhoodBlendingPSWrap(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_Target
{
#if SMAA_DEBUG_OUTPUT == 1
	return tex2D(edgesSampler, texcoord); // Show edgesTex
#elif SMAA_DEBUG_OUTPUT == 2
	return tex2D(blendSampler, texcoord); // Show blendTex
#elif SMAA_DEBUG_OUTPUT == 3
	return tex2D(areaSampler, texcoord); // Show areaTex
#elif SMAA_DEBUG_OUTPUT == 4
	return tex2D(searchSampler, texcoord); // Show searchTex
#elif SMAA_DEBUG_OUTPUT == 5
	return float3(1.0, 0.0, 0.0); // Show the stencil in red.
#else
	float3 color = SMAANeighborhoodBlendingPS(texcoord, offset, colorLinearSampler, blendSampler).rgb;

	#if (CeeJay_PIGGY == 1)
		color.rgb = (color.rgb <= 0.0031308) ? saturate(abs(color.rgb) * 12.92) : 1.055 * saturate(pow(abs(color.rgb), 1.0/2.4 )) - 0.055; // Linear to SRGB

		color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
	#endif

	return color.OUTPUT_COMPONENT3;
#endif
}

technique SMAA_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = SMAA_ToggleKey; >
{
	pass SMAA_EdgeDetection //First SMAA Pass
	{
		VertexShader = SMAAEdgeDetectionVSWrap;

	#if SMAA_EDGE_DETECTION == 1
		PixelShader = SMAALumaEdgeDetectionPSWrap;
	#elif SMAA_EDGE_DETECTION == 3
		PixelShader = SMAADepthEdgeDetectionPSWrap;
	#else
		PixelShader = SMAAColorEdgeDetectionPSWrap; //Probably the best in most cases so I default to this.
	#endif

		// We will be creating the stencil buffer for later usage.
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;

		RenderTarget = edgesTex;
	}

	pass SMAA_BlendWeightCalculation //Second SMAA Pass
	{
		VertexShader = SMAABlendingWeightCalculationVSWrap;
		PixelShader = SMAABlendingWeightCalculationPSWrap;

		// Here we want to process only marked pixels.
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;

		RenderTarget = blendTex;
	}

	pass SMAA_NeighborhoodBlending //Third SMAA Pass
	{
		VertexShader = SMAANeighborhoodBlendingVSWrap;
		PixelShader  = SMAANeighborhoodBlendingPSWrap;

	#if SMAA_DEBUG_OUTPUT == 5
		// Use the stencil so we can show it.
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	#else
		// Process all the pixels.
		StencilEnable = false;
	#endif

	#if (CeeJay_PIGGY == 1)
		#undef CeeJay_PIGGY
		SRGBWriteEnable = false;
	#else
		SRGBWriteEnable = true;
	#endif
	}
}

}

#include "PiggyCount.h"
#endif

#include EFFECT_CONFIG_UNDEF(CeeJay)
