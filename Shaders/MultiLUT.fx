//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Multi-LUT shader, using a texture atlas with multiple LUTs
// by Otis / Infuse Project.
// Based on Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fLUT_TextureName
#define fLUT_TextureName "MultiLut_Atlas1.png"
#endif
#ifndef fLUT_TileSizeXY
#define fLUT_TileSizeXY 32
#endif
#ifndef fLUT_TileAmount
#define fLUT_TileAmount 32
#endif
#ifndef fLUT_LutAmount
#define fLUT_LutAmount 17
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

uniform int fLUT_LutSelector < __UNIFORM_LIST_INT1
	ui_items = "Neutral\0Color1\0Color2\0Color3 (Blue oriented)\0Color4 (Hollywood)\0Color5\0Color6\0Color7\0Color8\0Cool light\0Flat & green\0Red lift matte\0Cross process\0Azure Red Dual Tone\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
	ui_label = "The LUT to use";
	ui_tooltip = "The LUT to use for color transformation. 'Neutral' doesn't do any color transformation.";
> = 0;

uniform float fLUT_AmountLuma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0; ui_step = (1.0 / 100.0);
	ui_label = "LUT luma amount";
	ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.0;

uniform float fLUT_AmountChroma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0; ui_step = (1.0 / 100.0);
	ui_label = "LUT chroma amount";
	ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.0;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

texture texMultiLUT < source = fLUT_TextureName; >
{
	Width = fLUT_TileSizeXY * fLUT_TileAmount;
	Height = fLUT_TileSizeXY * fLUT_LutAmount;
	Format = RGBA8;
};

sampler SamplerMultiLUT
{
	Texture = texMultiLUT;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_MultiLUT_Apply(in float4 vars : SV_Position, in float2 texCoord : TEXCOORD, out float4 back : SV_Target)
{
	back = tex2D(ReShade::BackBuffer, texCoord);
	vars = float(fLUT_TileSizeXY - 1) / fLUT_TileSizeXY * back.rgrg + 0.5 / fLUT_TileSizeXY;

	float blueTable = back.b * (fLUT_TileAmount - 1);

	vars.xz = (vars.xz + float2(floor(blueTable), ceil(blueTable))) * (1.0 / fLUT_TileAmount);
	vars.yw = (vars.yw + fLUT_LutSelector) / fLUT_LutAmount;

	vars = lerp(tex2D(SamplerMultiLUT, vars.xy), tex2D(SamplerMultiLUT, vars.zw), frac(blueTable));
	vars = lerp(length(back), length(vars), fLUT_AmountLuma) * lerp(normalize(back), normalize(vars), fLUT_AmountChroma);
	vars.a = back.a;

	back = vars;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique MultiLUT
{
	pass MultiLUT_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_MultiLUT_Apply;
	}
}
