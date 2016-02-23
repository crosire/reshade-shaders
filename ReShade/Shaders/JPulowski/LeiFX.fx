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
 1.0a - Fixed a bug caused by a typo
		Minor optimizations
 */

#include EFFECT_CONFIG(JPulowski)

#if (USE_LEIFX == 1)

namespace JPulowski {

float3 PS_LEIFX_P0(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {

	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	int ditdex = floor(vpos.x % 4.0) * 4 + floor(vpos.y % 4.0); // 4x4!
	
	float ohyes;
	
	/*
	float erroredtable[16] = {
	16.0,  4.0, 13.0,  1.0,   
	 8.0, 12.0,  5.0,  9.0,
	14.0,  2.0, 15.0,  3.0,
	 6.0, 10.0,  7.0, 11.0
	};
	*/
	
	// Pre-calculated table, x ^ 0.72
	
	float erroredtable[16] = {
	7.36150122, 2.71320868, 6.33926964, 1.0,   
	4.46914864, 5.98426056, 3.18609262, 4.86468363,
	6.68670511, 1.64718199, 7.02725506, 2.20560288,
	3.63302922, 5.24807453, 4.05948162, 5.62085962
	};
	
	// looping through a lookup table matrix
	// Dither method adapted from xTibor on Shadertoy ("Ordered Dithering"), generously
	// put into the public domain.  Thanks!
	for (int i = ditdex; i < (ditdex + 16); i++) {
		//ohyes = pow(erroredtable[i - 15], 0.72);
		ohyes = erroredtable[i - 15];
	}

	// Adjust the dither thing
	ohyes = 18.0 - ohyes; // invert
	ohyes = (ohyes * DitherAmount) + DitherBias;
	
	col.rb = (col.rb * 255.0) + ohyes;
	col.g *= 255.0;
	col.g += (ohyes * 0.5);
	col   *= 0.00392156886;	// Divide by 255

	// Reduce to 16-bit color
	float3 radooct = float3(32.0, 64.0, 32.0);	// 32 is usually the proper value
	float3 rcpradooct = float3(0.03125, 0.015625, 0.03125);
	col  = floor(col.rgb * radooct) * rcpradooct;

	// Add the purple line of lineness here, so the filter process catches it and gets gammaed.
	if (vpos.y % 2.0 == 0.0) {
		col.rb += LeiFXLines * 0.1;
	}

	return col;
}

float3 PS_LEIFX_P1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 pixel1 = tex2D(ReShade::BackBuffer, texcoord + float2( ReShade::PixelSize.x, 0.0)).rgb;
	float3 pixel2 = tex2D(ReShade::BackBuffer, texcoord + float2(-ReShade::PixelSize.x, 0.0)).rgb;

	// New filter
	float3 pixeldiff = pixel2 - col;
	float3 pixeldiffleft = pixel1 - col;

	pixeldiff = clamp(pixeldiff, float3(-FiltCap, -FiltCapG, -FiltCap), float3(FiltCap, FiltCapG, FiltCap));
	pixeldiffleft = clamp(pixeldiffleft, float3(-FiltCap, -FiltCapG, -FiltCap), float3(FiltCap, FiltCapG, FiltCap));

	col += pixeldiff * 0.25;
	col += pixeldiffleft * 0.0625;

	return col;
}

float3 PS_LEIFX_P2(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {

	// Gamma scanlines
	// the Voodoo drivers usually supply a 1.3 gamma setting whether people liked it or not
	// but it was enough to brainwash the competition for looking 'too dark'

   return pow(abs(tex2D(ReShade::BackBuffer, texcoord).rgb), 1.0 / GammaLevel);
}

technique LeiFX_Tech <bool enabled = RFX_Start_Enabled; int toggle = LeiFX_ToggleKey; >
{
	pass DitherAndReduction
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P0;
	}
	
	pass PixelFiltering
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
		
	pass PixelFiltering
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
	
	pass PixelFiltering
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
	
	pass PixelFiltering
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P1;
	}
	
	pass GammaProcess
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LEIFX_P2;
	}
}

}

#endif

#include "ReShade/Shaders/JPulowski.undef"