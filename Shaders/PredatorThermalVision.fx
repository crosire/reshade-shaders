//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit https://github.com/Oncorporation/reshade-shaders news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Surn Predator Thermal Vision LUT shader 1.0 for ReShade 3.0
// Copyright © 20019 Charles Fettinger
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fPTVLUT_TextureName
	#define fPTVLUT_TextureName "ptvlut.png"
#endif
#ifndef fPTVLUT_TileSizeXY
	#define fPTVLUT_TileSizeXY 512
#endif
#ifndef fPTVLUT_TileAmountX
	#define fPTVLUT_TileAmountX 1
#endif
#ifndef fPTVLUT_TileAmountY
	#define fPTVLUT_TileAmountY 1
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

uniform float fPTVLUT_AmountLuma < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "PTVLUT luma amount";
	ui_tooltip = "Intensity of luma change of the PVT LUT.";
> = 0.85;

uniform float fPTVLUT_AmountChroma < __UNIFORM_SLIDER_FLOAT1
	ui_min = -1.00; ui_max = 10.00;
	ui_label = "LUT chroma amount";
	ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 6.30;

uniform float fPTVLUT_AmbientHeat < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "Environment Ambient Heat Level";
	ui_tooltip = "Ambient Temperature/Luminance, above level applies LUT Chroma Amount.";
> = 0.0;

uniform float fPTVLUT_AmbientHeatAdjustment < __UNIFORM_SLIDER_FLOAT1
	ui_min = -5.00; ui_max = 5.00;
	ui_label = "Environment Ambient Heat Adjustment";
	ui_tooltip = "Adjust Ambient Temperature/Luminance.";
> = 0.0;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"
texture texPTVLUT < source = fPTVLUT_TextureName; > { Width = fPTVLUT_TileSizeXY*fPTVLUT_TileAmountX; Height = fPTVLUT_TileSizeXY*fPTVLUT_TileAmountY; Format = RGBA8; };
sampler	SamplerPTVLUT 	{ Texture = texPTVLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float4 PS_Predator_Thermal_Vision(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
	float4 textureColor = tex2D(ReShade::BackBuffer, texcoord);
	const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);
	float lumaLevel = dot(coefLuma, textureColor.rgb);
	if (lumaLevel >= fPTVLUT_AmbientHeat)  {
		lumaLevel *= (fPTVLUT_AmountChroma * 10);
	} else {
		lumaLevel += fPTVLUT_AmbientHeatAdjustment;
	}
	float blueColor = lumaLevel;//textureColor.b * (fPTVLUT_AmountChroma * 10);//63.0

	float2 quad1;
	quad1.y = floor(floor(blueColor) / 8.0);
	quad1.x = floor(blueColor) - (quad1.y * 8.0);

	float2 quad2;
	quad2.y = floor(ceil(blueColor) / 8.0);
	quad2.x = ceil(blueColor) - (quad2.y * 8.0);

	float2 texPos1;
	texPos1.x = (quad1.x * 0.125) + 0.5/fPTVLUT_TileSizeXY + ((0.125 - 1.0/fPTVLUT_TileSizeXY) * textureColor.r);
	texPos1.y = (quad1.y * 0.125) + 0.5/fPTVLUT_TileSizeXY + ((0.125 - 1.0/fPTVLUT_TileSizeXY) * textureColor.g);

	float2 texPos2;
	texPos2.x = (quad2.x * 0.125) + 0.5/fPTVLUT_TileSizeXY + ((0.125 - 1.0/fPTVLUT_TileSizeXY) * textureColor.r);
	texPos2.y = (quad2.y * 0.125) + 0.5/fPTVLUT_TileSizeXY + ((0.125 - 1.0/fPTVLUT_TileSizeXY) * textureColor.g);

	float4 newColor1 = tex2D(SamplerPTVLUT, texPos1);
	float4 newColor2 = tex2D(SamplerPTVLUT, texPos2);
	float4 luttedColor = lerp(newColor1, newColor2, frac(blueColor));

	float4 final_color = lerp(textureColor, luttedColor, fPTVLUT_AmountLuma);
	return float4(final_color.rgb, textureColor.a);
}

void PS_Predator_Thermal_Vision_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float2 texelsize = ReShade::PixelSize;//1.0 / fPTVLUT_TileSizeXY;
	texelsize.x /= fPTVLUT_TileAmountX;
	texelsize.y /= fPTVLUT_TileAmountY;

	float3 lutcoord = float3((color.xy*fPTVLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fPTVLUT_TileSizeXY-color.z);
	float lerpfact = frac(lutcoord.z);
	lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

	float3 lutcolor = lerp(tex2D(SamplerPTVLUT, lutcoord.xy).xyz, tex2D(SamplerPTVLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

	color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fPTVLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fPTVLUT_AmountLuma);

	res.xyz = color.xyz;
	res.w = 1.0;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique Predator_Thermal_Vision
{
	pass PTV_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Predator_Thermal_Vision;
	}
}