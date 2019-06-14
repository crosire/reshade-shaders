//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fLUT_TextureName
#define fLUT_TextureName "lut.png"
#endif
#ifndef fLUT_TileSizeXY
#define fLUT_TileSizeXY 32
#endif
#ifndef fLUT_TileAmount
#define fLUT_TileAmount 32
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

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

texture texLUT < source = fLUT_TextureName; >
{
	Width = fLUT_TileSizeXY * fLUT_TileAmount;
	Height = fLUT_TileSizeXY;
	Format = RGBA8;
};

sampler SamplerLUT
{
	Texture = texLUT;
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_LUT_Apply(in float4 vars : SV_Position, in float2 texCoord : TEXCOORD, out float4 back : SV_Target)
{
	back = tex2D(ReShade::BackBuffer, texCoord);
	vars = float(fLUT_TileSizeXY - 1) / fLUT_TileSizeXY * back.rgrg + 0.5 / fLUT_TileSizeXY;

	float blueTable = back.b * (fLUT_TileAmount - 1);

	vars.xz = (vars.xz + float2(floor(blueTable), ceil(blueTable))) * (1.0 / fLUT_TileAmount);

	vars = lerp(tex2D(SamplerLUT, vars.xy), tex2D(SamplerLUT, vars.zw), frac(blueTable));
	vars = lerp(length(back), length(vars), fLUT_AmountLuma) * lerp(normalize(back), normalize(vars), fLUT_AmountChroma);
	vars.a = back.a;

	back = vars;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique LUT
{
	pass LUT_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_LUT_Apply;
	}
}
