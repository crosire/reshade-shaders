///////////////////////////////////////////////////////////////////
// Simple depth-based AFG
///////////////////////////////////////////////////////////////////

#include EFFECT_CONFIG(Otis)
#include "Common.fx"

#if USE_ADAPTIVEFOG

#pragma message "Adaptive Fog by Otis, with bloom code from CeeJay.\n"

namespace Otis
{

texture   Otis_BloomTarget 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = Otis_RENDERMODE;};	
sampler2D Otis_BloomSampler { Texture = Otis_BloomTarget; };

// pixel shader which performs bloom, by CeeJay. 
void PS_Otis_AFG_PerformBloom(float4 position : SV_Position, float2 texcoord : TEXCOORD0, out float4 fragment: SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord);
	float3 BlurColor2 = 0;
	float3 Blurtemp = 0;
	float MaxDistance = 8*AFG_BloomWidth;
	float CurDistance = 0;
	float Samplecount = 25.0;
	float2 blurtempvalue = texcoord * ReShade::PixelSize * AFG_BloomWidth;
	float2 BloomSample = float2(2.5,-2.5);
	float2 BloomSampleValue;
	
	for(BloomSample.x = (2.5); BloomSample.x > -2.0; BloomSample.x = BloomSample.x - 1.0)
	{
		BloomSampleValue.x = BloomSample.x * blurtempvalue.x;
		float2 distancetemp = BloomSample.x * BloomSample.x * AFG_BloomWidth;
		
		for(BloomSample.y = (- 2.5); BloomSample.y < 2.0; BloomSample.y = BloomSample.y + 1.0)
		{
			distancetemp.y = BloomSample.y * BloomSample.y;
			CurDistance = (distancetemp.y * AFG_BloomWidth) + distancetemp.x;
			BloomSampleValue.y = BloomSample.y * blurtempvalue.y;
			Blurtemp.rgb = tex2D(ReShade::BackBuffer, float2(texcoord + BloomSampleValue)).rgb;
			BlurColor2.rgb += lerp(Blurtemp.rgb,color.rgb, sqrt(CurDistance / MaxDistance));
		}
	}
	BlurColor2.rgb = (BlurColor2.rgb / (Samplecount - (AFG_BloomPower - AFG_BloomThreshold*5)));
	float Bloomamount = (dot(color.rgb,float3(0.299f, 0.587f, 0.114f)));
	float3 BlurColor = BlurColor2.rgb * (AFG_BloomPower + 4.0);
	color.rgb = lerp(color.rgb,BlurColor.rgb, Bloomamount);	
	fragment = saturate(color);
}


void PS_Otis_AFG_BlendFogWithNormalBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	float depth = tex2D(ReShade::LinearizedDepth, texcoord).r;
	float4 bloomedFragment = tex2D(Otis_BloomSampler, texcoord);
	float4 colorFragment = tex2D(ReShade::BackBuffer, texcoord);
	float4 fogColor = float4(AFG_Color, 1.0);
#if AFG_MouseDrivenFogColorSelect
	fogColor = tex2D(ReShade::BackBuffer, ReShade::MouseCoords * ReShade::PixelSize);
#endif
	float fogFactor = clamp(depth * AFG_FogCurve, 0.0, AFG_MaxFogFactor); 
	float4 bloomedBlendedWithFogFragment = lerp(bloomedFragment, fogColor, fogFactor);
	fragment = lerp(colorFragment, bloomedBlendedWithFogFragment, fogFactor);
}

technique Otis_AFG_Tech <bool enabled = false; int toggle = AFG_ToggleKey; >
{
	pass Otis_AFG_PassAverage0
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Otis_AFG_PerformBloom;
		RenderTarget = Otis_BloomTarget;
	}
	
	pass Otis_AFG_PassBlend
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Otis_AFG_BlendFogWithNormalBuffer;
	}
}

}

#endif

#include EFFECT_CONFIG_UNDEF(Otis)
