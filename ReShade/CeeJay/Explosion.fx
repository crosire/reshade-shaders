#include "Common.fx"

#ifndef RFX_duplicate
#include CeeJay_SETTINGS_DEF
#endif

#if (USE_EXPLOSION == 1)

   /*-----------------------------------------------------------.   
  /                         Explosion                           /
  '-----------------------------------------------------------*/

namespace CeeJay
{

float4 ExplosionPass( float4 colorInput, float2 tex )
{
	// -- pseudo random number generator --
	float2 sine_cosine;
	sincos(dot(tex, float2(12.9898,78.233)),sine_cosine.x,sine_cosine.y);
	sine_cosine = sine_cosine * 43758.5453 + tex;
	float2 noise = frac(sine_cosine);

	tex = (-Explosion_Radius * RFX_PixelSize) + tex; //Slightly faster this way because it can be calculated while we calculate noise.

	colorInput.rgb = myTex2D(s0, (2.0 * Explosion_Radius * RFX_PixelSize) * noise + tex).rgb;

	return colorInput;
}


float3 ExplosionWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 color = myTex2D(s0, texcoord);

	color = ExplosionPass(color,texcoord);

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color.rgb;
}

technique Explosion_Tech <bool enabled = 
#if (Explosion_TimeOut > 0)
1; int toggle = Explosion_ToggleKey; timeout = Explosion_TimeOut; >
#else
RFX_Start_Enabled; int toggle = Explosion_ToggleKey; >
#endif
{
	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = ExplosionWrap;
	}
}

}

#include "ReShade\CeeJay\PiggyCount.h"
#endif

#ifndef RFX_duplicate
#include CeeJay_SETTINGS_UNDEF
#endif
