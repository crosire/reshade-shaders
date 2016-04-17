///////////////////////////////////////////////////////////////////
// Simple depth-based fog powered with bloom to fake light diffusion.
// The bloom is borrowed from SweetFX's bloom by CeeJay.
///////////////////////////////////////////////////////////////////

#include EFFECT_CONFIG(Otis)
#include "Common.fx"

#if USE_ADAPTIVEFOG

#pragma message "Adaptive Fog by Otis, with bloom code from CeeJay.\n"

namespace Otis
{

uniform bool Otis_MouseToggleKeyDown < source = "key"; keycode = MOL_ToggleKey; toggle = true; >;

// Two small 1x1 textures to preserve a value across frames. We need 2 as each target is cleared before it's bound so 
// we have to copy from 1 to 2 and then either read from 2 into 1 or read the new value.
texture Otis_FogColorFromMouseTarget1 { Width=1; Height=1; Format= Otis_RENDERMODE;};
sampler2D Otis_FogColorFromMouseSampler1 { Texture = Otis_FogColorFromMouseTarget1;};
texture Otis_FogColorFromMouseTarget2 { Width=1; Height=1; Format= Otis_RENDERMODE;};
sampler2D Otis_FogColorFromMouseSampler2 { Texture = Otis_FogColorFromMouseTarget2;};

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
	depth = (depth * (1.0+AFG_FogStart)) - AFG_FogStart;
	float4 bloomedFragment = tex2D(Otis_BloomSampler, texcoord);
	float4 colorFragment = tex2D(ReShade::BackBuffer, texcoord);
	float4 fogColor = float4(AFG_Color, 1.0);
#if AFG_MouseDrivenFogColorSelect
	fogColor = tex2D(Otis_FogColorFromMouseSampler1, float2(0,0));  //tex2Dfetch(Otis_FogColorFromMouseSampler, int2(0, 0)); // 
#endif
	float fogFactor = clamp(depth * AFG_FogCurve, 0.0, AFG_MaxFogFactor); 
	float4 bloomedBlendedWithFogFragment = lerp(bloomedFragment, fogColor, fogFactor);
	fragment = lerp(colorFragment, bloomedBlendedWithFogFragment, fogFactor);
}


void PS_Otis_AFG_CopyFogColorFrom1To2(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	fragment = tex2D(Otis_FogColorFromMouseSampler1, texcoord);
}


void PS_Otis_AFG_PerformGetFogColorFromFrameBuffer(float4 vpos: SV_Position, float2 texcoord: TEXCOORD, out float4 fragment: SV_Target0)
{
	fragment = Otis_MouseToggleKeyDown 
				? tex2D(ReShade::BackBuffer, ReShade::MouseCoords * ReShade::PixelSize)	 // read new value 
				: tex2D(Otis_FogColorFromMouseSampler2, float2(0,0)); // preserve old value 
}


technique Otis_AFG_Tech <bool enabled = false; int toggle = AFG_ToggleKey; >
{
	pass Otis_AFG_PassCopyOldFogValueFrom1To2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Otis_AFG_CopyFogColorFrom1To2;
		RenderTarget = Otis_FogColorFromMouseTarget2;
	}

	pass Otis_AFG_PassFogColorFromMouse
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Otis_AFG_PerformGetFogColorFromFrameBuffer;
		RenderTarget = Otis_FogColorFromMouseTarget1;
	}
	
	pass Otis_AFG_PassBloom0
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
