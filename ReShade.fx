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

// Global Variables
#define RFX_PixelSize float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define RFX_ScreenSize float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define RFX_ScreenSizeFull float4(BUFFER_WIDTH, BUFFER_RCP_WIDTH, float(BUFFER_WIDTH) / float(BUFFER_HEIGHT), float(BUFFER_HEIGHT) / float(BUFFER_WIDTH))

uniform float RFX_Timer < string source = "timer"; >;
uniform float RFX_FrameTime < source = "frametime"; >;
uniform float RFX_TechniqueTimeLeft < string source = "timeleft"; >;

// Global Textures and Samplers
texture RFX_depthBufferTex : DEPTH;
texture RFX_depthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; };

texture RFX_backbufferTex : COLOR;

#if RFX_InitialStorage
	texture RFX_originalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
#else
	texture RFX_originalTex : COLOR;
#endif

sampler RFX_depthColor { Texture = RFX_depthBufferTex; };
sampler RFX_depthTexColor { Texture = RFX_depthTex; };

sampler RFX_backbufferColor { Texture = RFX_backbufferTex; };
sampler RFX_originalColor { Texture = RFX_originalTex; };

#if RFX_PseudoDepth
texture RFX_dMaskTex < source = "ReShade/BasicFX/Textures/dMask.png"; > { Width = 1024; Height = 1024; MipLevels = 1; Format = RGBA8; };
sampler RFX_dMaskColor { Texture = RFX_dMaskTex; };
#endif

// Fullscreen Triangle Vertex Shader
void RFX_VS_PostProcess(in uint id : SV_VertexID, out float4 pos : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	pos = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

#if RFX_InitialStorage
float4 RFX_PS_StoreColor(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(RFX_backbufferColor, texcoord);
}
#endif
#if RFX_DepthBufferCalc
float  RFX_PS_StoreDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
#if RFX_PseudoDepth
#if RFX_NegativeDepth
	return 1.0 - tex2D(RFX_dMaskColor, texcoord).x;
#else
	return tex2D(RFX_dMaskColor, texcoord).x;
#endif
#endif

#if RFX_NegativeDepth
	float depth = 1.0 - tex2D(RFX_depthColor, texcoord).x;
#else
	float depth = tex2D(RFX_depthColor, texcoord).x;
#endif

	// Linearize depth	
#if RFX_LogDepth 
	depth = saturate(1.0f - depth);
	depth = (exp(pow(depth, 150 * pow(depth, 55) + 32.75f / pow(depth, 5) - 1850f * (pow((1 - depth), 2)))) - 1) / (exp(depth) - 1); // Made by LuciferHawk ;-)
	return depth;;
#else
	depth = 1.f/(1000.f-999.f*depth);
	return depth;
#endif
}
#endif

#if RFX_InitialStorage || RFX_DepthBufferCalc
technique RFX_Setup_Tech < enabled = true; >
{
	#if RFX_InitialStorage
	pass StoreColor
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = RFX_PS_StoreColor;
		RenderTarget = RFX_originalTex;	
	}
	#endif
	#if RFX_DepthBufferCalc
	pass StoreDepth
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = RFX_PS_StoreDepth;
		RenderTarget = RFX_depthTex;
	}
	#endif
}
#endif

// Global Defines
#if defined(__RESHADE__) && __RESHADE__ >= 1700
	#define NAMESPACE_ENTER(name) namespace name {
	#define NAMESPACE_LEAVE() }
#else
	#define NAMESPACE_ENTER(name)
	#define NAMESPACE_LEAVE()
#endif

#define STR(name) #name
#define EFFECT(l,n) STR(ReShade/l/##n.fx)

/**
 * =============================================================================
 *                                    Effects
 * =============================================================================
 */

#include "ReShade\Pipeline.cfg"

/**
 * =============================================================================
 *                                 Toggle Message
 * =============================================================================
 */

#if RFX_ShowToggleMessage
float4 RFX_PS_ToggleMessage(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
	return tex2D(RFX_backbufferColor, texcoord);
}

technique Framework < enabled = RFX_Start_Enabled; toggle = RFX_ToggleKey; >
{
	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = RFX_PS_ToggleMessage;
	}
}
#endif
