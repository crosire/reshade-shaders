#include "Common.fx"

#ifndef RFX_duplicate
#include Ganossa_SETTINGS_DEF
#endif

#if USE_AMBIENT_LIGHT

#if AL_Adaptation
#include "BrightDetect.fx"
#endif

/**
 * Copyright (C) 2015 Ganossa (mediehawk@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software with restriction, including without limitation the rights to
 * use and/or sell copies of the Software, and to permit persons to whom the Software 
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and below) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "Software"), to deal in the Software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the Software, and subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

namespace Ganossa
{

uniform float2 AL_t < source = "pingpong"; min = 0.0f; max = 6.28f; step = float2(0.1f, 0.2f); >;

#define GEMFX_PIXEL_SIZE float2(1.0f/(BUFFER_WIDTH/16.0f),1.0f/(BUFFER_HEIGHT/16.0f))

texture2D alInTex { Width = BUFFER_WIDTH/16; Height = BUFFER_HEIGHT/16; Format = RGBA32F; };
texture2D alOutTex { Width = BUFFER_WIDTH/16; Height = BUFFER_HEIGHT/16; Format = RGBA32F; };
texture dirtTex < source = "ReShade/Shaders/Ganossa/Textures/dirt.png"; > { Width = 1920; Height = 1080; MipLevels = 1; Format = RGBA8; };

texture dirtOVRTex < source = "ReShade/Shaders/Ganossa/Textures/dirtOVR.png"; > { Width = 2400; Height = 1350; MipLevels = 1; Format = RGBA8; };
texture dirtOVBTex < source = "ReShade/Shaders/Ganossa/Textures/dirtOVB.png"; > { Width = 2400; Height = 1348; MipLevels = 1; Format = RGBA8; };
texture lensDBTex < source = "ReShade/Shaders/Ganossa/Textures/lensDB.png"; > { Width = 1920; Height = 1080; MipLevels = 1; Format = RGBA8; };
texture lensDB2Tex < source = "ReShade/Shaders/Ganossa/Textures/lensDB2.png"; > { Width = 1024; Height = 576; MipLevels = 1; Format = RGBA8; };
texture lensDOVTex < source = "ReShade/Shaders/Ganossa/Textures/lensDOV.png"; > { Width = 1920; Height = 1080; MipLevels = 1; Format = RGBA8; };
texture lensDUVTex < source = "ReShade/Shaders/Ganossa/Textures/lensDUV.png"; > { Width = 1920; Height = 1080; MipLevels = 1; Format = RGBA8; };

sampler2D alInColor { Texture = alInTex; };
sampler2D alOutColor { Texture = alOutTex; };
sampler dirtSampler { Texture = dirtTex; };
sampler dirtOVRSampler { Texture = dirtOVRTex; };
sampler dirtOVBSampler { Texture = dirtOVBTex; };
sampler lensDBSampler { Texture = lensDBTex; };
sampler lensDB2Sampler { Texture = lensDB2Tex; };
sampler lensDOVSampler { Texture = lensDOVTex; };
sampler lensDUVSampler { Texture = lensDUVTex; };

void PS_AL_DetectHigh(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 highR : SV_Target0)
{
	float4 x = tex2D(ReShade::OriginalColor, texcoord);

	x = float4 (x.rgb * pow (abs (max (x.r, max (x.g, x.b))), 2.0), 1.0f);

	float base = (x.r + x.g + x.b); base /= 3;
	
	float nR = (x.r * 2) - base;
	float nG = (x.g * 2) - base;
	float nB = (x.b * 2) - base;

	[flatten]if (nR < 0) { nG += nR/2; nB += nR/2; nR = 0; }
	[flatten]if (nG < 0) { nB += nG/2; [flatten]if (nR > -nG/2) nR += nG/2; else nR = 0; nG = 0; }
	[flatten]if (nB < 0) { [flatten]if (nR > -nB/2) nR += nB/2; else nR = 0; [flatten]if (nG > -nB/2) nG += nB/2; else nG = 0; nB = 0; }

	[flatten]if (nR > 1) { nG += (nR-1)/2; nB += (nR-1)/2; nR = 1; }
	[flatten]if (nG > 1) { nB += (nG-1)/2; [flatten]if (nR+(nG-1) < 1) nR += (nG-1)/2; else nR = 1; nG = 1; }
	[flatten]if (nB > 1) { [flatten]if (nR+(nB-1) < 1) nR += (nB-1)/2; else nR = 1; [flatten]if (nG+(nB-1) < 1) nG += (nB-1)/2; else nG = 1; nB = 1; }

	x.r = nR; x.g = nG; x.b = nB;

	highR = x;
}

void PS_AL_HGB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hgbR : SV_Target0)
{
	static const float sampleOffsets[5] = { 0.0, 2.4347826, 4.3478260, 6.2608695, 8.1739130 };
	static const float sampleWeights[5] = { 0.16818994, 0.27276957, 0.111690125, 0.024067905, 0.0021112196 };

	float4 hgb = tex2D(alInColor, texcoord) * sampleWeights[0];
	hgb = float4(max(hgb.rgb - alThreshold, 0.0), hgb.a);
	float step = 1.08 + (AL_t.x / 100)* 0.02;

	[flatten]if ((texcoord.x + sampleOffsets[1] * GEMFX_PIXEL_SIZE.x) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[1] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[1] * step;
	[flatten]if ((texcoord.x - sampleOffsets[1] * GEMFX_PIXEL_SIZE.x) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[1] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[1] * step;

	[flatten]if ((texcoord.x + sampleOffsets[2] * GEMFX_PIXEL_SIZE.x) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[2] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[2] * step;
	[flatten]if ((texcoord.x - sampleOffsets[2] * GEMFX_PIXEL_SIZE.x) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[2] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[2] * step;

	[flatten]if ((texcoord.x + sampleOffsets[3] * GEMFX_PIXEL_SIZE.x) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[3] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[3] * step;
	[flatten]if ((texcoord.x - sampleOffsets[3] * GEMFX_PIXEL_SIZE.x) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[3] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[3] * step;

	[flatten]if ((texcoord.x + sampleOffsets[4] * GEMFX_PIXEL_SIZE.x) < 1.05) hgb += tex2D(alInColor, texcoord + float2(sampleOffsets[4] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[4] * step;
	[flatten]if ((texcoord.x - sampleOffsets[4] * GEMFX_PIXEL_SIZE.x) > -0.05) hgb += tex2D(alInColor, texcoord - float2(sampleOffsets[4] * GEMFX_PIXEL_SIZE.x, 0.0)) * sampleWeights[4] * step;

	hgbR = hgb;
}

void PS_AL_VGB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 vgbR : SV_Target0)
{
	static const float sampleOffsets[5] = { 0.0, 2.4347826, 4.3478260, 6.2608695, 8.1739130 };
	static const float sampleWeights[5] = { 0.16818994, 0.27276957, 0.111690125, 0.024067905, 0.0021112196 };

	float4 vgb = tex2D(alOutColor, texcoord) * sampleWeights[0];
	vgb = float4(max(vgb.rgb - alThreshold, 0.0), vgb.a);
	float step = 1.08 + (AL_t.x / 100)* 0.02;
	
	[flatten]if ((texcoord.y + sampleOffsets[1] * GEMFX_PIXEL_SIZE.y) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[1] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[1] * step;
	[flatten]if ((texcoord.y - sampleOffsets[1] * GEMFX_PIXEL_SIZE.y) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[1] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[1] * step;
	
	[flatten]if ((texcoord.y + sampleOffsets[2] * GEMFX_PIXEL_SIZE.y) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[2] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[2] * step;
	[flatten]if ((texcoord.y - sampleOffsets[2] * GEMFX_PIXEL_SIZE.y) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[2] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[2] * step;

	[flatten]if ((texcoord.y + sampleOffsets[3] * GEMFX_PIXEL_SIZE.y) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[3] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[3] * step;
	[flatten]if ((texcoord.y - sampleOffsets[3] * GEMFX_PIXEL_SIZE.y) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[3] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[3] * step;

	[flatten]if ((texcoord.y + sampleOffsets[4] * GEMFX_PIXEL_SIZE.y) < 1.05) vgb += tex2D(alOutColor, texcoord + float2(0.0, sampleOffsets[4] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[4] * step;
	[flatten]if ((texcoord.y - sampleOffsets[4] * GEMFX_PIXEL_SIZE.y) > -0.05) vgb += tex2D(alOutColor, texcoord - float2(0.0, sampleOffsets[4] * GEMFX_PIXEL_SIZE.y)) * sampleWeights[4] * step;

	vgbR = vgb;
}

float4 PS_AL_Magic(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 base = tex2D(ReShade::BackBuffer, texcoord);
	float4 high = tex2D(alInColor, texcoord);

#if AL_Adaptation
//DetectLow	
	float4 detectLow = tex2D(detectLowColor, 0.5)/4.215;
	float low = sqrt(0.241*detectLow.r*detectLow.r+0.691*detectLow.g*detectLow.g+0.068*detectLow.b*detectLow.b);
//.DetectLow

	low = pow(low*1.25f,2);
	float adapt = low*(low+1.0f)*alAdapt*alInt*5.0f;

#if alDebug
	float mod = (texcoord.x*1000.0f)%1.001f;
	//mod = abs(mod - texcoord.x/4.0f);

	if (texcoord.y < 0.01f)
	if (texcoord.x < low*10f && mod < 0.3f) return float4(1f,0.5f,0.3f,0f);

	if (texcoord.y > 0.01f && texcoord.y < 0.02f)
	if (texcoord.x < adapt/(alInt*1.5) && mod < 0.3f) return float4(0.2f,1f,0.5f,0f);
#endif
#endif


	high = min(0.0325f,high)*max(0.0f,(1.15f - 0));

	float4 highOrig = high;

	float xFlip = 1.0f - texcoord.x;
	float yFlip = 1.0f - texcoord.y;
	float4 highFlipOrig = tex2D(alInColor, float2(xFlip,yFlip));
	
	highFlipOrig = min(0.03f,highFlipOrig)*max(0.0f,(1.15f - 0));

	float4 highFlip = highFlipOrig;
	float4 highLensSrc = high;

#if AL_Dirt
		float4 dirt = tex2D(dirtSampler, texcoord);
		float4 dirtOVR = tex2D(dirtOVRSampler, texcoord);
		float4 dirtOVB = tex2D(dirtOVBSampler, texcoord);

		float maxhigh = max(high.r, max(high.g, high.b));
		float threshDiff = maxhigh - 3.2f;
		[flatten]if (threshDiff > 0) {
			high.r = (high.r / maxhigh)*3.2f;
			high.g = (high.g / maxhigh)*3.2f;
			high.b = (high.b / maxhigh)*3.2f;
		}
#if AL_DirtTex 
		float4 highDirt = highOrig*dirt*alDirtInt;
#else
		float4 highDirt = highOrig*high*alDirtInt;
#endif
#if AL_Vibrance 
			highDirt *= 1.0f+0.5f*sin(AL_t.x);
#endif
		float highMix = highOrig.r + highOrig.g + highOrig.b;
		float red = highOrig.r/highMix;
		float green = highOrig.g/highMix;
		float blue = highOrig.b/highMix;
		highOrig = highOrig + highDirt;
#if AL_Adaptive == 2
			high = high + high*dirtOVR*alDirtOVInt*green;
			high = high + highDirt;
			high = high + highOrig*dirtOVB*alDirtOVInt*blue;
			high = high + highOrig*dirtOVR*alDirtOVInt*red;
#elif AL_Adaptive == 1
			high = high + highDirt;
			high = high + highOrig*dirtOVB*alDirtOVInt;
#else
			high = high + highDirt;
			high = high + highOrig*dirtOVR*alDirtOVInt;
#endif
		highLensSrc = high*85f*pow(1.25f-(abs(texcoord.x-0.5f)+abs(texcoord.y-0.5f)),2);
#endif
	#define GEMFX_lensb1 (1.8f * alLensThresh)
	float origBright = max(highLensSrc.r,max(highLensSrc.g,highLensSrc.b));//sqrt(0.241*base.r*base.r+0.691*base.g*base.g+0.068*base.b*base.b);
	float maxOrig = max(GEMFX_lensb1 - pow(origBright*(0.5f-abs(texcoord.x-0.5f)),4),0.0f);
	float smartWeight = maxOrig*max(abs(xFlip-0.5f), 0.3f*abs(yFlip-0.5f))*(2.2-1.2*(abs(xFlip-0.5f)))*alLensInt;
	smartWeight = min(0.85f,max(0,smartWeight
#if AL_Adaptation
-adapt
#endif
));

	float4 lensDB = tex2D(lensDBSampler, texcoord);
	float4 lensDB2 = tex2D(lensDB2Sampler, texcoord);
	float4 lensDOV = tex2D(lensDOVSampler, texcoord);
	float4 lensDUV = tex2D(lensDUVSampler, texcoord);

	float4 highLens = highFlip*lensDB*0.7f*smartWeight;

#if AL_Lens
		high = high + highLens;

		highLens = highFlipOrig*lensDUV*1.15f*smartWeight;
		highFlipOrig = highFlipOrig + highLens;
		high = high + highLens;

		highLens = highFlipOrig*lensDB2*0.7f*smartWeight;
		highFlipOrig = highFlipOrig + highLens;
		high = high + highLens;

		highLens = highFlipOrig*lensDOV*1.15f*smartWeight/2f + highFlipOrig*smartWeight/2f;
		highFlipOrig = highFlipOrig + highLens;
		high = high + highLens;
#endif

	float dither = 0.15 * (1.0 / (pow(2, 10.0) - 1.0));
	dither = lerp(2.0 * dither, -2.0 * dither, frac(dot(texcoord, ReShade::ScreenSize * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25));

#if AL_Adaptation
	base.xyz *= max(0.0f,(1.0f - adapt*0.75f*alAdaptBaseMult*pow((1.0f-(base.x+base.y+base.z)/3),alAdaptBaseBlackLvL)));
#define GEMFX_alb1 max(0.0f,(alInt-adapt)*0.85f)
	float4 highSampleMix = (1.0 - ((1.0 - base) * (1.0 - high *1.0)))+dither;
	float4 baseSample = lerp(base, highSampleMix, max(0.0f,alInt-adapt));
#else
#define GEMFX_alb1 max(0.0f,alInt*0.85f)
	float4 highSampleMix = (1.0 - ((1.0 - base) * (1.0 - high *1.0)))+dither;
	float4 baseSample = lerp(base, highSampleMix, alInt);
#endif
	float baseSampleMix = baseSample.r + baseSample.g + baseSample.b;
	[flatten]if (baseSampleMix>0.008)
		return baseSample;
	else return lerp(base, highSampleMix, GEMFX_alb1*baseSampleMix);
}

technique AmbientLight_Tech <bool enabled = 
#if (AmbientLight_TimeOut > 0)
1; int toggle = AmbientLight_ToggleKey; timeout = AmbientLight_TimeOut; >
#else
RESHADE_START_ENABLED; int toggle = AmbientLight_ToggleKey; >
#endif
{
	pass AL_DetectHigh
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_DetectHigh;
		RenderTarget = alInTex;
	}

	pass AL_H1
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V1
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H3
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V3
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H5
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V5
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H6
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V6
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H7
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V7
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H8
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V8
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H9
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V9
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H10
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V10
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H11
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V11
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_H12
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_HGB;
		RenderTarget = alOutTex;
	}

	pass AL_V12
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_VGB;
		RenderTarget = alInTex;
	}

	pass AL_Magic
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_Magic;
	}
}

}

#endif

#ifndef RFX_duplicate
#include Ganossa_SETTINGS_UNDEF
#endif
