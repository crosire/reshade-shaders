NAMESPACE_ENTER(Ioxa)

#include Ioxa_SETTINGS_DEF

#if USE_GAUSS

#if USE_Blur == 1
#define Use_GaussianBlur 1
#endif
#if USE_Sharpening == 1 
#define Use_Unsharpmask 1
#endif
#if USE_Bloom == 1
#define Use_GaussianBloom 1 
#endif

 /**
 * Copyright (C) 2012 Jorge Jimenez (jorge@iryoku.com). All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
 * IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are 
 * those of the authors and should not be interpreted as representing official
 * policies, either expressed or implied, of the copyright holders.
 */

/* This is my attempt to port the the GAUSSIAN shader by Boulotaur2024 to ReShade.
   Some settings from the original are missing and I have added some other settings to achieve certain looks.
   More info can be found at 
   http://reshade.me/forum/shader-presentation/27-gaussian-blur-bloom-unsharpmask */ 

#define CoefLuma_G            float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
#define sharp_strength_luma_G (CoefLuma_G * SharpStrength + 0.2)
#define sharp_clampG        0.035

uniform int random < source = "random"; min = 0; max = 10; >;

#if Use_GaussianBlur == 0 && Use_Unsharpmask == 0 
#undef GaussTexScale 
#endif 

#if Use_GaussianBloom == 0 
#undef BloomTexScale 
#endif

#if GaussTexScale == 1 
#define txsize 2 
#elif GaussTexScale == 2 
#define txsize 4 
#else 
#define txsize 1 
#endif

#if GaussSigma == 2
#define Gpx_size (RFX_PixelSize*2)
#elif GaussSigma == 3
#define Gpx_size (RFX_PixelSize*3)
#elif GaussSigma == 4
#define Gpx_size (RFX_PixelSize*4)
#else
#define Gpx_size (RFX_PixelSize)
#endif

texture GBlurTex2Dping{ Width = BUFFER_WIDTH/txsize; Height = BUFFER_HEIGHT/txsize; Format = RGBA8; };
sampler2D GBlurSamplerPing { Texture = GBlurTex2Dping; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Clamp; SRGBTexture = FALSE;};
#if GaussTexScale != 0
texture GBlurTex2Dpong{ Width = BUFFER_WIDTH/txsize; Height = BUFFER_HEIGHT/txsize; Format = RGBA8; };
sampler2D GBlurSamplerPong { Texture = GBlurTex2Dpong; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Clamp; SRGBTexture = FALSE;};
#endif

#if BloomSigma == 2
#define Bpx_size (RFX_PixelSize*2)
#elif BloomSigma == 3
#define Bpx_size (RFX_PixelSize*3)
#elif BloomSigma == 4
#define Bpx_size (RFX_PixelSize*4)
#else
#define Bpx_size (RFX_PixelSize)
#endif

#if BloomTexScale != 0
 
#if BloomTexScale == 1 
	#define Btxsize 0.5 
#elif BloomTexScale == 2 
	#define Btxsize 0.25 
#else 
	#define Btxsize 1 
#endif

texture BBlurTex2Dping{ Width = BUFFER_WIDTH*Btxsize; Height = BUFFER_HEIGHT*Btxsize; Format = RGBA8; };
texture BBlurTex2Dpong{ Width = BUFFER_WIDTH*Btxsize; Height = BUFFER_HEIGHT*Btxsize; Format = RGBA8; };
sampler2D BBlurSamplerPing { Texture = BBlurTex2Dping; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Clamp; SRGBTexture = FALSE;};
sampler2D BBlurSamplerPong { Texture = BBlurTex2Dpong; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Clamp; SRGBTexture = FALSE;};
#endif 

float4 GOriginalPixel(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float4 color = tex2D(RFX_backbufferColor, texcoord);
	return saturate(color);
}

float4 HGaussianBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if GaussTexScale != 0 
	float4 color = tex2D(GBlurSamplerPing, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(GBlurSamplerPing, texcoord + float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i];
		color += tex2D(GBlurSamplerPing, texcoord - float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i]; 
	}
	#else
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i];
		color += tex2D(RFX_backbufferColor, texcoord - float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i]; 
	}
	#endif
	return color;
}

float4 VGaussianBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if GaussTexScale != 0
	float4 color = tex2D(GBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(GBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
		color += tex2D(GBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
	}
	#else
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
	}
	#endif
	return color;
}

float4 V2GaussianBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if GaussTexScale != 0
	float4 color = tex2D(GBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(GBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
		color += tex2D(GBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
	}
	#else
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
	}
	#endif
	return color;
}

float4 H2GaussianBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if GaussTexScale != 0
	float4 color = tex2D(GBlurSamplerPing, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(GBlurSamplerPing, texcoord + float2(sampleOffsets[i] * Gpx_size.x, 0.0)) * sampleWeights[i];
		color += tex2D(GBlurSamplerPing, texcoord - float2(sampleOffsets[i] * Gpx_size.x, 0.0)) * sampleWeights[i]; 
	}
	#else 
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(sampleOffsets[i] * Gpx_size.x, 0.0)) * sampleWeights[i];
		color += tex2D(RFX_backbufferColor, texcoord - float2(sampleOffsets[i] * Gpx_size.x, 0.0)) * sampleWeights[i]; 
	}
	#endif
	return color;
}

