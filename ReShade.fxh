// unclear if this is needed.
#include "KeyCodes.h"
// For now, till format for this include is finalized
#include "Global.cfg"

	// Global Variables
	static const float AspectRatio = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
	static const float2 PixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	static const float2 ScreenSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	uniform float Timer < source = "timer"; >;
	uniform float FrameTime < source = "frametime"; >;
	uniform float2 MouseCoords < source = "mousepoint"; >;

	// Global Textures and Samplers
	texture BackBufferTex : COLOR;
	texture DepthBufferTex : DEPTH;
	texture OriginalColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
#if RESHADE_DEPTH_LINEARIZATION
	texture LinearizedDepthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; };
#else
	texture LinearizedDepthTex : DEPTH;
#endif

	sampler BackBuffer { Texture = BackBufferTex; };
	sampler OriginalColor { Texture = OriginalColorTex; };
	sampler OriginalDepth { Texture = DepthBufferTex; };
	sampler LinearizedDepth { Texture = LinearizedDepthTex; };

	// Full-screen triangle vertex shader
	void VS_PostProcess(in uint id : SV_VertexID, out float4 pos : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		pos = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	// Color and depth buffer copy and linearization shaders
	float4 PS_CopyBackBuffer(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return tex2D(BackBuffer, texcoord);
	}
#if RESHADE_DEPTH_LINEARIZATION
	void PS_DepthLinearization(float4 vpos : SV_Position, float2 texcoord : TEXCOORD0, out float depth : SV_Target)
	{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		texcoord.y = 1.0 - texcoord.y;
#endif
		depth = tex2D(OriginalDepth, texcoord).x;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);
	}
#endif

/*
//
// Unclear what to do with this. 
//
technique Setup < enabled = true; >
{
	pass ColorBackup
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_CopyBackBuffer;
		RenderTarget = OriginalColorTex;
	}
#if RESHADE_DEPTH_LINEARIZATION
	pass DepthLinearization
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_DepthLinearization;
		RenderTarget = LinearizedDepthTex;
	}
#endif
}
*/
