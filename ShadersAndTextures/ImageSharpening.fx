/**
  Image sharpening filter from GeForce Experience. Provided by NVIDIA Corporation.
  
  Copyright 2019 Suketu J. Shah. All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted provided
  that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions
       and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
       and the following disclaimer in the documentation and/or other materials provided with the distribution.
    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
       or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "ReShadeUI.fxh"

uniform float g_sldSharpen < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.000; ui_max=1.000;
	ui_label = "Sharpen";
	ui_tooltip = "Increase to sharpen details within the image.";
	ui_step = 0.001;
> = 0.5;

uniform float g_sldDenoise < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.000; ui_max=1.000;
	ui_label = "Ignore Film Grain";
	ui_tooltip = "Increase to limit how intensely film grain within the image gets sharpened.";
	ui_step = 0.001;
> = 0.17;

#include "ReShade.fxh"

float GetLuma(float r, float g, float b)
{
    // Y from JPEG spec
    return 0.299f * r + 0.587f * g + 0.114f * b;
}

float GetLuma(float4 p)
{
    return GetLuma(p.x, p.y, p.z);
}

float Square(float v)
{
    return v * v;
}

// highlight fall-off start (prevents halos and noise in bright areas)
#define kHighBlock 0.65f
// offset reducing sharpening in the shadows
#define kLowBlock (1.0f / 256.0f)
#define kSharpnessMin (-1.0f / 14.0f)
#define kSharpnessMax (-1.0f / 6.5f)
#define kDenoiseMin (0.001f)
#define kDenoiseMax (-0.1f)

void PS_ImageSharpening(in float4 i_pos : SV_POSITION, in float2 i_uv : TEXCOORD, out float4 o_rgba : SV_Target)
{
    float4 x = tex2D(ReShade::BackBuffer, i_uv);

    float4 a = tex2Doffset(ReShade::BackBuffer, i_uv, int2(-1, 0));
    float4 b = tex2Doffset(ReShade::BackBuffer, i_uv, int2(1, 0));
    float4 c = tex2Doffset(ReShade::BackBuffer, i_uv, int2(0, 1));
    float4 d = tex2Doffset(ReShade::BackBuffer, i_uv, int2(0, -1));

    float4 e = tex2Doffset(ReShade::BackBuffer, i_uv, int2(-1, -1));
    float4 f = tex2Doffset(ReShade::BackBuffer, i_uv, int2(1, 1));
    float4 g = tex2Doffset(ReShade::BackBuffer, i_uv, int2(-1, 1));
    float4 h = tex2Doffset(ReShade::BackBuffer, i_uv, int2(1, -1));

    float lx = GetLuma(x);

    float la = GetLuma(a);
    float lb = GetLuma(b);
    float lc = GetLuma(c);
    float ld = GetLuma(d);

    float le = GetLuma(e);
    float lf = GetLuma(f);
    float lg = GetLuma(g);
    float lh = GetLuma(h);

    // cross min/max
    const float ncmin = min(min(le, lf), min(lg, lh));
    const float ncmax = max(max(le, lf), max(lg, lh));

    // plus min/max
    float npmin = min(min(min(la, lb), min(lc, ld)), lx);
    float npmax = max(max(max(la, lb), max(lc, ld)), lx);

    // compute "soft" local dynamic range -- average of 3x3 and plus shape
    float lmin = 0.5f * min(ncmin, npmin) + 0.5f * npmin;
    float lmax = 0.5f * max(ncmax, npmax) + 0.5f * npmax;

    // compute local contrast enhancement kernel
    float lw = lmin / (lmax + kLowBlock);
    float hw = Square(1.0f - Square(max(lmax - kHighBlock, 0.0f) / ((1.0f - kHighBlock))));

    // noise suppression
    // Note: Ensure that the denoiseFactor is in the range of (10, 1000) on the CPU-side prior to launching this shader.
    // For example, you can do so by adding these lines
    //      const float kDenoiseMin = 0.001f;
    //      const float kDenoiseMax = 0.1f;
    //      float kernelDenoise = 1.0f / (kDenoiseMin + (kDenoiseMax - kDenoiseMin) * min(max(denoise, 0.0f), 1.0f));
    // where kernelDenoise is the value to be passed in to this shader (the amount of noise suppression is inversely proportional to this value),
    //       denoise is the value chosen by the user, in the range (0, 1)
	float kernelDenoise = 1.0f / (kDenoiseMin + (kDenoiseMax - kDenoiseMin) * min(max(g_sldDenoise, 0.0f), 1.0f));
    const float nw = Square((lmax - lmin) * kernelDenoise);

    // pick conservative boost
    const float boost = min(min(lw, hw), nw);

    // run variable-sigma 3x3 sharpening convolution
    // Note: Ensure that the sharpenFactor is in the range of (-1.0f/14.0f, -1.0f/6.5f) on the CPU-side prior to launching this shader.
    // For example, you can do so by adding these lines
    //      const float kSharpnessMin = -1.0f / 14.0f;
    //      const float kSharpnessMax = -1.0f / 6.5f;
    //      float kernelSharpness = kSharpnessMin + (kSharpnessMax - kSharpnessMin) * min(max(sharpen, 0.0f), 1.0f);
    // where kernelSharpness is the value to be passed in to this shader,
    //       sharpen is the value chosen by the user, in the range (0, 1)
    float kernelSharpness = kSharpnessMin + (kSharpnessMax - kSharpnessMin) * min(max(g_sldSharpen, 0.0f), 1.0f);
    const float k = boost * kernelSharpness;

    float accum = lx;
    accum += la * k;
    accum += lb * k;
    accum += lc * k;
    accum += ld * k;
    accum += le * (k * 0.5f);
    accum += lf * (k * 0.5f);
    accum += lg * (k * 0.5f);
    accum += lh * (k * 0.5f);

    // normalize (divide the accumulator by the sum of convolution weights)
    accum /= 1.0f + 6.0f * k;

    // accumulator is in linear light space            
    float delta = accum - GetLuma(x);
    x.x += delta;
    x.y += delta;
    x.z += delta;

    o_rgba = x;
}

technique ImageSharpening
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_ImageSharpening;
	}
}