float4 GaussianBlurFinalPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if GaussTexScale >= 1
	#if GaussQuality >= 1
	float4 color = tex2D(GBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(GBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
		color += tex2D(GBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(RFX_backbufferColor, texcoord); //Original Image
	#else
	float4 color = tex2D(GBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(GBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
		color += tex2D(GBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(RFX_backbufferColor, texcoord); //Original Image
	#endif
	#else
	#if GaussQuality >= 1
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * Gpx_size.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(GBlurSamplerPing, texcoord); //Original Image
	#else 
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(GBlurSamplerPing, texcoord); //Original Image
	#endif 
	#endif
	
	#if Use_Unsharpmask == 1 // Sharpening
	float3 sharp;
		sharp = orig.rgb - color.rgb;
		float sharp_luma1 = dot(sharp, sharp_strength_luma_G);
		sharp_luma1 = clamp(sharp_luma1, -sharp_clampG, sharp_clampG);
		orig = orig + sharp_luma1;
	#endif

	#if Use_GaussianBlur == 1
		orig = lerp(orig, color, BlurStrength);
	#endif

	return saturate(orig);
}

#if Use_GaussianBloom == 1
float3 FilmicTonemap(float3 x) {
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;
    float W = 11.2;
    return ((x*(A*x+C*B)+D*E) / (x*(A*x+B)+D*F))- E / F;
}

float3 DoToneMap(float3 color) {
	/*
    #if TONEMAP_OPERATOR == 1 //TONEMAP_LINEAR
    return exposure * color;
    #elif TONEMAP_OPERATOR == 2 //TONEMAP_EXPONENTIAL
    color = 1.0 - exp2(-exposure * color);
    return color;
    #elif TONEMAP_OPERATOR == 3 //TONEMAP_EXPONENTIAL_HSV
    color = rgb2hsv(color);
    color.b = 1.0 - exp2(-exposure * color.b);
    color = hsv2rgb(color);
    return color;
    #elif TONEMAP_OPERATOR == 5 //TONEMAP_REINHARD
    color = xyz2Yxy(rgb2xyz(color));
    float L = color.r;
    L *= exposure;
    float LL = 1 + L / (burnout * burnout);
    float L_d = L * LL / (1 + L);
    color.r = L_d;
    color = xyz2rgb(Yxy2xyz(color));
    return color;
    #else // TONEMAP_FILMIC
	*/
    color = 2.0f * FilmicTonemap(2.00 * color);
    float3 whiteScale = 1.0f / FilmicTonemap(11.2);
    color *= whiteScale;
    return color;
}

float4 GlareDetectionPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	#if BloomTexScale != 0
	float4 color = tex2D( BBlurSamplerPong, texcoord );
	#else
	float4 color = tex2D( RFX_backbufferColor, texcoord );
	#endif
	
	#if GaussBloomWarmth == 1
	color.rgb = lerp(color.rgb,dot(color.rgb, CoefLuma_G),-0.2);
	#else
	color.rgb = lerp(color.rgb,dot(color.rgb, CoefLuma_G),0.5);
	#endif
	
	color.rgb *= float3(BloomRed,BloomGreen,BloomBlue);
	
	color.rgb *= ( 1.0f + ( color.rgb / ( GaussThreshold * GaussThreshold ) ) );
	color.rgb *= 0.1800 / ( 0.051 );
    color.rgb -= 5.0f;

    color.rgb = max( color.rgb, 0.0f );

    color.rgb /= ( GaussExposure*0.1 + color.rgb ); 
	
	color.rgb = DoToneMap(color.rgb);
	
	return color;
}

float4 HBloomBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if BloomTexScale >= 1 
	float4 color = tex2D(BBlurSamplerPing, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(BBlurSamplerPing, texcoord + float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i];
		color += tex2D(BBlurSamplerPing, texcoord - float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i]; 
	}
	#else
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i];
		color += tex2D(RFX_backbufferColor, texcoord - float2(sampleOffsets[i] * RFX_PixelSize.x, 0.0)) * sampleWeights[i]; 
	}
	#endif
	return color;
}

float4 VBloomBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if BloomTexScale != 0
	float4 color = tex2D(BBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(BBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
		color += tex2D(BBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
	}
	#else
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
	}
	#endif
	return color;
}

float4 V2BloomBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if BloomTexScale >= 1
	float4 color = tex2D(BBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(BBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
		color += tex2D(BBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
	}
	#else
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
	}
	#endif
	return color;
}

float4 H2BloomBlurPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
  
	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if BloomTexScale != 0
	float4 color = tex2D(BBlurSamplerPing, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(BBlurSamplerPing, texcoord + float2(sampleOffsets[i] * Bpx_size.x, 0.0)) * sampleWeights[i];
		color += tex2D(BBlurSamplerPing, texcoord - float2(sampleOffsets[i] * Bpx_size.x, 0.0)) * sampleWeights[i]; 
	}
	#else 
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int i = 1; i < 5; ++i) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(sampleOffsets[i] * Bpx_size.x, 0.0)) * sampleWeights[i];
		color += tex2D(RFX_backbufferColor, texcoord - float2(sampleOffsets[i] * Bpx_size.x, 0.0)) * sampleWeights[i]; 
	}
	#endif
	return color;
}

