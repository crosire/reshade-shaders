/**
 * Depth-buffer based cel shading for ENB by kingeric1992
 * http://enbseries.enbdev.com/forum/viewtopic.php?f=7&t=3244#p53168
 *
 * Modified and optimized for ReShade by JPulowski
 * http://reshade.me/forum/shader-presentation/261
 *
 * Do not distribute without giving credit to the original author(s).
 * 
 * 1.0  - Initial release/port
 * 1.1  - Replaced depth linearization algorithm with another one by crosire
 *        Added an option to tweak accuracy
 *        Modified the code to make it compatible with SweetFX 2.0 Preview 7 and new Operation Piggyback which should give some performance increase
 * 1.1a - Framework port
 * 1.2  - Changed the name to "Outline" since technically this is not Cel shading (See https://en.wikipedia.org/wiki/Cel_shading)
 *        Added custom outline and background color support
 *        Added a threshold and opacity modifier
 * 1.2a - Now uses the depth buffer linearized by ReShade therefore it should work with pseudo/logaritmic/negative/flipped depth
 *        It is now possible to use the color texture for edge detection
 *        Rewritten and simplified some parts of the code
 */

#include EFFECT_CONFIG(JPulowski)

#if USE_OUTLINE

#pragma message "Outline by kingeric1992 (ported by JPulowski)\n"

namespace JPulowski {

#if (OutlineEdgeDetection == 0)

texture NormalizedDepthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F; };
sampler NormalizedDepth { Texture = NormalizedDepthTex; };

void PS_NormalizeDepth(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0, out float3 normalizedDepth : SV_TARGET) {
	float4 depth = float4(tex2D(ReShade::LinearizedDepth, texcoord + float2(ReShade::PixelSize.x,                  0.0)).x,
				          tex2D(ReShade::LinearizedDepth, texcoord - float2(ReShade::PixelSize.x,                  0.0)).x,
						  tex2D(ReShade::LinearizedDepth, texcoord + float2(                 0.0, ReShade::PixelSize.y)).x,
						  tex2D(ReShade::LinearizedDepth, texcoord - float2(                 0.0, ReShade::PixelSize.y)).x);
						  
	float2 delta = float2(depth.x - depth.y, depth.z - depth.w) * ReShade::ScreenSize;
	
	normalizedDepth = normalize(float3(delta, 1.0));
}

#endif

float3 PS_Outline(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
	
	#if (OutlineCustomBackground == 0)
		float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
		#define OutlineBG tex2D(ReShade::BackBuffer, texcoord).rgb
	#else
		float3 color = OutlineBackgroundColor;
		#define OutlineBG OutlineBackgroundColor
	#endif
	
	#if (OutlineEdgeDetection == 0)
		#define EDTexture NormalizedDepth
	#else
		#define EDTexture ReShade::BackBuffer
	#endif
	
	// Sobel operator matrices
	float3 Gx[3] =
	{
		float3(-1.0, 0.0, 1.0),
		float3(-2.0, 0.0, 2.0),
		float3(-1.0, 0.0, 1.0)
	};
	
	float3 Gy[3] =
	{
		float3( 1.0,  2.0,  1.0),
		float3( 0.0,  0.0,  0.0),
		float3(-1.0, -2.0, -1.0)
	};
	
	float3 dotx = 0.0;
	float3 doty = 0.0;
	
	int j;
	
	// Edge detection
	for(int i = 0; i < 3; i++) {
		j = i - 1;
		dotx += Gx[i].x * tex2D(EDTexture, texcoord + float2(-ReShade::PixelSize.x, ReShade::PixelSize.y * j)).rgb;
		dotx += Gx[i].y * tex2D(EDTexture, texcoord + float2(                  0.0, ReShade::PixelSize.y * j)).rgb;
		dotx += Gx[i].z * tex2D(EDTexture, texcoord + float2( ReShade::PixelSize.x, ReShade::PixelSize.y * j)).rgb;
		
		doty += Gy[i].x * tex2D(EDTexture, texcoord + float2(-ReShade::PixelSize.x, ReShade::PixelSize.y * j)).rgb;
		doty += Gy[i].y * tex2D(EDTexture, texcoord + float2(                  0.0, ReShade::PixelSize.y * j)).rgb;
		doty += Gy[i].z * tex2D(EDTexture, texcoord + float2( ReShade::PixelSize.x, ReShade::PixelSize.y * j)).rgb;
	}
	
	// Boost edge detection
	dotx *= OutlineAccuracy;
	doty *= OutlineAccuracy;
	
	color = lerp(color, OutlineColor, sqrt(dot(dotx, dotx) + dot(doty, doty)) >= OutlineThreshold); // Return custom color when weight over threshold
	
	// Set opacity
	color = lerp(OutlineBG, color, OutlineOpacity);
	
	return color;
}

technique Outline_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = Outline_ToggleKey; >
{
	
#if (OutlineEdgeDetection == 0)
	
	pass DepthNormalization
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_NormalizeDepth;
		RenderTarget = NormalizedDepthTex;
	}

#endif
	
	pass Outline
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Outline;
	}
}

}

#endif

#include "ReShade/Shaders/JPulowski.undef"