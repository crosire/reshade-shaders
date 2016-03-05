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
 *
 * Credits: Based on kingeric1992's TiltShift effect
 */

#include EFFECT_CONFIG(Ganossa)

#if USE_TILTSHIFT

#pragma message "TiltShift by kingeric1992 and Ganossa\n"

#define ScreenRatio float(-BUFFER_WIDTH / BUFFER_HEIGHT)

namespace Ganossa
{

float4 PS_TiltShiftH(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 res = tex2D(ReShade::BackBuffer, texcoord);

	float2 othogonal = float2(0.0f, ScreenRatio);
	float2 pos = othogonal * TiltShiftOffset;
	float TiltShiftDist = abs(dot(texcoord - pos, othogonal) / length(othogonal));

	res.a = pow(saturate(TiltShiftDist), TiltShiftCurve);

	float blurAmount = res.a * (TiltShiftPower + max(1.0f - min(res.r, min(res.g, res.b)), 0.0f));
	float blurAmountChroma = res.a * (TiltShiftPower + max(max(res.r, max(res.g, res.b)) - 0.8f, 0.0f)*1.8f);
	
	float pixelBlur = blurAmount * (BUFFER_RCP_HEIGHT);
	float pixelBlurChroma = blurAmountChroma * (BUFFER_RCP_WIDTH);

	float CHROMA_POW = 760.0;
	float3 fvChroma = float3(0.995, 1.000, 1.005);
		float3 chroma = pow(fvChroma, CHROMA_POW * pixelBlurChroma);

		float2 tr = ((2.0 * texcoord - 1.0) * chroma.r) * 0.5 + 0.5;
		float2 tg = ((2.0 * texcoord - 1.0) * chroma.g) * 0.5 + 0.5;
		float2 tb = ((2.0 * texcoord - 1.0) * chroma.b) * 0.5 + 0.5;

		res.rgb = lerp(res.rgb, float3(tex2D(ReShade::BackBuffer, tr).r, tex2D(ReShade::BackBuffer, tg).g, tex2D(ReShade::BackBuffer, tb).b) * (1.0 - pixelBlur), 0.8);


	float weight[11] = { 0.082607, 0.080977, 0.076276, 0.069041, 0.060049, 0.050187, 0.040306, 0.031105, 0.023066, 0.016436, 0.011254 };
	res *= weight[0];
	for (int i = 1; i < 11; i++)
	{
		float4 tempPlus = tex2D(ReShade::BackBuffer, texcoord.xy + float2(i*pixelBlur,0));
		float tempPlusWeight = max(max(res.r, max(res.g, res.b)) - 0.93f, 0.0f) * (pixelBlur * 80);
		res += tempPlus * min(0.8f, (weight[i] + tempPlusWeight));
		float4 tempMinus = tex2D(ReShade::BackBuffer, texcoord.xy - float2(i*pixelBlur,0));
		float tempMinusWeight = max(max(res.r, max(res.g, res.b)) - 0.93f, 0.0f) * (pixelBlur * 80);
		res += tempMinus * min(0.8f, (weight[i] + tempMinusWeight));
	}

	return res;
}

float4 PS_TiltShiftV(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 res = tex2D(ReShade::BackBuffer, texcoord);

	float2 othogonal = float2(0.0f, ScreenRatio);
	float2 pos = othogonal * TiltShiftOffset;
	float TiltShiftDist = abs(dot(texcoord - pos, othogonal) / length(othogonal));

	res.a = pow(saturate(TiltShiftDist), TiltShiftCurve);

	float blurAmount = res.a * (TiltShiftPower + max(1.0f - min(res.r, min(res.g, res.b)), 0.0f));
	float blurAmountChroma = res.a * (TiltShiftPower + max(max(res.r, max(res.g, res.b)) - 0.8f, 0.0f)*1.8f);
	
	float pixelBlur = blurAmount * (BUFFER_RCP_HEIGHT);
	float pixelBlurChroma = blurAmountChroma * (BUFFER_RCP_WIDTH);

	float CHROMA_POW = 760.0;
	float3 fvChroma = float3(0.995, 1.000, 1.005);
		float3 chroma = pow(fvChroma, CHROMA_POW * pixelBlurChroma);

		float2 tr = ((2.0 * texcoord - 1.0) * chroma.r) * 0.5 + 0.5;
		float2 tg = ((2.0 * texcoord - 1.0) * chroma.g) * 0.5 + 0.5;
		float2 tb = ((2.0 * texcoord - 1.0) * chroma.b) * 0.5 + 0.5;

		res.rgb = lerp(res.rgb, float3(tex2D(ReShade::BackBuffer, tr).r, tex2D(ReShade::BackBuffer, tg).g, tex2D(ReShade::BackBuffer, tb).b) * (1.0 - pixelBlur), 0.8);


	float weight[11] = { 0.082607, 0.080977, 0.076276, 0.069041, 0.060049, 0.050187, 0.040306, 0.031105, 0.023066, 0.016436, 0.011254 };
	res *= weight[0];
	for (int i = 1; i < 11; i++)
	{
		float4 tempPlus = tex2D(ReShade::BackBuffer, texcoord.xy + float2(0,i*pixelBlur));
		float tempPlusWeight = max(max(res.r, max(res.g, res.b)) - 0.93f, 0.0f) * (pixelBlur * 80);
		res += tempPlus * min(0.8f, (weight[i] + tempPlusWeight));
		float4 tempMinus = tex2D(ReShade::BackBuffer, texcoord.xy - float2(0,i*pixelBlur));
		float tempMinusWeight = max(max(res.r, max(res.g, res.b)) - 0.93f, 0.0f) * (pixelBlur * 80);
		res += tempMinus * min(0.8f, (weight[i] + tempMinusWeight));
	}

	return res;
}


technique TiltShift_Tech <bool enabled = 
#if (TiltShift_TimeOut > 0)
1; int toggle = TiltShift_ToggleKey; timeout = TiltShift_TimeOut; >
#else
RESHADE_START_ENABLED; int toggle = TiltShift_ToggleKey; >
#endif
{
	pass TiltShiftHPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_TiltShiftH;
	}

	pass TiltShiftVPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_TiltShiftV;
	}
}

}

#endif

#include "ReShade/Shaders/Ganossa.undef" 
