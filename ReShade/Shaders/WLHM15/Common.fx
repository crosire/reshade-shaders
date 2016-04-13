#ifndef INCLUDE_GUARD_WLHM15_COMMON
#define INCLUDE_GUARD_WLHM15_COMMON
#if (USE_FXGB || USE_YATC || USE_Posterization)
#if (FXGBRenderFormat == 1)
	#define FXGBRenderFORM RGBA8
#elif (FXGBRenderFormat == 2)
	#define FXGBRenderFORM RGBA16F
#else
	#define FXGBRenderFORM RGBA32F
#endif

///////////////////////////////////////////////////////////////
static const float3 lumaCoeff = float3(0.2126f,0.7152f,0.0722f);
#define ScreenSize 	float4(BUFFER_WIDTH, BUFFER_RCP_WIDTH, float(BUFFER_WIDTH) / float(BUFFER_HEIGHT), float(BUFFER_HEIGHT) / float(BUFFER_WIDTH)) //x=Width, y=1/Width, z=ScreenScaleY, w=1/ScreenScaleY

namespace Wlhm15
{
	//////////////////////////////////////////////////////
	texture2D texWLHM { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	texture2D texHDRA { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
	texture2D texHDRB { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
	texture2D texBloomA { Width = BUFFER_WIDTH/FXGBDownsampling; Height = BUFFER_HEIGHT/FXGBDownsampling; Format = FXGBRenderFORM; };
	texture2D texBloomB { Width = BUFFER_WIDTH/FXGBDownsampling; Height = BUFFER_HEIGHT/FXGBDownsampling; Format = FXGBRenderFORM; };
	texture2D texDirt < string source = "ReShade/Shaders/Wlhm15/Textures/dirtylens.png"; > {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	///////////////////////////////////////////////////////
	sampler2D samplerWLHMOri { Texture = texWLHM; };
	sampler2D samplerWLHM
	{
		Texture = texWLHM;
		AddressU = BORDER;
		AddressV = BORDER;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		SRGBTexture = TRUE;
	};

	sampler samplerHDRA
	{
		Texture = texHDRA;
		AddressU = BORDER;
		AddressV = BORDER;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
	};

	sampler samplerHDRB
	{
		Texture = texHDRB;
		AddressU = BORDER;
		AddressV = BORDER;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
	};

	sampler samplerBloomA { Texture = texBloomA; };
	sampler samplerBloomB { Texture = texBloomB; };
	sampler samplerDirt { Texture = texDirt; };
	///////////////////////////////////////////////////////////////////
	
	float4 PS_WInitialization(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return tex2D(ReShade::BackBuffer, texcoord);
	}
	///////////////////////////////////////////////////////////////////
	
	//This is my weirdo way to keeping out texture initialization conflict on each effect.
	//I moved the initialization in here, so the effects can recognize the texture without conflict each other..
	float4 PS_Initialization(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return float4(tex2D(samplerWLHM, texcoord.xy).xyz, 1.0);
	}
	///////////////////////////////////////////////////////////////////
	technique WLHM15CommonTech < bool enabled = RESHADE_START_ENABLED;  int toggle = RESHADE_TOGGLE_KEY; >
	{
		pass WLHMInitialization
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_WInitialization;
			RenderTarget = texWLHM;
		}
		
		pass Initialization
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_Initialization;
			RenderTarget0 = texHDRA;
		}

		pass InitializationWithoutFXGB
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_Initialization;
			RenderTarget0 = texHDRB;
		}
	
	}
}
#endif
#endif
