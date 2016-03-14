#ifndef INCLUDE_GUARD_OTIS_COMMON
#define INCLUDE_GUARD_OTIS_COMMON

// Stuff all/most of Otis shared shaders need

#if( HDR_MODE == 0)
 #define Otis_RENDERMODE RGBA8
#elif( HDR_MODE == 1)
 #define Otis_RENDERMODE RGBA16F
#else
 #define Otis_RENDERMODE RGBA32F
#endif

namespace Otis
{

// textures
texture   Otis_FragmentBuffer1 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; MipLevels = 8; Format = Otis_RENDERMODE;};	
texture   Otis_FragmentBuffer2 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; MipLevels = 8; Format = Otis_RENDERMODE;};	

// samplers
sampler2D Otis_SamplerFragmentBuffer2
{
	Texture = Otis_FragmentBuffer2;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

sampler2D Otis_SamplerFragmentBuffer1
{
	Texture = Otis_FragmentBuffer1;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

// general pixel shaders
void PS_Otis_Init(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 colFragment : SV_Target0) 
{
	colFragment = tex2D(ReShade::BackBuffer, texcoord.xy);
}

float4 PS_Otis_Overlay(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(Otis_SamplerFragmentBuffer2, texcoord.xy);
}

// init technique to read the back buffer into the two fragment buffers. Disabled for now as they're not used
/*
technique Otis_Init_Tech  < enabled = false; >
{
	pass Init_Otis_FragmentBuffer2
	{
		VertexShader = ReShade::VS_PostProcess;			
		PixelShader = PS_Otis_Init;
		RenderTarget = Otis_FragmentBuffer2;
	}
	pass Init_Otis_FragmentBuffer1
	{
		VertexShader = ReShade::VS_PostProcess;			
		PixelShader = PS_Otis_Init;
		RenderTarget = Otis_FragmentBuffer1;
	}
}
*/

}

#endif
