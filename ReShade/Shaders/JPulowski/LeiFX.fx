/*
 "LeiFX" shader
 https://github.com/libretro/common-shaders/tree/master/3dfx
 
 Copyright (C) 2013-2014 leilei
 
 This program is free software; you can redistribute it and/or modify it
 under the terms of the GNU General Public License as published by the Free
 Software Foundation; either version 2 of the License, or (at your option)
 any later version.
 
 Modified and optimized for ReShade by JPulowski
 
 Do not distribute without giving credit to the original author(s).

 1.0  - Initial release
 */

#include EFFECT_CONFIG(JPulowski)

#if (USE_LEIFX == 1)

namespace JPulowski {

float4 PS_LEIFX_P0(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {

	float4 col = tex2D(ReShade::BackBuffer, texcoord);
	float2 ditheu = texcoord * ReShade::ScreenSize;

	int ditdex = int(ditheu.x % 4.0) * 4 + int(ditheu.y % 4.0); // 4x4!
	
	int ohyes;
	
	float erroredtable[16] = {
	16.0,  4.0, 13.0,  1.0,   
	 8.0, 12.0,  5.0,  9.0,
	14.0,  2.0, 15.0,  3.0,
	 6.0, 10.0,  7.0, 11.0
	};
	
	// looping through a lookup table matrix
	// Dither method adapted from xTibor on Shadertoy ("Ordered Dithering"), generously
	// put into the public domain.  Thanks!
	for (int i = ditdex; i < (ditdex + 16); i++) {
		ohyes = pow(erroredtable[i - 15], 0.72);
	}

	// Adjust the dither thing
	ohyes = 17 - (ohyes - 1); // invert
	ohyes = mad(ohyes, DitherAmount, DitherBias);

	col.rgb = float3(mad(col.r, 255.0, ohyes), mad(col.g, 255.0, ohyes * 0.5), mad(col.b, 255.0, ohyes)) / 255.0;

	// Reduce to 16-bit color
	float radooct = 32.0;	// 32 is usually the proper value
	col.rgb *= float3(radooct, radooct * 2.0, radooct);
	col.rgb  = floor(col.rgb);
	col.rgb /= float3(radooct, radooct * 2.0, radooct);

	// Add the purple line of lineness here, so the filter process catches it and gets gammaed.
	if ((ditheu.y % 2.0) < 1.0) {
		col.rb = mad(LeiFXLines, 0.1, col.rb);
	}

	return col;
}

float4 PS_LEIFX_P1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	
	float4 col = tex2D(ReShade::BackBuffer, texcoord);

	float3 pixel1 = tex2D(ReShade::BackBuffer, texcoord + float2( ReShade::ScreenSize.x, 0.0)).rgb;
	float3 pixel2 = tex2D(ReShade::BackBuffer, texcoord + float2(-ReShade::ScreenSize.x, 0.0)).rgb;

	// New filter
	float3 pixeldiff = pixel2 - col.rgb;
	float3 pixeldiffleft = pixel1 - col.rgb;

	pixeldiff = min(pixeldiff, float3( FiltCap,  FiltCapG, FiltCap));
	pixeldiff = max(pixeldiff, float3(-FiltCap, -FiltCapG,-FiltCap));
	
	pixeldiffleft = min(pixeldiffleft, float3( FiltCap,  FiltCapG, FiltCap));
	pixeldiffleft = max(pixeldiffleft, float3(-FiltCap, -FiltCapG,-FiltCap));

	col.rgb += (pixeldiff * 0.25) + (pixeldiffleft * 0.0625);

	return col;
}

float4 PS_LEIFX_P2(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {

	// Gamma scanlines
	// the Voodoo drivers usually supply a 1.3 gamma setting whether people liked it or not
	// but it was enough to brainwash the competition for looking 'too dark'

   return pow(abs(tex2D(ReShade::BackBuffer, texcoord)), 1.0 / GammaLevel);
}


technique LeiFX_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = LeiFX_ToggleKey; >
{
	pass LEIFX_P0
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P0;
	}
	
	pass LEIFX_P1
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
		
	pass LEIFX_P2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
	
	pass LEIFX_P3
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
	
	pass LEIFX_P4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
	
	pass LEIFX_P5
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P2;
	}
}

}

#endif

#include "ReShade/Shaders/JPulowski.undef"