// Copyright (c) 2015-2016, bacondither
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

// Adaptive sharpen - version 2016-01-12 - (requires ps >= 3.0)
// Tuned for use post resize, EXPECTS FULL RANGE GAMMA LIGHT

/* Modified for ReShade by JPulowski

   Changelog:
   1.0  - Initial release
   1.1  - Updated to version 2015-11-05
   1.2  - Updated to version 2015-11-17, fixed tanh overflow causing black pixels
   1.2a - Speed optimizations
   1.3  - Updated to version 2016-01-12

*/

#include EFFECT_CONFIG(bacondither)

#if (USE_ADAPTIVESHARPEN == 1)

namespace bacondither
{

texture Pass0Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler Pass0_Sampler { Texture = Pass0Tex; };

// Get destination pixel values
#define get1(x,y)      ( saturate(tex2D(ReShade::BackBuffer, texcoord + (ReShade::PixelSize * float2(x, y))).rgb) )
#define get2(x,y)      ( tex2D(Pass0_Sampler, texcoord + (ReShade::PixelSize * float2(x, y))).xy )

// Compute diff
#define b_diff(z)      ( abs(blur-c[z]) )

// Saturation loss reduction
#define minim_satloss  ( (satorig*min((d[0].y + sharpdiff)/d[0].y, 1e+5) + (satorig + sharpdiff))/2 )

// Soft if, fast
#define soft_if(a,b,c) ( saturate((a + b + c)/(saturate(maxedge) + 0.0067) - 0.85) )

// Soft limit, modified tanh
#define soft_lim(v,s)  ( ((exp(2*min(abs(v), s*16)/s) - 1)/(exp(2*min(abs(v), s*16)/s) + 1))*s )

// Maximum of four values
#define max4(a,b,c,d)  ( max(max(a,b), max(c,d)) )

// Colour to luma, fast approx gamma
#define CtL(RGB)       ( sqrt(dot(float3(0.256, 0.651, 0.093), saturate((RGB).rgb*abs(RGB).rgb))) )

// Center pixel diff
#define mdiff(a,b,c,d,e,f,g) ( abs(luma[g]-luma[a]) + abs(luma[g]-luma[b])			 \
                             + abs(luma[g]-luma[c]) + abs(luma[g]-luma[d])			 \
                             + 0.5*(abs(luma[g]-luma[e]) + abs(luma[g]-luma[f])) )

void AdaptiveSharpenP0(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float2 P0_OUT : SV_Target0) {

	// Get points and saturate out of range values (BTB & WTW)
	// [                c22               ]
	// [           c24, c9,  c23          ]
	// [      c21, c1,  c2,  c3, c18      ]
	// [ c19, c10, c4,  c0,  c5, c11, c16 ]
	// [      c20, c6,  c7,  c8, c17      ]
	// [           c15, c12, c14          ]
	// [                c13               ]
	float3 c[25] = { get1( 0, 0), get1(-1,-1), get1( 0,-1), get1( 1,-1), get1(-1, 0),
	                 get1( 1, 0), get1(-1, 1), get1( 0, 1), get1( 1, 1), get1( 0,-2),
	                 get1(-2, 0), get1( 2, 0), get1( 0, 2), get1( 0, 3), get1( 1, 2),
	                 get1(-1, 2), get1( 3, 0), get1( 2, 1), get1( 2,-1), get1(-3, 0),
	                 get1(-2, 1), get1(-2,-1), get1( 0,-3), get1( 1,-2), get1(-1,-2) };

	// RGB to luma
	float luma = CtL(c[0]);

	// Blur, gauss 3x3
	float3 blur   = (2*(c[2]+c[4]+c[5]+c[7]) + (c[1]+c[3]+c[6]+c[8]) + 4*c[0])/16;
	float  blur_Y = (blur.r/3 + blur.g/3 + blur.b/3);

	// Contrast compression, center = 0.5, scaled to 1/3
	float c_comp = saturate(0.266666681f + 0.9*pow(2, (-7.4*blur_Y)));

	// Edge detection
	// Matrix weights
	// [         1/4,        ]
	// [      1,  1,  1      ]
	// [ 1/4, 1,  1,  1, 1/4 ]
	// [      1,  1,  1      ]
	// [         1/4         ]
	float edge = length( b_diff(0) + b_diff(1) + b_diff(2) + b_diff(3)
	                   + b_diff(4) + b_diff(5) + b_diff(6) + b_diff(7) + b_diff(8)
	                   + 0.25*(b_diff(9) + b_diff(10) + b_diff(11) + b_diff(12)) );

	P0_OUT = float2( edge*c_comp, luma );
}

