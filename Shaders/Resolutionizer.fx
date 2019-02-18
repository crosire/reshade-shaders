/*
	Resolution Changer by luluco250
	
	Based on Pixelizer
*/

#include "ReShade.fxh"

//preprocessor definitions//////////////////////////////////////////////////////////////////////////////////////////////////

//crosire, the reference.md lacks documentation on these macro values, could you update it with them?
#if _RENDERER_ == 0x09300
	#define Pixelizer_int int
#else
	#define Pixelizer_int uint
#endif

#define f2Pixelizer_DownSampleRes float2(iPixelizer_DownSampleX, iPixelizer_DownSampleY)

//uniform variables/////////////////////////////////////////////////////////////////////////////////////////////////////////

uniform Pixelizer_int iPixelizer_DownSampleType <
	ui_label = "DownSample Type [Pixelizer]";
	ui_type = "combo";
	ui_items = "Disabled\0Resolution Scale\0Custom Resolution\0";
> = 0;

uniform bool bPixelizer_SmoothDownSample <
	ui_label = "Smooth DownSample [Pixelizer]";
> = false;

uniform float fPixelizer_DownSampleScale <
	ui_label = "Resolution Scale [Pixelizer]";
	ui_type = "drag";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 1.0;

uniform Pixelizer_int iPixelizer_DownSampleX <
	ui_label = "Custom Width [Pixelizer]";
	ui_type = "drag";
	ui_min = 1;
	ui_max = BUFFER_WIDTH;
	ui_step = 1;
> = BUFFER_WIDTH;

uniform Pixelizer_int iPixelizer_DownSampleY <
	ui_label = "Custom Height [Pixelizer]";
	ui_type = "drag";
	ui_min = 1;
	ui_max = BUFFER_HEIGHT;
	ui_step = 1;
> = BUFFER_HEIGHT;

//samplers//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

sampler sPixelBackBuffer { Texture=ReShade::BackBufferTex; MinFilter=POINT; MagFilter=POINT; };

//functions/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//shaders///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float3 DownSample(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
	uv -= 0.5;
	uv /= 	iPixelizer_DownSampleType == 1 ? fPixelizer_DownSampleScale :
			iPixelizer_DownSampleType == 2 ? f2Pixelizer_DownSampleRes * ReShade::PixelSize :
			uv;
	uv += 0.5;
	return bPixelizer_SmoothDownSample ? tex2D(ReShade::BackBuffer, uv).rgb : tex2D(sPixelBackBuffer, uv).rgb;
}

float3 UpSample(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
	uv -= 0.5;
	uv *= 	iPixelizer_DownSampleType == 1 ? fPixelizer_DownSampleScale :
			iPixelizer_DownSampleType == 2 ? f2Pixelizer_DownSampleRes * ReShade::PixelSize :
			uv;
	uv += 0.5;
	return tex2D(sPixelBackBuffer, uv).rgb;
}

//techniques////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique Resolutionizer {
	pass DownSample {
		VertexShader=PostProcessVS;
		PixelShader=DownSample;
	}
	pass UpSample {
		VertexShader=PostProcessVS;
		PixelShader=UpSample;
	}
}

//preprocessor undefinitions////////////////////////////////////////////////////////////////////////////////////////////////

#undef Pixelizer_int
#undef f2Pixelizer_DownSampleRes
