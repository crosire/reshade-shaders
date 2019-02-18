/*
	svofski's CRT PAL Shader
	Ported to ReShade by Matsilagi and luluco250
*/

#include "ReShade.fxh"

//Macros///////////////////////////////////////////////////////////////////////////////////////////

//on directx the matrices must be multiplied in reverse
//otherwise the luma is not displayed correctly, instead being pink
#if (__RENDERER__ >= 0x10000)
	#define MUL(A, B) mul(A, B)
#else
	#define MUL(A, B) mul(B, A)
#endif

//Statics//////////////////////////////////////////////////////////////////////////////////////////

static const float pi = atan(1.0) * 4.0;
static const float fsc = 4433618.75;
static const int fline = 15625;
static const int visible_lines = 312;

static const float3x3 rgb2yiq = float3x3(
	0.299, 0.595716, 0.211456,
	0.587,-0.274453,-0.522591,
	0.114,-0.321263,0.311135
);
static const float3x3 yiq2rgb = float3x3(
	1.0,    1.0,    1.0,
	0.9563,-0.2721,-1.1070,
	0.6210,-0.6474, 1.7046
);

static const float3x3 rgb2yuv = float3x3(
	0.299,-0.14713, 0.615,
	0.587,-0.28886,-0.514991,
	0.114, 0.436,  -0.10001
);
static const float3x3 yuv2rgb = float3x3(
	1.0,     1.0,     1.0,
	0.0,    -0.39465, 2.03211,
	1.13983,-0.58060, 0.0
);
/*static const float3x3 yuv2rgb = float3x3(
	1.0, 0.0,     1.13983,
	1.0,-0.39465,-0.58060,
	1.0, 2.03211, 0.0
);*/

static const int filter_taps = 20;

static const float width_ratio = BUFFER_WIDTH / (fsc / fline);
static const float height_ratio = BUFFER_HEIGHT / visible_lines;
static const float invx = 0.25 / (fsc / fline);

//Uniforms/////////////////////////////////////////////////////////////////////////////////////////

uniform float filter_gain <
	ui_label = "Filter Gain [PAL-CRT]";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 5.0;
	ui_step = 0.01;
> = 1.5;

uniform float filter_invgain <
	ui_label = "Filter Inverse Gain [PAL-CRT]";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 5.0;
	ui_step = 0.01;
> = 1.1;

//Functions////////////////////////////////////////////////////////////////////////////////////////

float filter(int i) {
	static const float arr[filter_taps] = {
		-0.008030271,
		 0.003107906,
		 0.016841352,
		 0.032545161,
		 0.049360136,
		 0.066256720,
		 0.082120150,
		 0.095848433,
		 0.106453014,
		 0.113151423,
		 0.115441842,
		 0.113151423,
		 0.106453014,
		 0.095848433,
		 0.082120150,
		 0.066256720,
		 0.049360136,
		 0.032545161,
		 0.016841352,
		 0.003107906
	};
	return arr[i];
}

float4 fetch(float offset, float2 center, float _invx) {
	center *= ReShade::PixelSize;
	return tex2D(ReShade::BackBuffer, float2(offset * _invx + center.x, center.y));
}

float modulated(float2 xy, float sinwt, float coswt) {
    float3 rgb = fetch(0, xy, invx).xyz;
    float3 yuv = MUL(rgb2yuv, rgb);

    return saturate(yuv.x + yuv.y * sinwt + yuv.z * coswt);
}

float2 modem_uv(float2 xy, int ofs, float altv) {
    float t = (xy.x + ofs * invx) * BUFFER_WIDTH;
    float wt = t * 2.0 * pi / width_ratio;

    float sinwt = sin(wt);
    float coswt = cos(wt + altv);

    float3 rgb = fetch(ofs, xy, invx).xyz;
    float3 yuv = MUL(rgb2yuv, rgb);
    float signal = saturate(yuv.x + yuv.y * sinwt + yuv.z * coswt);

    return float2(signal * sinwt, signal * coswt);
}

//Shaders//////////////////////////////////////////////////////////////////////////////////////////

float4 PS_PAL(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET {
	float2 xy = uv * ReShade::ScreenSize;

	float altv = (floor(xy.y * visible_lines + 0.5) % 2.0) * pi;

	float2 filtered = 0.0;
	[unroll]
	for (int i = 0; i < filter_taps; ++i) {
		float2 _uv = modem_uv(xy, i - filter_taps / 2, altv);
		filtered += filter_gain * _uv * filter(i);
	}

	float t = xy.x * BUFFER_WIDTH;
	float wt = t * 2.0 * pi / width_ratio;

	float sinwt = sin(wt);
	float coswt = cos(wt + altv);

	float luma = modulated(xy, sinwt, coswt) - filter_invgain * (filtered.x * sinwt + filtered.y * coswt);
	float3 yuv_result = float3(luma, filtered);

	return float4(MUL(yuv2rgb, yuv_result), 1.0);
}

//Technique////////////////////////////////////////////////////////////////////////////////////////

technique PAL_CRT {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_PAL;
	}
}