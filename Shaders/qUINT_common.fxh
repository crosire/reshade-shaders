


/*
	changelog:

	2.0.0:	added frame count parameter
			added versioning system
			removed common textures - should only be declared if needed
			flipped reversed depth buffer switch by default as most games use this format

*/

/*=============================================================================
	Version checks
=============================================================================*/

#ifndef RESHADE_QUINT_COMMON_VERSION
 #define RESHADE_QUINT_COMMON_VERSION 200
#endif

#if RESHADE_QUINT_COMMON_VERSION_REQUIRE > RESHADE_QUINT_COMMON_VERSION
 #error "qUINT_common.fxh outdated."
 #error "Please download update from github.com/martymcmodding/qUINT"
#endif

#if !defined(RESHADE_QUINT_COMMON_VERSION_REQUIRE)
 #error "Incompatible qUINT_common.fxh and shaders."
 #error "Do not mix different file versions."
#endif

#if !defined(__RESHADE__) || __RESHADE__ < 40000
	#error "ReShade 4.4+ is required to use this header file"
#endif

/*=============================================================================
	Define defaults
=============================================================================*/

//depth buffer
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

/*=============================================================================
	Uniforms
=============================================================================*/

namespace qUINT
{
    uniform float FRAME_TIME < source = "frametime"; >;
	uniform int FRAME_COUNT < source = "framecount"; >;

    static const float2 ASPECT_RATIO 	= float2(1.0, BUFFER_WIDTH * BUFFER_RCP_HEIGHT);
	static const float2 PIXEL_SIZE 		= float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	static const float2 SCREEN_SIZE 	= float2(BUFFER_WIDTH, BUFFER_HEIGHT);

	// Global textures and samplers
	texture BackBufferTex : COLOR;
	texture DepthBufferTex : DEPTH;

	sampler sBackBufferTex 	{ Texture = BackBufferTex; 	};
	sampler sDepthBufferTex { Texture = DepthBufferTex; };

    // Helper functions
	float linear_depth(float2 uv)
	{
#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		uv.y = 1.0 - uv.y;
#endif
		float depth = tex2Dlod(sDepthBufferTex, float4(uv, 0, 0)).x;

#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
#endif
#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
#endif
		const float N = 1.0;
		depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);

		return saturate(depth);
	}
}

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 vpos : SV_Position, out float2 uv : TEXCOORD)
{
	uv.x = (id == 2) ? 2.0 : 0.0;
	uv.y = (id == 1) ? 2.0 : 0.0;
	vpos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}