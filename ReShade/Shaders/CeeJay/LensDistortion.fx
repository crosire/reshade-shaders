/*-----------------------------------------------------------.
/                    Cubic Lens Distortion                    /
'-----------------------------------------------------------*/

/*
Cubic Lens Distortion HLSL Shader

Original Lens Distortion Algorithm from SSontech (Syntheyes)
http://www.ssontech.com/content/lensalg.htm

r2 = image_aspect*image_aspect*u*u + v*v
f = 1 + r2*(k + kcube*sqrt(r2))
u' = f*u
v' = f*v

author : François Tarlier
website : http://www.francois-tarlier.com/blog/tag/lens-distortion/
*/

#include EFFECT_CONFIG(CeeJay)
#include "Common.fx"

#if USE_LENS_DISTORTION

#pragma message "Cubic Lens Distortion by Francois Tarlier (ported by CeeJay)\n"

namespace CeeJay
{

float3 LensDistortionPass(float2 tex)
{
	// lens distortion coefficient (between
	float k = -0.15;

	// cubic distortion value
	float kcube = 0.5;

	float r2 = (tex.x-0.5) * (tex.x-0.5) + (tex.y-0.5) * (tex.y-0.5);       
	float f = 0.0;

	//only compute the cubic distortion if necessary
	if (kcube == 0.0)
	{
		f = 1 + r2 * k;
	}
	else
	{
		f = 1 + r2 * (k + kcube * sqrt(r2));
	};

	// get the right pixel for the current position
	float x = f*(tex.x-0.5)+0.5;
	float y = f*(tex.y-0.5)+0.5;
	float3 inputDistord = tex2D(BorderSampler,float2(x,y)).rgb;

	return inputDistord;
}

float3 LensDistortionWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = LensDistortionPass(texcoord).rgb;

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color.rgb;
}

technique Distortion_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = RESHADE_TOGGLE_KEY; >
{
	pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = LensDistortionWrap;
	}
}

}

#include "PiggyCount.h"
#endif

#include EFFECT_CONFIG_UNDEF(CeeJay)
