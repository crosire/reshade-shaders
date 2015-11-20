// Copyright (c) 2015, bacondither
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

// Adaptive sharpen - version 2015-11-17 - (requires ps >= 3.0)
// Tuned for use post resize, EXPECTS FULL RANGE GAMMA LIGHT

/* Modified for ReShade by JPulowski
   
   Changelog:
   1.0 - Initial release
   1.1 - Updated to version 2015-11-05
   1.2 - Updated to version 2015-11-17, fixed tanh overflow causing black pixels
   
*/   

NAMESPACE_ENTER(CFX)
#include CFX_SETTINGS_DEF

#if (USE_ADAPTIVESHARPEN == 1)

texture edgeTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler edgeSampler { Texture = edgeTex; };	

// Edge channel offset, must be the same in both passes
#define w_offset  2.0

// Get destination pixel values
#define get1(x, y) ( saturate(tex2D(RFX_backbufferColor, texcoord + (RFX_PixelSize * float2(x, y))).rgb) )

// Compute diff
#define b_diff(z) ( abs(blur-c[z]) )

// Saturation loss reduction
#define minim_satloss  ( (c[0].rgb*(CtL(c[0].rgb + sharpdiff)/c0_Y) + (c[0].rgb + sharpdiff))/2 )

// Soft if, fast
#define soft_if(a,b,c) ( saturate((3*((a.w + b.w + c.w - 3*w_offset)/maxedge))-0.85) )

// Soft limit
#define soft_lim(v,s)  ( ((exp(2*min(abs(v), s*16)/s) - 1)/(exp(2*min(abs(v), s*16)/s) + 1))*s )

// Get destination pixel values
#define get2(x,y)      ( tex2D(edgeSampler, texcoord + (RFX_PixelSize * float2(x, y))) )
#define sat(input)     ( float4(saturate((input).xyz), (input).w) )

// Maximum of four values
#define max4(a,b,c,d)  ( max(max(a,b), max(c,d)) )

// Colour to luma, fast approx gamma
#define CtL(RGB)       ( sqrt(dot(float3(0.256, 0.651, 0.093), saturate((RGB).rgb*abs(RGB).rgb))) )

// Center pixel diff
#define mdiff(a,b,c,d,e,f,g) ( abs(luma[g]-luma[a]) + abs(luma[g]-luma[b])			 \
                             + abs(luma[g]-luma[c]) + abs(luma[g]-luma[d])			 \
                             + 0.5*(abs(luma[g]-luma[e]) + abs(luma[g]-luma[f])) )

void AdaptiveSharpenP0(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 edgeR : SV_Target0) {

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

	// Blur, gauss 3x3
	float3 blur   = (2*(c[2]+c[4]+c[5]+c[7]) + (c[1]+c[3]+c[6]+c[8]) + 4*c[0])/16;
	float  blur_Y = (blur.r/3 + blur.g/3 + blur.b/3);

	// Contrast compression, center = 0.5
	float c_comp = min((0.8+2.7*pow(2, (-7.4*blur_Y))), 3.0);

	// Edge detection
	// Matrix weights
	// [         1/4,        ]
	// [      4,  1,  4      ]
	// [ 1/4, 4,  1,  4, 1/4 ]
	// [      4,  1,  4      ]
	// [         1/4         ]
	float edge = length( b_diff(0) + b_diff(1) + b_diff(2) + b_diff(3)
	                   + b_diff(4) + b_diff(5) + b_diff(6) + b_diff(7) + b_diff(8)
	                   + 0.25*(b_diff(9) + b_diff(10) + b_diff(11) + b_diff(12)) );

	edge = min(((edge*c_comp)/3 + w_offset), 32 + w_offset);

	edgeR = float4( (tex2D(RFX_backbufferColor, texcoord).rgb), edge );
}

