/**
 * FineSharp by Didée
 * http://avisynth.nl/images/FineSharp.avsi
 *
 * Initial HLSL port by -Vit-
 * https://forum.doom9.org/showthread.php?t=171346
 *
 * Modified and optimized for ReShade by JPulowski
 *
 * Do not distribute without giving credit to the original author(s).
 *
 * 1.0  - Initial release
 */

#include EFFECT_CONFIG(JPulowski)

#if USE_FINESHARP

#pragma message "FineSharp by Didee (ported by -Vit- and JPulowski)\n"

namespace JPulowski {

// Helper functions

float4 Src(float a, float b, float2 tex) {
	return tex2D(ReShade::BackBuffer, mad(ReShade::PixelSize, float2(a, b), tex));
}

float3x3 RGBtoYUV(float Kb, float Kr) {
	return float3x3(float3(Kr, 1.0 - Kr - Kb, Kb), float3(-Kr, Kr + Kb - 1.0, 1.0 - Kb) / (2.0 * (1.0 - Kb)), float3(1.0 - Kr, Kr + Kb - 1.0, -Kb) / (2.0 * (1.0 - Kr)));
}

float3x3 YUVtoRGB(float Kb, float Kr) {
	return float3x3(float3(1.0, 0.0, 2.0 * (1.0 - Kr)), float3(Kb + Kr - 1.0, 2.0 * (1.0 - Kb) * Kb, 2 * Kr * (1.0 - Kr)) / (Kb + Kr - 1.0), float3(1.0, 2.0 * (1.0 - Kb), 0.0));
}

void sort(inout float a1, inout float a2) {
	float t = min(a1, a2);
	a2 = max(a1, a2);
	a1 = t;
}

float median3(float a1, float a2, float a3) {
	sort(a2, a3);
	sort(a1, a2);
	
	return min(a2, a3);
}

float median5(float a1, float a2, float a3, float a4, float a5) {
	sort(a1, a2);
	sort(a3, a4);
	sort(a1, a3);
	sort(a2, a4);
	
	return median3(a2, a3, a5);
}

float median9(float a1, float a2, float a3, float a4, float a5, float a6, float a7, float a8, float a9) {
	sort(a1, a2);
	sort(a3, a4);
	sort(a5, a6);
	sort(a7, a8);
	sort(a1, a3);
	sort(a5, a7);
	sort(a1, a5);
	
	sort(a3, a5);
	sort(a3, a7);
	sort(a2, a4);
	sort(a6, a8);
	sort(a4, a8);
	sort(a4, a6);
	sort(a2, a6);
	
	return median5(a2, a4, a5, a7, a9);
}

void sort_min_max7(inout float a1, inout float a2, inout float a3, inout float a4, inout float a5, inout float a6, inout float a7) {
	sort(a1, a2);
	sort(a3, a4);
	sort(a5, a6);
	
	sort(a1, a3);
	sort(a1, a5);
	sort(a2, a6);
	
	sort(a4, a5);
	sort(a1, a7);
	sort(a6, a7);
}

void sort_min_max9(inout float a1, inout float a2, inout float a3, inout float a4, inout float a5, inout float a6, inout float a7, inout float a8, inout float a9) {
	sort(a1, a2);
	sort(a3, a4);
	sort(a5, a6);
	sort(a7, a8);
	
	sort(a1, a3);
	sort(a5, a7);
	sort(a1, a5);
	sort(a2, a4);
	
	sort(a6, a7);
	sort(a4, a8);
	sort(a1, a9);
	sort(a8, a9);
}

void sort9_partial2(inout float a1, inout float a2, inout float a3, inout float a4, inout float a5, inout float a6, inout float a7, inout float a8, inout float a9) {
	sort_min_max9(a1,a2,a3,a4,a5,a6,a7,a8,a9);
	sort_min_max7(a2,a3,a4,a5,a6,a7,a8);
}


float SharpDiff(float4 c) {
	float t = c.a - c.x;
	return sign(t) * (sstr / 255.0) * pow(abs(t) / (lstr / 255.0), 1.0 / pstr) * ((t * t) / mad(t, t, ldmp / 65025.0));
}

// Main

float4 PS_FineSharp_P0(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	float3 yuv = mul(RGBtoYUV(0.0722, 0.2126), Src(0.0, 0.0, texcoord).rgb ) + float3(0.0, 0.5, 0.5);
	return float4(yuv, yuv.x);
}

float4 PS_FineSharp_P1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	float4 o = Src(0.0, 0.0, texcoord);
	
