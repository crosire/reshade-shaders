//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit https://github.com/Oncorporation/reshade-shaders news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Surn Tron LUT shader 1.0 for ReShade 3.0
// Copyright © 20019 Charles Fettinger
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fTronLUT_TextureName
	#define fTronLUT_TextureName "tron.png"
#endif
#ifndef fTronLUT_TileSizeXY
	#define fTronLUT_TileSizeXY 32
#endif
#ifndef fTronLUT_TileAmount
	#define fTronLUT_TileAmount 32
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

uniform float fTronLUT_AmountLuma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "TronLUT luma amount";
	ui_tooltip = "Intensity of luma change of the PVT LUT.";
> = 0.85;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"
texture texTronLUT < source = fTronLUT_TextureName; > { Width = fTronLUT_TileSizeXY*fTronLUT_TileAmount; Height = fTronLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerTronLUT 	{ Texture = texTronLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float4 PS_Tron(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
	float4 textureColor = tex2D(ReShade::BackBuffer, texcoord);
	float blueColor = textureColor.b * 63.0;

	float2 quad1;
	quad1.y = floor(floor(blueColor) / 8.0);
	quad1.x = floor(blueColor) - (quad1.y * 8.0);

	float2 quad2;
	quad2.y = floor(ceil(blueColor) / 8.0);
	quad2.x = ceil(blueColor) - (quad2.y * 8.0);

	float2 texPos1;
	texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
	texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

	float2 texPos2;
	texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
	texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

	float4 newColor1 = tex2D(SamplerTronLUT, texPos1);
	float4 newColor2 = tex2D(SamplerTronLUT, texPos2);
	float4 luttedColor = lerp(newColor1, newColor2, frac(blueColor));

	float4 final_color = lerp(textureColor, luttedColor, fTronLUT_AmountLuma);
	return float4(final_color.rgb, textureColor.a);
}
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique Tron_LUT
{
	pass Tron_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Tron;
	}
}