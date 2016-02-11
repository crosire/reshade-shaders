/*
 Dos Game shader by Boris Vorontsov
 http://enbdev.com/effect_dosgame.zip
*/

#include EFFECT_CONFIG(Iddqd)

#if USE_DOSFX

namespace Iddqd
{

float4 PS_DosFX(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 xs = ReShade::ScreenSize / PIXELSIZE;
	
	#if (ENABLE_SCREENSIZE == 1)
	xs=DOSScreenSize;
	#endif
	
	texcoord.xy=floor(texcoord.xy * xs)/xs;

	float4 origcolor=tex2D(ReShade::BackBuffer, texcoord);

	origcolor+=0.0001;

    #if (DOSCOLOR == 1)
	float graymax=max(origcolor.x, max(origcolor.y, origcolor.z));
	float3 ncolor=origcolor.xyz/graymax;
	graymax=floor(graymax * DOSColorsCount)/DOSColorsCount;
	origcolor.xyz*=graymax;
	#if (ENABLE_POSTCURVE == 1)
	origcolor.xyz = pow(origcolor.xyz, POSTCURVE);
	#endif
    #endif

	return origcolor;
}

float4 PS_DosGamma(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
float4 color=tex2D(ReShade::BackBuffer, texcoord);
color.xyz = lerp(color.xyz,-0.0039*pow(1.0/0.0039, 1.0-color.xyz)+1.0,0.7*(DoSgammaValue/2.2));
return color;
}

technique DosFX_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = Dos_ToggleKey; >
{
	#if ENABLE_AGD
	pass DosFXGammaPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_DosGamma;
	}
	#endif
	pass DosFXPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_DosFX;
	}
}

}

#endif

#include "ReShade/Shaders/Iddqd.undef"
