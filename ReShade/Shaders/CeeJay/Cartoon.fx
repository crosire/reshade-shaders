#include "Common.fx"
#include CeeJay_SETTINGS_DEF

#if (USE_CARTOON == 1)

/*------------------------------------------------------------------------------
						Cartoon
------------------------------------------------------------------------------*/

#ifndef CartoonEdgeSlope //for backwards compatiblity with settings preset from earlier versions of CeeJay
  #define CartoonEdgeSlope 1.5 
#endif

namespace CeeJay
{

float4 CartoonPass( float4 colorInput, float2 Tex )
{
  float3 CoefLuma2 = float3(0.2126, 0.7152, 0.0722);  //Values to calculate luma with
  
  float diff1 = dot(CoefLuma2,myTex2D(s0, Tex + ReShade::PixelSize).rgb);
  diff1 = dot(float4(CoefLuma2,-1.0),float4(myTex2D(s0, Tex - ReShade::PixelSize).rgb , diff1));
  
  float diff2 = dot(CoefLuma2,myTex2D(s0, Tex +float2(ReShade::PixelSize.x,-ReShade::PixelSize.y)).rgb);
  diff2 = dot(float4(CoefLuma2,-1.0),float4(myTex2D(s0, Tex +float2(-ReShade::PixelSize.x,ReShade::PixelSize.y)).rgb , diff2));
	
  float edge = dot(float2(diff1,diff2),float2(diff1,diff2));
  
  colorInput.rgb =  pow(edge,CartoonEdgeSlope) * -CartoonPower + colorInput.rgb;
	
  return saturate(colorInput);
}

float3 CartoonWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 color = myTex2D(s0, texcoord);

	color = CartoonPass(color,texcoord);

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color.rgb;
}

technique Cartoon_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = Cartoon_ToggleKey; >
{
	pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = CartoonWrap;
	}
}

}

#include "ReShade\Shaders\CeeJay\PiggyCount.h"
#endif

#include CeeJay_SETTINGS_UNDEF