float3 AdaptiveSharpenP1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {

	float3 orig    = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 satorig = saturate(orig);

	// Get points, .x= edge, .y= luma
	// [                d22               ]
	// [           d24, d9,  d23          ]
	// [      d21, d1,  d2,  d3, d18      ]
	// [ d19, d10, d4,  d0,  d5, d11, d16 ]
	// [      d20, d6,  d7,  d8, d17      ]
	// [           d15, d12, d14          ]
	// [                d13               ]
	float2 d[25] = { get2( 0, 0), get2(-1,-1), get2( 0,-1), get2( 1,-1), get2(-1, 0),
	                 get2( 1, 0), get2(-1, 1), get2( 0, 1), get2( 1, 1), get2( 0,-2),
	                 get2(-2, 0), get2( 2, 0), get2( 0, 2), get2( 0, 3), get2( 1, 2),
	                 get2(-1, 2), get2( 3, 0), get2( 2, 1), get2( 2,-1), get2(-3, 0),
	                 get2(-2, 1), get2(-2,-1), get2( 0,-3), get2( 1,-2), get2(-1,-2) };

	// Allow for higher overshoot if the current edge pixel is surrounded by similar edge pixels
	float maxedge = max4( max4(d[1].x,d[2].x,d[3].x,d[4].x), max4(d[5].x,d[6].x,d[7].x,d[8].x),
	                      max4(d[9].x,d[10].x,d[11].x,d[12].x), d[0].x );

	// [          x          ]
	// [       z, x, w       ]
	// [    z, z, x, w, w    ]
	// [ y, y, y, 0, y, y, y ]
	// [    w, w, x, z, z    ]
	// [       w, x, z       ]
	// [          x          ]
	float var = soft_if(d[2].x,d[9].x,d[22].x) *soft_if(d[7].x,d[12].x,d[13].x)  // x dir
	          + soft_if(d[4].x,d[10].x,d[19].x)*soft_if(d[5].x,d[11].x,d[16].x)  // y dir
	          + soft_if(d[1].x,d[24].x,d[21].x)*soft_if(d[8].x,d[14].x,d[17].x)  // z dir
	          + soft_if(d[3].x,d[23].x,d[18].x)*soft_if(d[6].x,d[20].x,d[15].x); // w dir

	#if (fast_ops == 1)
		float s[2] = { lerp( L_compr_low, L_compr_high, saturate(var-2) ),
		               lerp( D_compr_low, D_compr_high, saturate(var-2) ) };
	#else
		float s[2] = { lerp( L_compr_low, L_compr_high, smoothstep(2, 3.1, var) ),
		               lerp( D_compr_low, D_compr_high, smoothstep(2, 3.1, var) ) };
	#endif

	float luma[25] = { d[0].y,  d[1].y,  d[2].y,  d[3].y,  d[4].y,
	                   d[5].y,  d[6].y,  d[7].y,  d[8].y,  d[9].y,
	                   d[10].y, d[11].y, d[12].y, d[13].y, d[14].y,
	                   d[15].y, d[16].y, d[17].y, d[18].y, d[19].y,
	                   d[20].y, d[21].y, d[22].y, d[23].y, d[24].y };

	// Precalculated default squared kernel weights
	float3 w1 = float3(0.5,           1.0, 1.41421356237); // 0.25, 1.0, 2.0
	float3 w2 = float3(0.86602540378, 1.0, 0.5477225575);  // 0.75, 1.0, 0.3

	// Transition to a concave kernel if the center edge val is above thr
	float3 dW = pow(lerp( w1, w2, smoothstep( 0.3, 0.6, d[0].x)), 2);

	float mdiff_c0  = 0.02 + 3*( abs(luma[0]-luma[2]) + abs(luma[0]-luma[4])
	                           + abs(luma[0]-luma[5]) + abs(luma[0]-luma[7])
	                           + 0.25*(abs(luma[0]-luma[1]) + abs(luma[0]-luma[3])
	                                  +abs(luma[0]-luma[6]) + abs(luma[0]-luma[8])) );

	// Use lower weights for pixels in a more active area relative to center pixel area.
	float weights[12]  = { ( dW.x ), ( dW.x ), ( dW.x ), ( dW.x ), // c2, // c4, // c5, // c7
	                       ( min(mdiff_c0/mdiff(24, 21, 2,  4,  9,  10, 1),  dW.y) ),   // c1
	                       ( min(mdiff_c0/mdiff(23, 18, 5,  2,  9,  11, 3),  dW.y) ),   // c3
	                       ( min(mdiff_c0/mdiff(4,  20, 15, 7,  10, 12, 6),  dW.y) ),   // c6
	                       ( min(mdiff_c0/mdiff(5,  7,  17, 14, 12, 11, 8),  dW.y) ),   // c8
	                       ( min(mdiff_c0/mdiff(2,  24, 23, 22, 1,  3,  9),  dW.z) ),   // c9
	                       ( min(mdiff_c0/mdiff(20, 19, 21, 4,  1,  6,  10), dW.z) ),   // c10
	                       ( min(mdiff_c0/mdiff(17, 5,  18, 16, 3,  8,  11), dW.z) ),   // c11
	                       ( min(mdiff_c0/mdiff(13, 15, 7,  14, 6,  8,  12), dW.z) ) }; // c12

	weights[4] = (max(max((weights[8]  + weights[9])/4,  weights[4]), 0.25) + weights[4])/2;
	weights[5] = (max(max((weights[8]  + weights[10])/4, weights[5]), 0.25) + weights[5])/2;
	weights[6] = (max(max((weights[9]  + weights[11])/4, weights[6]), 0.25) + weights[6])/2;
	weights[7] = (max(max((weights[10] + weights[11])/4, weights[7]), 0.25) + weights[7])/2;

	// Calculate the negative part of the laplace kernel and the low threshold weight
	float lowthsum    = 0;
	float weightsum   = 0;
	float neg_laplace = 0;

	static const int order[12] = { 2, 4, 5, 7, 1, 3, 6, 8, 9, 10, 11, 12 };

	[unroll]
	for (int pix = 0; pix < 12; ++pix)
	{
		#if (fast_ops == 1)
			float lowth = clamp(((10*d[order[pix]].x)-0.15), 0.01, 1);

			neg_laplace += pow(luma[order[pix]], 2)*(weights[pix]*lowth);
		#else
			float x = saturate((d[order[pix]].x - 0.01)/0.11);
			float lowth = x*x*(2.99 - 2*x) + 0.01;

			neg_laplace += pow(abs(luma[order[pix]]) + 0.064, 2.4)*(weights[pix]*lowth);
		#endif

		weightsum   += weights[pix]*lowth;
		lowthsum    += lowth;
	}

	#if (fast_ops == 1)
		neg_laplace = sqrt(neg_laplace/weightsum);
	#else
		neg_laplace = pow(abs(neg_laplace/weightsum), (1.0/2.4)) - 0.064;
	#endif

	// Compute sharpening magnitude function
	float sharpen_val = (lowthsum/12)*(curve_height/(curveslope*pow(abs(d[0].x), 3.5) + 0.5));

	// Calculate sharpening diff and scale
	float sharpdiff = (d[0].y - neg_laplace)*(sharpen_val*0.8 + 0.01);

	#if (fast_ops == 1)
		static const int numloop = 2;
	#else
		static const int numloop = 3;
	#endif

	// Calculate local near min & max, partial sort
	[unroll]
	for (int i = 0; i < numloop; ++i)
	{
		float temp;

		for (int i1 = i; i1 < 24-i; i1 += 2)
		{
			temp = luma[i1];
			luma[i1]   = min(luma[i1], luma[i1+1]);
			luma[i1+1] = max(temp, luma[i1+1]);
		}

		for (int i2 = 24-i; i2 > i; i2 -= 2)
		{
			temp = luma[i];
			luma[i]    = min(luma[i], luma[i2]);
			luma[i2]   = max(temp, luma[i2]);

			temp = luma[24-i];
			luma[24-i] = max(luma[24-i], luma[i2-1]);
			luma[i2-1] = min(temp, luma[i2-1]);
		}
	}

	#if (fast_ops == 1)
		float nmax = max((luma[23] + luma[24])/2, d[0].y);
		float nmin = min((luma[0]  + luma[1])/2,  d[0].y);
	#else
		float nmax = max(((luma[22] + luma[23]*2 + luma[24])/4), d[0].y);
		float nmin = min(((luma[0]  + luma[1]*2  + luma[2])/4),  d[0].y);
	#endif

	// Calculate tanh scale factor, pos/neg
	float nmax_scale = min(((nmax - d[0].y) + L_overshoot), max_scale_lim);
	float nmin_scale = min(((d[0].y - nmin) + D_overshoot), max_scale_lim);

	// Soft limit sharpening with tanh, lerp to control maximum compression
	sharpdiff = lerp(  (soft_lim(max(sharpdiff, 0), nmax_scale)), max(sharpdiff, 0), s[0] )
	          + lerp( -(soft_lim(min(sharpdiff, 0), nmin_scale)), min(sharpdiff, 0), s[1] );

	/*if (video_level_out == true)
	{
		[flatten]
		if (sharpdiff > 0) { return ( orig + (minim_satloss - satorig) ); }

		else { return ( orig + sharpdiff ); }
	}*/

	// Normal path
	[flatten]
	if (sharpdiff > 0) { return minim_satloss; }

	else { return ( satorig + sharpdiff ); }
}

technique AdaptiveSharpen_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = AdaptiveSharpen_ToggleKey; >
{
	pass AdaptiveSharpenPass1
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader  = AdaptiveSharpenP0;
		RenderTarget = Pass0Tex;
	}
	
	pass AdaptiveSharpenPass2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader  = AdaptiveSharpenP1;
	}
}

#undef get1
#undef get2
#undef b_diff
#undef minim_satloss
#undef soft_if
#undef soft_lim
#undef max4
#undef CtL
#undef mdiff

}

#endif

#include "ReShade/Shaders/bacondither.undef"