float4 AdaptiveSharpenP1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {

	float4 orig = tex2D(edgeSampler, texcoord);

	// Displays a green screen if the edge data is not inside a valid range in the .w channel
	if (orig.w > (w_offset+33) || orig.w < (w_offset-0.5)  ) { return float4(0, 1, 0, 1.0); }

	// Get points, saturate color data in c[0]
	// [                c22               ]
	// [           c24, c9,  c23          ]
	// [      c21, c1,  c2,  c3, c18      ]
	// [ c19, c10, c4,  c0,  c5, c11, c16 ]
	// [      c20, c6,  c7,  c8, c17      ]
	// [           c15, c12, c14          ]
	// [                c13               ]
	float4 c[25] = {  sat( orig), get2(-1,-1), get2( 0,-1), get2( 1,-1), get2(-1, 0),
	                 get2( 1, 0), get2(-1, 1), get2( 0, 1), get2( 1, 1), get2( 0,-2),
	                 get2(-2, 0), get2( 2, 0), get2( 0, 2), get2( 0, 3), get2( 1, 2),
	                 get2(-1, 2), get2( 3, 0), get2( 2, 1), get2( 2,-1), get2(-3, 0),
	                 get2(-2, 1), get2(-2,-1), get2( 0,-3), get2( 1,-2), get2(-1,-2) };

	// Allow for higher overshoot if the current edge pixel is surrounded by similar edge pixels
	float maxedge = max4( max4(c[1].w,c[2].w,c[3].w,c[4].w), max4(c[5].w,c[6].w,c[7].w,c[8].w),
	                      max4(c[9].w,c[10].w,c[11].w,c[12].w), c[0].w );

	maxedge  = saturate(maxedge - w_offset)*3 + 0.02;

	// [          x          ]
	// [       z, x, w       ]
	// [    z, z, x, w, w    ]
	// [ y, y, y, 0, y, y, y ]
	// [    w, w, x, z, z    ]
	// [       w, x, z       ]
	// [          x          ]
	float var = soft_if(c[2],c[9],c[22]) *soft_if(c[7],c[12],c[13])  // x dir
	          + soft_if(c[4],c[10],c[19])*soft_if(c[5],c[11],c[16])  // y dir
	          + soft_if(c[1],c[24],c[21])*soft_if(c[8],c[14],c[17])  // z dir
	          + soft_if(c[3],c[23],c[18])*soft_if(c[6],c[20],c[15]); // w dir

	float s[2] = { lerp( L_compr_low, L_compr_high, smoothstep(2, 3.1, var) ),
	               lerp( D_compr_low, D_compr_high, smoothstep(2, 3.1, var) ) };

	// RGB to luma
	float c0_Y = CtL(c[0]);

	float luma[25] = { c0_Y, CtL(c[1]), CtL(c[2]), CtL(c[3]), CtL(c[4]), CtL(c[5]), CtL(c[6]),
	                   CtL(c[7]),  CtL(c[8]),  CtL(c[9]),  CtL(c[10]), CtL(c[11]), CtL(c[12]),
	                   CtL(c[13]), CtL(c[14]), CtL(c[15]), CtL(c[16]), CtL(c[17]), CtL(c[18]),
	                   CtL(c[19]), CtL(c[20]), CtL(c[21]), CtL(c[22]), CtL(c[23]), CtL(c[24]) };

	// Pixel weights for the laplace kernel
	float mdiff_c0  = 0.02 + 3*( abs(luma[0]-luma[2]) + abs(luma[0]-luma[4])
	                           + abs(luma[0]-luma[5]) + abs(luma[0]-luma[7])
	                           + 0.25*(abs(luma[0]-luma[1]) + abs(luma[0]-luma[3])
	                                  +abs(luma[0]-luma[6]) + abs(luma[0]-luma[8])) );

	float weights[12]  = { ( 0.25 ), ( 0.25 ), ( 0.25 ), ( 0.25 ), // c2, // c4, // c5, // c7
	                       ( min((mdiff_c0/mdiff(24, 21, 2,  4,  9,  10, 1)),  1) ),    // c1
	                       ( min((mdiff_c0/mdiff(23, 18, 5,  2,  9,  11, 3)),  1) ),    // c3
	                       ( min((mdiff_c0/mdiff(4,  20, 15, 7,  10, 12, 6)),  1) ),    // c6
	                       ( min((mdiff_c0/mdiff(5,  7,  17, 14, 12, 11, 8)),  1) ),    // c8
	                       ( min((mdiff_c0/mdiff(2,  24, 23, 22, 1,  3,  9)),  2) ),    // c9
	                       ( min((mdiff_c0/mdiff(20, 19, 21, 4,  1,  6,  10)), 2) ),    // c10
	                       ( min((mdiff_c0/mdiff(17, 5,  18, 16, 3,  8,  11)), 2) ),    // c11
	                       ( min((mdiff_c0/mdiff(13, 15, 7,  14, 6,  8,  12)), 2) ) };  // c12

	weights[4]   = (max(max((weights[8]  + weights[9])/4,  weights[4]), 0.25) + weights[4])/2;
	weights[5]   = (max(max((weights[8]  + weights[10])/4, weights[5]), 0.25) + weights[5])/2;
	weights[6]   = (max(max((weights[9]  + weights[11])/4, weights[6]), 0.25) + weights[6])/2;
	weights[7]   = (max(max((weights[10] + weights[11])/4, weights[7]), 0.25) + weights[7])/2;

	// Calculate the negative part of the laplace kernel and the low threshold weight
	float lowthsum    = 0;
	float weightsum   = 0;
	float neg_laplace = 0;

	int order[12] = { 2, 4, 5, 7, 1, 3, 6, 8, 9, 10, 11, 12 };

	[unroll]
	for (int pix = 0; pix < 12; ++pix)
	{
		float x       = saturate((c[order[pix]].w - w_offset - 0.01)/0.12);
		float lowth   = x*x*(2.99 - 2*x) + 0.01;

		neg_laplace  += pow(luma[order[pix]], 2.0)*(weights[pix]*lowth);
		weightsum    += weights[pix]*lowth;
		lowthsum     += lowth;
	}

	neg_laplace = pow((neg_laplace/weightsum), (1.0/2.0));

	// Compute sharpening magnitude function
	float c_edge = abs(c[0].w - w_offset);

	float sharpen_val = (lowthsum/12)*(curve_height/(curveslope*pow(c_edge, 3.5) + 0.5));

	// Calculate sharpening diff and scale
	float sharpdiff = (c0_Y - neg_laplace)*(sharpen_val*0.8 + 0.01);

	// Calculate local near min & max, partial cocktail sort (No branching!)
	[unroll]
	for (int i = 0; i < 3; ++i)
	{
		for (int i1 = 1+i; i1 < 25-i; ++i1)
		{
			float temp = luma[i1-1];
			luma[i1-1] = min(luma[i1-1], luma[i1]);
			luma[i1]   = max(temp, luma[i1]);
		}

		for (int i2 = 23-i; i2 > i; --i2)
		{
			float temp = luma[i2-1];
			luma[i2-1] = min(luma[i2-1], luma[i2]);
			luma[i2]   = max(temp, luma[i2]);
		}
	}

	float nmax = max(((luma[22] + luma[23]*2 + luma[24])/4), c0_Y);
	float nmin = min(((luma[0]  + luma[1]*2  + luma[2])/4),  c0_Y);

	// Calculate tanh scale factor, pos/neg
	float nmax_scale = min(((nmax - c0_Y) + L_overshoot), max_scale_lim);
	float nmin_scale = min(((c0_Y - nmin) + D_overshoot), max_scale_lim);

	// Soft limit sharpening with tanh, lerp to control maximum compression
	sharpdiff = lerp(  (soft_lim(max(sharpdiff, 0), nmax_scale)), max(sharpdiff, 0), s[0] )
	          + lerp( -(soft_lim(min(sharpdiff, 0), nmin_scale)), min(sharpdiff, 0), s[1] );

	/*if (video_level_out == true)
	{
		[flatten]
		if (sharpdiff > 0) { return float4( orig.rgb + (minim_satloss - c[0].rgb), 1.0 ); }

		else { return float4( (orig.rgb + sharpdiff), 1.0 ); }
	}*/

	// Normal path
	[flatten]
	if (sharpdiff > 0) { return float4( minim_satloss, 1.0 ); }

	else { return float4( (c[0].rgb + sharpdiff), 1.0 ); }
}

technique AdaptiveSharpen_Tech <bool enabled = RFX_Start_Enabled; int toggle = AdaptiveSharpen_ToggleKey; >
{
	pass AdaptiveSharpenPass1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = AdaptiveSharpenP0;
		RenderTarget = edgeTex;
	}
	
	pass AdaptiveSharpenPass2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = AdaptiveSharpenP1;
	}
}

#undef w_offset
#undef get1
#undef b_diff
#undef minim_satloss
#undef soft_if
#undef soft_lim
#undef get2
#undef sat
#undef max4
#undef CtL
#undef mdiff

#endif

#include CFX_SETTINGS_UNDEF
NAMESPACE_LEAVE()
