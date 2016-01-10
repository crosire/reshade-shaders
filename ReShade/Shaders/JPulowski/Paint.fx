/*
 Basic kuwahara filtering by Jan Eric Kyprianidis <www.kyprianidis.com>
 https://code.google.com/p/gpuakf/source/browse/glsl/kuwahara.glsl
 
 Copyright (C) 2009-2011 Computer Graphics Systems Group at the
 Hasso-Plattner-Institut, Potsdam, Germany <www.hpi3d.de>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 Paint effect shader for ENB by kingeric1992
 http://enbseries.enbdev.com/forum/viewtopic.php?f=7&t=3244#p53168
 
 Modified and optimized for ReShade by JPulowski
 http://reshade.me/forum/shader-presentation/261-paint-effect-and-depth-buffer-based-cel-shading
 
 Do not distribute without giving credit to the original author(s).
 
 1.0  - Initial release/port
 1.0a - Modified the code to make it compatible with SweetFX 2.0 Preview 7 and new Operation Piggyback which should give some performance increase
 1.1  - Removed SweetFX Operation Piggyback compatibility
        Added Framework compatibility 
*/

#include EFFECT_CONFIG(JPulowski)

#if (USE_PAINT == 1)

namespace JPulowski {

float3 PS_Paint(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
	//Shared content, might add more stuff later
	//TO-DO: Look for ways to simplify the code by combining two shaders
	float3 color, c;
	int i, j;

#if (PaintMethod == 0)
	float	Intensitycount0, Intensitycount1, Intensitycount2, Intensitycount3, Intensitycount4,
			Intensitycount5, Intensitycount6, Intensitycount7, Intensitycount8, Intensitycount9;

	float3	color0, color1, color2, color3, color4,
			color5, color6, color7, color8, color9;

	int	lum, Maxcount = 0;

	for(i = -PaintRadius; i < (PaintRadius + 1); i++){
		for(j = -PaintRadius; j < (PaintRadius + 1); j++){
			c = tex2D(s0, texcoord + float2(RFX_PixelSize * float2(i,j))).rgb;

			lum = dot(c, float3(0.2126, 0.7152, 0.0722)) * 9;

			Intensitycount0 = ( lum == 0) ? Intensitycount0 + 1 : Intensitycount0;
			Intensitycount1 = ( lum == 1) ? Intensitycount1 + 1 : Intensitycount1;
			Intensitycount2 = ( lum == 2) ? Intensitycount2 + 1 : Intensitycount2;
			Intensitycount3 = ( lum == 3) ? Intensitycount3 + 1 : Intensitycount3;
			Intensitycount4 = ( lum == 4) ? Intensitycount4 + 1 : Intensitycount4;
			Intensitycount5 = ( lum == 5) ? Intensitycount5 + 1 : Intensitycount5;
			Intensitycount6 = ( lum == 6) ? Intensitycount6 + 1 : Intensitycount6;
			Intensitycount7 = ( lum == 7) ? Intensitycount7 + 1 : Intensitycount7;
			Intensitycount8 = ( lum == 8) ? Intensitycount8 + 1 : Intensitycount8;
			Intensitycount9 = ( lum == 9) ? Intensitycount9 + 1 : Intensitycount9;
				
			color0 = ( lum == 0) ? color0 + c : color0;
			color1 = ( lum == 1) ? color1 + c : color1;
			color2 = ( lum == 2) ? color2 + c : color2;
			color3 = ( lum == 3) ? color3 + c : color3;
			color4 = ( lum == 4) ? color4 + c : color4;
			color5 = ( lum == 5) ? color5 + c : color5;
			color6 = ( lum == 6) ? color6 + c : color6;
			color7 = ( lum == 7) ? color7 + c : color7;
			color8 = ( lum == 8) ? color8 + c : color8;
			color9 = ( lum == 9) ? color9 + c : color9;
		}
	}	
		
	if(Intensitycount0 > Maxcount){Maxcount = Intensitycount0; color = color0 / Maxcount;}
	if(Intensitycount1 > Maxcount){Maxcount = Intensitycount1; color = color1 / Maxcount;}
	if(Intensitycount2 > Maxcount){Maxcount = Intensitycount2; color = color2 / Maxcount;}
	if(Intensitycount3 > Maxcount){Maxcount = Intensitycount3; color = color3 / Maxcount;}
	if(Intensitycount4 > Maxcount){Maxcount = Intensitycount4; color = color4 / Maxcount;}
	if(Intensitycount5 > Maxcount){Maxcount = Intensitycount5; color = color5 / Maxcount;}
	if(Intensitycount6 > Maxcount){Maxcount = Intensitycount6; color = color6 / Maxcount;}
	if(Intensitycount7 > Maxcount){Maxcount = Intensitycount7; color = color7 / Maxcount;}
	if(Intensitycount8 > Maxcount){Maxcount = Intensitycount8; color = color8 / Maxcount;}
	if(Intensitycount9 > Maxcount){Maxcount = Intensitycount9; color = color9 / Maxcount;}

#else
	
     float n = float((PaintRadius + 1) * (PaintRadius + 1));
	 
	 float3 m0, m1, m2, m3,
		k0, k1, k2, k3;

     for (j = -PaintRadius; j <= 0; ++j)  {
         for (i = -PaintRadius; i <= 0; ++i)  {
             c = tex2D(s0, texcoord + float2(i,j) / RFX_ScreenSize).rgb;
             m0 += c;
             k0 += c * c;
         }
     }

     for (j = -PaintRadius; j <= 0; ++j)  {
         for (i = 0; i <= PaintRadius; ++i)  {
             c = tex2D(s0, texcoord + float2(i,j) / RFX_ScreenSize).rgb;
             m1 += c;
             k1 += c * c;
         }
     }

     for (j = 0; j <= PaintRadius; ++j)  {
         for (i = 0; i <= PaintRadius; ++i)  {
             c = tex2D(s0, texcoord + float2(i,j) / RFX_ScreenSize).rgb;
             m2 += c;
             k2 += c * c;
         }
     }

     for (j = 0; j <= PaintRadius; ++j)  {
         for (i = -PaintRadius; i <= 0; ++i)  {
             c = tex2D(s0, texcoord + float2(i,j) / RFX_ScreenSize).rgb;
             m3 += c;
             k3 += c * c;
         }
     }

     float min_sigma2 = 1e+2;
     m0 /= n;
     k0 = abs(k0 / n - m0 * m0);

     float sigma2 = k0.r + k0.g + k0.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         color = m0;
     }

     m1 /= n;
     k1 = abs(k1 / n - m1 * m1);

     sigma2 = k1.r + k1.g + k1.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         color = m1;
     }

     m2 /= n;
     k2 = abs(k2 / n - m2 * m2);

     sigma2 = k2.r + k2.g + k2.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         color = m2;
     }

     m3 /= n;
     k3 = abs(k3 / n - m3 * m3);

     sigma2 = k3.r + k3.g + k3.b;
     if (sigma2 < min_sigma2) {
         min_sigma2 = sigma2;
         color = m3;
     }
	 
#endif

return color;
}

technique Paint_Tech <bool enabled = RFX_Start_Enabled; int toggle = Paint_ToggleKey; >
{
	pass PaintPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Paint;
	}
}

}

#endif

#include "ReShade/Shaders/JPulowski.undef"