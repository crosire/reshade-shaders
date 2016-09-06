/**
 * Copyright © 2016 Wilham A. Putro (thewlhm15@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. As clarification, there
 * is no requirement that the copyright notice and permission be included in
 * binary distributions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE. 
 *------------------------------------------------------------------------------
 *                       FireFX Shader File by WLHM15
 *                        For ReShade 3.0 by Crosire 
 *------------------------------------------------------------------------------
 *                          High Quality Bloom 1.1a
 *------------------------------------------------------------------------------
 * TODO : Get better post process, implement lensdirt.
 */

uniform float fBloomThreshold <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Bloom Threshold. Pixels darker than this value won't cast bloom";
> = 0.1;

uniform float fThresholdBoost <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 5.0;
	ui_tooltip = "Control the threshold visibility.";
> = 0.1;  

uniform float fBloomAmount <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Bloom Amount, how bright the bloom's exposure will be.";
> = 1.2;  

uniform float fBloomContrast <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Bloom Contrast, higher values increase strong bloom and decrease weak bloom.";
> = 1.1;

uniform float fBloomGamma <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Bloom Gamma, higher the values more bloom will be damped in dark areas";
> = 1.0;    

uniform float fBloomSaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Bloom Saturation, control the bloom color intensity";
> = 0.1;

uniform float3 fBloomTint <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Bloom Tint, RGB Color tinting the bloom";
> = float3(0.7,0.8,1.0);    

uniform int iBloomBlendMode <
	ui_type = "combo";
	ui_items = "Linear Add\0Screen Add\0Screen/Lighten/Opacity\0Lighten\0";
	ui_tooltip = "Bloom Blend Mode";
> = 2;  

uniform bool bUseLensdirt <
	ui_tooltip = "Use Lensdirt";
> = 0;

uniform float fLensdirtAmount <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Lensdirt Intensity, the lensdirt intensity on bloomy area";
> = 1.1;

uniform float fLensdirtSaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Lensdirt Saturation, control the bloom color intensity";
> = 1.1;

uniform float3 fLensdirtTint <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 8.0;
	ui_tooltip = "Lensdirt Tint, RGB Color tinting the bloom";
> = float3(1.1,1.1,1.0);    

uniform int iLensdirtBlendMode <
	ui_type = "combo";
	ui_items = "Linear Add\0Screen Add\0Screen/Lighten/Opacity\0Lighten\0";
	ui_tooltip = "Lensdirt Blend Mode";
> = 2;  

/* Jangan ubah apapun dibawah garis ini, kecuali kau tau apa yang kau lakukan! */
#include "ReShade.fxh"
static const float3 lumaCoeff = float3(0.2126f,0.7152f,0.0722f);

/////////////////////////////////////////////////////////////////////////////////////
texture tekThresh {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};
texture tekKosongA {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};
texture tekKosongB {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};
////////////////////////////////////////////////////////////////////////////////////////////
texture tekSinarA {Width = BUFFER_WIDTH/16; Height = BUFFER_HEIGHT/16; Format = RGBA16F;};
texture tekSinarB {Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; Format = RGBA16F;};
texture tekSinarC {Width = BUFFER_WIDTH/64; Height = BUFFER_HEIGHT/64; Format = RGBA16F;};
texture tekSinarD {Width = BUFFER_WIDTH/128; Height = BUFFER_HEIGHT/128; Format = RGBA16F;};
texture tekSinarE {Width = BUFFER_WIDTH/256; Height = BUFFER_HEIGHT/256; Format = RGBA16F;};
texture tekSinarF {Width = BUFFER_WIDTH/512; Height = BUFFER_HEIGHT/512; Format = RGBA16F;};
texture tekDebu <source = "debu.png";> {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};

//sampler
sampler samplerThre {Texture = tekThresh;};
sampler samplerKosA {Texture = tekKosongA;};
sampler samplerKosB {Texture = tekKosongB;};
////////////////////////////////////////////
sampler samplerSinarA {Texture = tekSinarA;};
sampler samplerSinarB {Texture = tekSinarB;};
sampler samplerSinarC {Texture = tekSinarC;};
sampler samplerSinarD {Texture = tekSinarD;};
sampler samplerSinarE {Texture = tekSinarE;};
sampler samplerSinarF {Texture = tekSinarF;};
sampler samplerDebu {Texture = tekDebu;};

//pembantu
float4 Kotakblur(sampler tekstur, float2 koord, float buram)
{
	float4 blurcolor = 0.0;

	float weights[3] = {1.0, 0.75, 0.5};
	for (float x = -2; x <= 2; x++)
	{
		for (float y = -2; y <= 2; y++)
		{
			float2 offset = float2(x, y);
			float offsetweight = weights[abs(x)] * weights[abs(y)];
			blurcolor.rgb += tex2Dlod(tekstur, float4(koord + offset.xy * ReShade::PixelSize * buram, 0, 0)).rgb * offsetweight;
			blurcolor.a += offsetweight;
		}
	}
	
	return float4(blurcolor.rgb / blurcolor.a, 1.0);
	
}

//pixelshader
void Initialization(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 warna : SV_Target)
{
	warna = saturate(tex2D(ReShade::BackBuffer, texcoord.xy) - fBloomThreshold) * fThresholdBoost;
}