float4 FinalBloomPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float sampleOffsets[5] = { 0.0, 1.4347826, 3.3478260, 5.2608695, 7.1739130 };
	float sampleWeights[5] = { 0.16818994, 0.27276957, 0.11690125, 0.024067905, 0.0021112196 };
	#if BloomTexScale != 0
	#if BloomQuality >= 1
	float4 color = tex2D(BBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(BBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
		color += tex2D(BBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(RFX_backbufferColor, texcoord); //Original Image
	#else 
	float4 color = tex2D(BBlurSamplerPong, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(BBlurSamplerPong, texcoord + float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
		color += tex2D(BBlurSamplerPong, texcoord - float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(RFX_backbufferColor, texcoord); //Original Image
	#endif
	#else
	#if BloomQuality >= 1
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * Bpx_size.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(GBlurSamplerPing, texcoord); //Original Image
	#else
	float4 color = tex2D(RFX_backbufferColor, texcoord) * sampleWeights[0];
	[loop]
	for(int j = 1; j < 5; ++j) {
		color += tex2D(RFX_backbufferColor, texcoord + float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
		color += tex2D(RFX_backbufferColor, texcoord - float2(0.0, sampleOffsets[j] * RFX_PixelSize.y)) * sampleWeights[j];
	}
	float4 orig = tex2D(GBlurSamplerPing, texcoord); //Original Image
	#endif
	#endif
			#define BloomDebug 0
		
		#if (GaussBloomWarmth == 0)
			#if BloomDebug == 1 
			orig = (1.0 - ((1.0 - orig) * (1.0 - (pow(abs(color*2.3),2.5))*0.3)));
			#else
			//orig = lerp(orig, (1.0 - ((1.0 - orig) * (1.0 - (pow(abs(color*2.3),2.5))*0.3))), BloomStrength);
			orig = lerp(orig, (1.0 - ((0.95 - orig) * (1.05 - (pow(abs(color*2.6),2.5))*0.3))), BloomStrength);
			#endif
		#elif (GaussBloomWarmth == 1)
			#if BloomDebug == 1 
			orig = (1.0 - ((1.05 - orig) * (0.95 - (pow(abs(color*2.6),2.5))*0.3)));
			#else
			orig = lerp(orig, (1.0 - ((1.05 - orig) * (0.95 - (pow(abs(color*2.6),2.5))*0.3))), BloomStrength);
			//orig = lerp(orig, (1.0 - ((1.0 - orig) * (1.00 - (pow(abs(color*2.6),2.5))*0.3))), BloomStrength);
			#endif
		#else
			#if BloomDebug == 1 
			orig = (1.0 - ((1.0 - orig) * (1.0 - (color)))), BloomStrength);
			#else
			orig = lerp(orig, (1.0 - ((1.0 - orig) * (1.0 - (color)))), BloomStrength);  // Foggy bloom
			#endif
		#endif 
		
	return saturate(orig);
}
#endif

technique Gaussian_Tech <bool enabled = RFX_Start_Enabled; int toggle = Gaussian_ToggleKey; >
{
#if Use_Unsharpmask == 1 || Use_GaussianBlur == 1
	pass H1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = GOriginalPixel;
		RenderTarget = GBlurTex2Dping;
	}

	pass H1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = HGaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}

#if GaussQuality >= 1
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = VGaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 2
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 3	
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 4
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 5	
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 6	
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 7	
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 8	
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 9
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 10	
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 11	
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussQuality >= 12
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2GaussianBlurPS;
		#if GaussTexScale != 0
		RenderTarget = GBlurTex2Dpong;
		#endif
	}
#endif
	pass VFinal
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = GaussianBlurFinalPS;
	}
#endif
#if Use_GaussianBloom == 1

	pass H1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = GOriginalPixel;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#else
		RenderTarget = GBlurTex2Dping;
		#endif
	}

	pass GD
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = GlareDetectionPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H1Bloom
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = HBloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
		
#if GaussBloomQuality >= 1
	pass V1
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = VBloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 2
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 3
	pass V3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
		
	pass H4
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 4
	pass V4
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}	
	
	pass H5
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 5	
	pass V5
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H6
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 6
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 7	
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 8
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 9
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 10	
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 11	
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif	
#if GaussBloomQuality >= 12
	pass V2
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = V2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dping;
		#endif
	}
	
	pass H3
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = H2BloomBlurPS;
		#if BloomTexScale != 0
		RenderTarget = BBlurTex2Dpong;
		#endif
	}
#endif
	
	pass VFinal
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = FinalBloomPS;
	}
#endif
}

#endif

#include Ioxa_SETTINGS_UNDEF

NAMESPACE_LEAVE()
