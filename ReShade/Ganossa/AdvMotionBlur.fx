#include "Common.fx"

#ifndef RFX_duplicate
#include Ganossa_SETTINGS_DEF
#endif

#if USE_ADV_MOTION_BLUR

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
namespace Ganossa_MB
{

texture2D ambCurrBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture2D ambPrevBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
texture2D ambPrevTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler2D ambCurrBlurColor { Texture = ambCurrBlurTex; };
sampler2D ambPrevBlurColor { Texture = ambPrevBlurTex; };
sampler2D ambPrevColor { Texture = ambPrevTex; };

float4 PS_AMBCombine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 prev = tex2D(ambPrevBlurColor, texcoord);
	float4 curr = tex2D(RFX::backbufferColor, texcoord);
	float4 currBlur = tex2D(ambCurrBlurColor, texcoord);
	
	float diff = (abs(currBlur.r - prev.r) + abs(currBlur.g - prev.g) + abs(currBlur.b - prev.b)) / 3;
	diff = min(max(diff - ambPrecision, 0.0f)*ambSmartMult, ambRecall);

#if ambDepth_Check
	float depth = tex2D(RFX::depthTexColor, texcoord).r;

	return lerp(curr, prev, min(ambIntensity+diff*ambSmartInt, 1.0f)/(depth.r+ambDepthRatio));
#endif
	return lerp(curr, prev, min(ambIntensity+diff*ambSmartInt, 1.0f));
}

void PS_AMBCopyPreviousFrame(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 prev : SV_Target0)
{
	prev = tex2D(RFX::backbufferColor, texcoord);
}

void PS_AMBBlur(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 curr : SV_Target0, out float4 prev : SV_Target1)
{
	

	float4 currVal = tex2D(RFX::backbufferColor, texcoord);
	float4 prevVal = tex2D(ambPrevColor, texcoord);

	float weight[11] = { 0.082607, 0.040484, 0.038138, 0.034521, 0.030025, 0.025094, 0.020253, 0.015553, 0.011533, 0.008218, 0.005627 };
	currVal *= weight[0];
	prevVal *= weight[0];

	float ratio = -1.0f;

	float pixelBlur = ambSoftness/max(1.0f,1.0f+(-1.0f)*ratio) * (BUFFER_RCP_HEIGHT); 

	[unroll]
	for (int z = 1; z < 11; z++) //set quality level by user
	{
		currVal += tex2D(RFX::backbufferColor, texcoord + float2(z*pixelBlur, 0)) * weight[z];
		currVal += tex2D(RFX::backbufferColor, texcoord - float2(z*pixelBlur, 0)) * weight[z];
		currVal += tex2D(RFX::backbufferColor, texcoord + float2(0, z*pixelBlur)) * weight[z];
		currVal += tex2D(RFX::backbufferColor, texcoord - float2(0, z*pixelBlur)) * weight[z];
		
		prevVal += tex2D(ambPrevColor, texcoord + float2(z*pixelBlur, 0)) * weight[z];
		prevVal += tex2D(ambPrevColor, texcoord - float2(z*pixelBlur, 0)) * weight[z];
		prevVal += tex2D(ambPrevColor, texcoord + float2(0, z*pixelBlur)) * weight[z];
		prevVal += tex2D(ambPrevColor, texcoord - float2(0, z*pixelBlur)) * weight[z];
	}

	curr = currVal;
	prev = prevVal;
}

technique AdvancedMotionBlur_Tech <bool enabled = 
#if (AdvancedMB_TimeOut > 0)
1; int toggle = AdvancedMB_ToggleKey; timeout = AdvancedMB_TimeOut; >
#else
RFX_Start_Enabled; int toggle = AdvancedMB_ToggleKey; >
#endif
{
	pass AMBBlur
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = PS_AMBBlur;
		RenderTarget0 = ambCurrBlurTex;
		RenderTarget1 = ambPrevBlurTex;
	}

	pass AMBCombine
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = PS_AMBCombine;
	}

	pass AMBPrev
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = PS_AMBCopyPreviousFrame;
		RenderTarget0 = ambPrevTex;
	}
}

}
}

#endif

#ifndef RFX_duplicate
#include Ganossa_SETTINGS_UNDEF
#endif