	o.x += o.x;
	o.x += Src( 0.0, -1.0, texcoord).x + Src(-1.0,  0.0, texcoord).x + Src( 1.0, 0.0, texcoord).x + Src(0.0, 1.0, texcoord).x;
	o.x += o.x;
	o.x += Src(-1.0, -1.0, texcoord).x + Src( 1.0, -1.0, texcoord).x + Src(-1.0, 1.0, texcoord).x + Src(1.0, 1.0, texcoord).x;
	o.x *= 0.0625;

	return o;
}

float4 PS_FineSharp_P2(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	float4 o = Src(0.0, 0.0, texcoord);

	float t1 = Src(-1.0, -1.0, texcoord).x;
	float t2 = Src( 0.0, -1.0, texcoord).x;
	float t3 = Src( 1.0, -1.0, texcoord).x;
	float t4 = Src(-1.0,  0.0, texcoord).x;
	float t5 = o.x;
	float t6 = Src( 1.0,  0.0, texcoord).x;
	float t7 = Src(-1.0,  1.0, texcoord).x;
	float t8 = Src( 0.0,  1.0, texcoord).x;
	float t9 = Src( 1.0,  1.0, texcoord).x;
	o.x = median9(t1,t2,t3,t4,t5,t6,t7,t8,t9);
	
	return o;
}

float4 PS_FineSharp_P3(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	float4 o = Src(0.0, 0.0, texcoord);
	
	float sd = SharpDiff(o);
	o.x = o.a + sd;
	sd += sd;
	sd += SharpDiff(Src( 0.0, -1.0, texcoord)) + SharpDiff(Src(-1.0,  0.0, texcoord)) + SharpDiff(Src( 1.0, 0.0, texcoord)) + SharpDiff(Src( 0.0, 1.0, texcoord));
	sd += sd;
	sd += SharpDiff(Src(-1.0, -1.0, texcoord)) + SharpDiff(Src( 1.0, -1.0, texcoord)) + SharpDiff(Src(-1.0, 1.0, texcoord)) + SharpDiff(Src( 1.0, 1.0, texcoord));
	sd *= 0.0625;
	o.x -= cstr * sd;
	o.a = o.x;

	return o;
}

float4 PS_FineSharp_P4(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	float4 o = Src(0.0, 0.0, texcoord);

	float t1 = Src(-1.0, -1.0, texcoord).a;
	float t2 = Src( 0.0, -1.0, texcoord).a;
	float t3 = Src( 1.0, -1.0, texcoord).a;
	float t4 = Src(-1.0,  0.0, texcoord).a;
	float t5 = o.a;
	float t6 = Src( 1.0,  0.0, texcoord).a;
	float t7 = Src(-1.0,  1.0, texcoord).a;
	float t8 = Src( 0.0,  1.0, texcoord).a;
	float t9 = Src( 1.0,  1.0, texcoord).a;

	o.x += t1 + t2 + t3 + t4 + t6 + t7 + t8 + t9;
	o.x /= 9.0;
	o.x = mad(9.9, (o.a - o.x), o.a);
	
	sort9_partial2(t1, t2, t3, t4, t5, t6, t7, t8, t9);
	o.x = max(o.x, min(t2, o.a));
	o.x = min(o.x, max(t8, o.a));

	return o;
}

float4 PS_FineSharp_P5(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	float4 o = Src(0.0, 0.0, texcoord);

	float edge = abs(Src(0.0, -1.0, texcoord).x + Src(-1.0, 0.0, texcoord).x + Src(1.0, 0.0, texcoord).x + Src(0.0, 1.0, texcoord).x - 4 * o.x);
	o.x = lerp(o.a, o.x, xstr * (1.0 - saturate(edge * xrep)));

	return o;
}

float4 PS_FineSharp_P6(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD0) : SV_TARGET {
	float4 rgb = Src(0.0, 0.0, texcoord);
	rgb.xyz = mul(YUVtoRGB(0.0722,0.2126), rgb.xyz - float3(0.0, 0.5, 0.5));
	return rgb;
}

technique FineSharp_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = FineSharp_ToggleKey; >
{
	pass ToYUV
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P0;
	}
	
#if (mode == 2)
	
	pass RemoveGrain4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P2;
	}
	
	pass RemoveGrain11
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P1;
	}
	
#elif (mode == 3)
	
	pass RemoveGrain4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P2;
	}
	
	pass RemoveGrain11
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P1;
	}
	
	pass RemoveGrain4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P2;
	}
	
#else
	
	pass RemoveGrain11
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P1;
	}
	
	pass RemoveGrain4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P2;
	}

#endif
	
	pass FineSharpA
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P3;
	}
	
	pass FineSharpB
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P4;
	}
	
	pass FineSharpC
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P5;
	}
	
	pass ToRGB
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_FineSharp_P6;
	}
}

}

#endif

#include EFFECT_CONFIG_UNDEF(JPulowski)
