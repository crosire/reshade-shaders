/**
 *                    ____      ____  _               _
 *                   |  _ \ ___/ ___|| |__   __ _  __| | ___
 *                   | |_) / _ \___ \| '_ \ / _` |/ _` |/ _ \
 *                   |  _ '  __/___) | | | | (_| | (_| |  __/
 *                   |_| \_\___|____/|_| |_|\__,_|\__,_|\___|
 *
 * =============================================================================
 *                           ReShade Framework Globals
 * =============================================================================
 */

// Global Settings
#include "ReShade\Common\KeyCodes.h"
#include "ReShade\Common.cfg"

#if RFX_Screenshot_Format != 2
	#pragma reshade screenshot_format bmp
#else
	#pragma reshade screenshot_format png
#endif

#if RFX_ShowFPS == 1
	#pragma reshade showfps
#endif
#if RFX_ShowClock == 1
	#pragma reshade showclock
#endif
#if RFX_ShowStatistics == 1
	#pragma reshade showstatistics
#endif

#if RFX_ShowToggleMessage == 1
	#pragma reshade showtogglemessage
#endif

#define RFX_PixelSize float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define RFX_ScreenSize float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define RFX_ScreenSizeFull float4(BUFFER_WIDTH, BUFFER_RCP_WIDTH, float(BUFFER_WIDTH) / float(BUFFER_HEIGHT), float(BUFFER_HEIGHT) / float(BUFFER_WIDTH))

namespace RFX
{
	// Global Variables
	uniform float Timer < source = "timer"; >;
	uniform float FrameTime < source = "frametime"; >;
	uniform float TechniqueTimeLeft < source = "timeleft"; >;

	// Global Textures and Samplers
	texture depthBufferTex : DEPTH;
	texture depthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; };

	texture backbufferTex : COLOR;

#if RFX_InitialStorage
	texture originalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
#else
	texture originalTex : COLOR;
#endif

	sampler depthColor { Texture = depthBufferTex; };
	sampler depthTexColor { Texture = depthTex; };

	sampler backbufferColor { Texture = backbufferTex; };
	sampler originalColor { Texture = originalTex; };

#if RFX_PseudoDepth
	texture dMaskTex < source = "ReShade/Ganossa/Textures/dMask.png"; > { Width = 1024; Height = 1024; MipLevels = 1; Format = RGBA8; };
	sampler dMaskColor { Texture = dMaskTex; };
#endif

	// Full-screen triangle vertex shader
	void VS_PostProcess(in uint id : SV_VertexID, out float4 pos : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		pos = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

#if RFX_InitialStorage
	float4 PS_StoreColor(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return tex2D(backbufferColor, texcoord);
	}
#endif
#if RFX_DepthBufferCalc
	float  PS_StoreDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
	{
#if RFX_PseudoDepth
	#if RFX_NegativeDepth
		return 1.0 - tex2D(dMaskColor, texcoord).x;
	#else
		return tex2D(dMaskColor, texcoord).x;
	#endif
#else
		float depth = tex2D(depthColor, texcoord).x;

		// Linearize depth	
	#if RFX_LogDepth 
		depth = saturate(1.0f - depth);
		depth = (exp(pow(depth, 150 * pow(depth, 55) + 32.75f / pow(depth, 5) - 1850f * (pow((1 - depth), 2)))) - 1) / (exp(depth) - 1); // Made by LuciferHawk ;-)
	#else
		depth = 1.f/(1000.f-999.f*depth);
	#endif

	#if RFX_NegativeDepth
		return 1.0 - depth;
	#else
		return depth;
	#endif
#endif
	}
#endif
}

#if RFX_InitialStorage || RFX_DepthBufferCalc
technique Setup_Tech < enabled = true; >
{
#if RFX_InitialStorage
	pass StoreColor
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = RFX::PS_StoreColor;
		RenderTarget = RFX::originalTex;
	}
#endif
#if RFX_DepthBufferCalc
	pass StoreDepth
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = RFX::PS_StoreDepth;
		RenderTarget = RFX::depthTex;
	}
#endif
}
#endif

/**
 * =============================================================================
 *                                    Effects
 * =============================================================================
 */

#define STR(name) #name
#define EFFECT(l,n) STR(ReShade/l/##n.fx)

#include "ReShade\Pipeline.cfg"

/**
 * =============================================================================
 *                                 Toggle Message
 * =============================================================================
 */

#if RFX_ShowToggleMessage
float4 PS_ToggleMessage(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
	return tex2D(RFX::backbufferColor, texcoord);
}

technique Framework < enabled = RFX_Start_Enabled; toggle = RFX_ToggleKey; >
{
	pass 
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = PS_ToggleMessage;
	}
}
#endif
