NAMESPACE_ENTER(Various)

#include Various_SETTINGS_DEF

#if USE_DOSFX

float4 PS_DosFX(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 xs = RFX_ScreenSize / PIXELSIZE;
	
	#if (ENABLE_SCREENSIZE == 1)
	xs.y=RFX_ScreenSizeFull.x*RFX_ScreenSizeFull.w;
	xs=DOSScreenSize;
	#endif
	
	texcoord.xy=floor(texcoord.xy * xs)/xs;

	float4 origcolor=tex2D(RFX_backbufferColor, texcoord);

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
float4 color=tex2D(RFX_backbufferColor, texcoord);
color.xyz = lerp(color.xyz,-0.0039*pow(1.0/0.0039, 1.0-color.xyz)+1.0,0.7*(DoSgammaValue/2.2));
return color;
}

technique DosFX_Tech <bool enabled = RFX_Start_Enabled; int toggle = Dos_ToggleKey; >
{
	#if ENABLE_AGD
	pass DosFXGammaPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_DosGamma;
	}
	#endif
	pass DosFXPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_DosFX;
	}
}

#endif

#include Various_SETTINGS_UNDEF

NAMESPACE_LEAVE()
