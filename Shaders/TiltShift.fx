// Based on kingeric1992's TiltShift effect

uniform bool Line <
	ui_label = "Show Center Line";
> = false;

uniform float Axis <
	ui_type = "drag";
	ui_min = -90; ui_max = 90; ui_step = 1;
> = 0.0;
uniform float Offset <
	ui_type = "drag";
	ui_min = -5; ui_max = 5;
> = 0.0;

uniform float BlurCurve <
	ui_type = "drag";
	ui_min = 0; ui_max = 10;
	ui_label = "Blur Curve";
> = 1.0;
uniform float BlurMultiplier <
	ui_type = "drag";
	ui_min = 0; ui_max = 100;
	ui_label = "Blur Multiplier";
> = 10.0;

#include "ReShade.fxh"

float4 PS_FakeTiltShiftPass1(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 res = tex2D(ReShade::BackBuffer, texcoord);

	float2 othogonal = float2(tan(Axis * 0.0174533), -1.0 / ReShade::AspectRatio);
	float2 pos = othogonal * Offset;
	float dist = abs(dot(texcoord - pos, othogonal) / length(othogonal));

	res.a = pow(saturate(dist), BlurCurve);
	res.rgb = (Line && dist < 0.01) ? float3(1.0, 0, 0) : res.rgb;

	return res;
}
float4 PS_FakeTiltShiftPass2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float weight[11] = {
		0.082607,
		0.080977,
		0.076276,
		0.069041,
		0.060049,
		0.050187,
		0.040306,
		0.031105,
		0.023066,
		0.016436,
		0.011254
	};

	float4 res = tex2D(ReShade::BackBuffer, texcoord);
	float blurAmount = res.a * BlurMultiplier;
	res *= weight[0];

	for (int i = 1; i < 11; i++)
	{
		res += tex2D(ReShade::BackBuffer, texcoord.xy + float2(i * ReShade::PixelSize.x * blurAmount, 0)) * weight[i];
		res += tex2D(ReShade::BackBuffer, texcoord.xy - float2(i * ReShade::PixelSize.x * blurAmount, 0)) * weight[i];
	}

	return res;
}
float4 PS_FakeTiltShiftPass3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float weight[11] = {
		0.082607,
		0.080977,
		0.076276,
		0.069041,
		0.060049,
		0.050187,
		0.040306,
		0.031105,
		0.023066,
		0.016436,
		0.011254
	};

	float4 res = tex2D(ReShade::BackBuffer, texcoord);
	float blurAmount = res.a * BlurMultiplier;
	res *= weight[0];

	for (int i = 1; i < 11; i++)
	{
		res += tex2D(ReShade::BackBuffer, texcoord.xy + float2(0, i * ReShade::PixelSize.y * blurAmount)) * weight[i];
		res += tex2D(ReShade::BackBuffer, texcoord.xy - float2(0, i * ReShade::PixelSize.y * blurAmount)) * weight[i];
	}

	return res;
}


technique TiltShift
{
	pass CoCToAlpha
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FakeTiltShiftPass1;
	}
	pass GaussianBlurH
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FakeTiltShiftPass2;
	}
	pass GaussianBlurV
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FakeTiltShiftPass3;
	}
}
