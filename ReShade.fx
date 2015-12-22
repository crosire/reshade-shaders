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

namespace ReShade
{
	// Global Variables
	uniform float Timer < source = "timer"; >;
	uniform float FrameTime < source = "frametime"; >;

	// Global Textures and Samplers
	texture BackBufferTex : COLOR;
	texture DepthBufferTex : DEPTH;

#if RFX_InitialStorage
	texture OriginalColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
#else
	texture OriginalColorTex : COLOR;
#endif
	texture LinearizedDepthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; };

	sampler BackBuffer { Texture = BackBufferTex; };
	sampler OriginalColor { Texture = OriginalColorTex; };
	sampler OriginalDepth { Texture = DepthBufferTex; };
	sampler LinearizedDepth { Texture = LinearizedDepthTex; };

#if RFX_PseudoDepth
	texture DepthMaskTex < source = "ReShade/Ganossa/Textures/dMask.png"; > { Width = 1024; Height = 1024; MipLevels = 1; Format = RGBA8; };
	sampler DepthMask { Texture = DepthMaskTex; };
#endif

	// Full-screen triangle vertex shader
	void VS_PostProcess(in uint id : SV_VertexID, out float4 pos : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		pos = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	// Color and depth buffer copy and linearization shaders
#if RFX_InitialStorage || RFX_ShowToggleMessage
	float4 PS_StoreColor(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return tex2D(BackBuffer, texcoord);
	}
#endif
#if RFX_DepthBufferCalc
	float  PS_StoreDepth(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
	{
#if RFX_PseudoDepth
		float depth = tex2D(DepthMask, texcoord).x;
#else
		float depth = tex2D(OriginalDepth, texcoord).x;

		// Linearize depth	
	#if RFX_LogDepth 
		depth = saturate(1.0f - depth);
		depth = (exp(pow(depth, 150 * pow(depth, 55) + 32.75f / pow(depth, 5) - 1850f * (pow((1 - depth), 2)))) - 1) / (exp(depth) - 1); // Made by Ganossa ;-)
	#else
		depth = 1.f/(1000.f-999.f*depth);
	#endif
#endif
#if RFX_NegativeDepth
		return 1.0 - depth;
#else
		return depth;
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
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = ReShade::PS_StoreColor;
		RenderTarget = ReShade::OriginalColorTex;
	}
#endif
#if RFX_DepthBufferCalc
	pass StoreDepth
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = ReShade::PS_StoreDepth;
		RenderTarget = ReShade::LinearizedDepthTex;
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
technique Framework < enabled = RFX_Start_Enabled; toggle = RFX_ToggleKey; >
{
	pass 
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = ReShade::PS_StoreColor;
	}
}
#endif
