#pragma once

#if !defined(__RESHADE__) || __RESHADE__ < 30000
	#error "ReShade 3.0+ is required to use this header file"
#endif

#ifndef RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	#define RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN 0
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_REVERSED
	#define RESHADE_DEPTH_INPUT_IS_REVERSED 1
#endif
#ifndef RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
	#define RESHADE_DEPTH_INPUT_IS_LOGARITHMIC 0
#endif
#ifndef RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
	#define RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 1000.0
#endif
// Reserved for Emulators with Weak Depth Buffers
// Keep at 1 for Stock Behaviour
#ifndef RESHADE_DEPTH_MULTIPLIER
	#define RESHADE_DEPTH_MULTIPLIER 1
#endif
// Depth Scale Factors Per Axis.
//  Keep at 1 for Stock Behaviour.
// Below 1 Expands and Above 1 Contracts On Relevant Axis.
#ifndef RESHADE_DEPTH_INPUT_X_SCALE
	#define RESHADE_DEPTH_INPUT_X_SCALE 1
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_SCALE
	#define RESHADE_DEPTH_INPUT_Y_SCALE 1
#endif
// Depth Buffer Location Offset.
// Keep at 0 for Stock Behaviour.
// Recommended to adjust in increments/decrements of anything between 0.005 and 0.1.
#ifndef RESHADE_DEPTH_INPUT_X_OFFSET_SCALE
	#define RESHADE_DEPTH_INPUT_X_OFFSET_SCALE 0
#endif
#ifndef RESHADE_DEPTH_INPUT_Y_OFFSET_SCALE
	#define RESHADE_DEPTH_INPUT_Y_OFFSET_SCALE 0
#endif

namespace ReShade
{
	// Global variables
#if defined(__RESHADE_FXC__)
	float GetAspectRatio() { return BUFFER_WIDTH * BUFFER_RCP_HEIGHT; }
	float2 GetPixelSize() { return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT); }
	float2 GetScreenSize() { return float2(BUFFER_WIDTH, BUFFER_HEIGHT); }
	#define AspectRatio GetAspectRatio()
	#define PixelSize GetPixelSize()
	#define ScreenSize GetScreenSize()
#else
	static const float AspectRatio = BUFFER_WIDTH * BUFFER_RCP_HEIGHT;
	static const float2 PixelSize = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	static const float2 ScreenSize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
#endif
	
	// Global textures and samplers
	texture BackBufferTex : COLOR;
	texture DepthBufferTex : DEPTH;

	sampler BackBuffer { Texture = BackBufferTex; };
	sampler DepthBuffer { Texture = DepthBufferTex; };

	// Helper functions
	float GetLinearizedDepth(float2 texcoord)
	{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		texcoord.y = 1.0 - texcoord.y;
#endif
		// Apply the Depth Buffer Scale
    	texcoord.y *= RESHADE_DEPTH_INPUT_Y_SCALE;
		texcoord.x *= RESHADE_DEPTH_INPUT_X_SCALE;
		// Apply Depth Buffer Location Offset
    	texcoord.y -= RESHADE_DEPTH_INPUT_Y_OFFSET_SCALE;
		texcoord.x -= RESHADE_DEPTH_INPUT_X_OFFSET_SCALE;
		float depth = tex2Dlod(DepthBuffer, float4(texcoord, 0, 0)).x * RESHADE_DEPTH_MULTIPLIER;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return depth;
	}
}

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}
