// Copyright (c) 2016, bacondither
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Colourfulness - version 2016-09-04 - (requires ps >= ps_2_b)
// EXPECTS FULL RANGE GAMMA LIGHT

uniform float colourfulness <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 2.0;
	ui_tooltip = "Degree of colourfulness, 0 = neutral";
	ui_step = 0.01;
> = 0.4;

uniform float lim_luma <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 1.0;
	ui_tooltip = "Lower vals allow more change near clipping";
	ui_step = 0.01;
> = 0.7;

#include "Reshade.fxh"

// Soft limit, modified tanh approximation
#define soft_lim(v,s)  ( clamp((v/s)*(27 + pow(v/s, 2))/(27 + 9*pow(v/s, 2)), -1, 1)*s )

// Weighted power mean, p=0.5
#define wpmean(a,b,w)  ( pow((abs(w)*sqrt(abs(a)) + abs(1-w)*sqrt(abs(b))), 2) )

// Max RGB components
#define max3(RGB)      ( max((RGB).r, max((RGB).g, (RGB).b)) )

// sRGB gamma approximation
#define to_linear(G)   ( pow((G) + 0.06, 2.4) )
#define to_gamma(LL)   ( pow((LL), 1.0/2.4) - 0.06 )

// Mean of Rec. 709 & 601 luma coefficients
#define lumacoeff        float3(0.2558, 0.6511, 0.0931)

float3 Colourfulness(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 c0  = saturate(tex2D(ReShade::BackBuffer, texcoord).rgb);
	float luma = to_gamma( max(dot(to_linear(c0), lumacoeff), 0) );

	float3 colour = luma + (c0 - luma)*(max(colourfulness, -1) + 1);

	float3 diff = colour - c0;

	if (colourfulness > 0.0)
	{
		// 120% of colour clamped to max range + overshoot
		float3 ccldiff = clamp((diff*1.2) + c0, -0.0001, 1.0001) - c0;

		// Calculate maximum saturation-increase without altering ratios for RGB
		float3 diff_luma = c0 - luma;

		float poslim = (1.0001 - luma)/max3(max(diff_luma, 0));
		float neglim = (luma + 0.0001)/max3(abs(min(diff_luma, 0)));

		float diffmul = min(min(abs(poslim), abs(neglim)), 32);

		float3 diffmax = (luma + diff_luma*diffmul) - c0;

		// Soft limit diff
		diff = soft_lim( diff, wpmean(diffmax, ccldiff, lim_luma) );
	}

	return c0 + diff;
}

technique Colourfulness
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = Colourfulness;
	}
}