///////////////////
void SinarThreshold(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 warna : SV_Target)
{
	warna = Kotakblur(samplerThre, texcoord.xy, 16);
}

//Downsample Sinar
void SinarDownA(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarA, texcoord.xy, 32);
}

void SinarDownB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarB, texcoord.xy, 64);
}

void SinarDownC(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarC, texcoord.xy, 128);
}

void SinarDownD(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarD, texcoord.xy, 256);
}

void SinarDownE(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarE, texcoord.xy, 512);
}

//Upsample Sinar
void SinarUpF(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarF, texcoord.xy, 512);
}

void SinarUpE(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarE, texcoord.xy, 256) + tex2D(samplerKosA, texcoord.xy);
}

void SinarUpD(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarD, texcoord.xy, 128) + tex2D(samplerKosB, texcoord.xy);
}

void SinarUpC(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarC, texcoord.xy, 64) + tex2D(samplerKosA, texcoord.xy);
}

void SinarUpB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarB, texcoord.xy, 32) + tex2D(samplerKosB, texcoord.xy);
}

void SinarUpA(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 sinar : SV_Target)
{	
	sinar = Kotakblur(samplerSinarA, texcoord.xy, 16) + tex2D(samplerKosA, texcoord.xy);
}

//Sinar Post Processing
void SinarPostProcess(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 warna : SV_Target)
{	
	warna = tex2D(ReShade::BackBuffer, texcoord.xy);
	float4 sinar = tex2D(samplerKosB, texcoord.xy);
	
	float sLuma = dot(sinar.rgb, lumaCoeff) * fBloomAmount;
	float3 sNSinar = normalize(sinar.rgb);
	sNSinar.rgb = pow(abs(sNSinar.rgb), 1.0 * fBloomSaturation);
	
	float sNLuma = dot(sNSinar.rgb, lumaCoeff);
	sinar.rgb = sNSinar.rgb * sLuma / sNLuma;
	sinar.rgb = pow(abs(sinar.rgb), fBloomGamma);
	sinar.rgb = ((sinar.rgb - 0.5) * max(fBloomContrast, 0)) + 0.5;
	
	sinar.rgb *= fBloomTint;
	
	if(iBloomBlendMode == 0)
		warna.rgb = warna.rgb + sinar.rgb;
	else if(iBloomBlendMode == 1)
		warna.rgb = 1-(1-warna.rgb) * (1-sinar.rgb);
	else if(iBloomBlendMode == 2)
		warna.rgb = max(0.0f,max(warna.rgb,lerp(warna.rgb,(1.0f - (1.0f - saturate(sinar.rgb)) *(1.0f - saturate(sinar.rgb * 1.0))),1.0)));
	else if(iBloomBlendMode == 3)
		warna.rgb = max(warna.rgb, sinar.rgb);
	
	if(bUseLensdirt)
	{
		float3 debu = tex2D(samplerDebu, texcoord.xy).rgb;
		float3 lensdirt = debu.rgb * sLuma * fLensdirtAmount * fLensdirtTint;
	
		lensdirt = lerp(dot(lensdirt.rgb, lumaCoeff), lensdirt.rgb, fLensdirtSaturation);

		if(iLensdirtBlendMode == 0)
			warna.rgb = warna.rgb + lensdirt.rgb;
		else if(iLensdirtBlendMode == 1)
			warna.rgb = 1-(1-warna.rgb)*(1-lensdirt.rgb);
		else if(iLensdirtBlendMode == 2)
			warna.rgb = max(0.0f,max(warna.rgb,lerp(warna.rgb,(1.0f - (1.0f - saturate(lensdirt.rgb)) *(1.0f - saturate(lensdirt.rgb * 1.0))),1.0)));
		else if(iLensdirtBlendMode == 3)
			warna.rgb = max(warna.rgb, lensdirt.rgb);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////
//teknik
technique HighQualityBloom
{
	pass TheInitialization
	{
		VertexShader = PostProcessVS;
		PixelShader = Initialization;
		RenderTarget = tekThresh;
	}
	
	pass TheThreshold
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarThreshold;
		RenderTarget = tekSinarA;
	}
	
	//Downsample Sinar
	pass DownA
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarDownA;
		RenderTarget = tekSinarB;
	}
	
	pass DownB
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarDownB;
		RenderTarget = tekSinarC;
	}
	
	pass DownC
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarDownC;
		RenderTarget = tekSinarD;
	}
	
	pass DownD
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarDownD;
		RenderTarget = tekSinarE;
	}
	
	pass DownE
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarDownE;
		RenderTarget = tekSinarF;
	}
	
	//Upsample Sinar
	pass UpF
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarUpF;
		RenderTarget = tekKosongA;
	}
	
	pass UpE
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarUpE;
	
	RenderTarget = tekKosongB;
	}
	
	pass UpD
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarUpD;
		RenderTarget = tekKosongA;
	}
	
	pass UpC
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarUpC;
		RenderTarget = tekKosongB;
	}
	
	pass UpB
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarUpB;
		RenderTarget = tekKosongA;
	}
	
	pass UpA
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarUpA;
		RenderTarget = tekKosongB;
	}
	
	//Sinar Post Processing
	pass ThePost
	{
		VertexShader = PostProcessVS;
		PixelShader = SinarPostProcess;
	}
}

