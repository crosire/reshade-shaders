//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Yet Another Chromatic Aberration by Marty McFly
// For private use only!
// Copyright © 2008-2015 Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int YACA_ImageChromaHues <
	ui_type = "drag";
	ui_min = 2; ui_max = 30;
	ui_tooltip = "Amount of samples through the light spectrum to get a smooth gradient.";
> = 25;
uniform float YACA_ImageChromaCurve <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 2.0;
	ui_tooltip = "Image chromatic aberration curve. Higher means less chroma at screen center areas.";
> = 1.0;
uniform float YACA_ImageChromaAmount <
	ui_type = "drag";
	ui_min = 5.0; ui_max = 200.0;
	ui_tooltip = "Linearly increases image chromatic aberration amount.";
> = 100.0;

#include "ReShade.fxh"

float3 PS_YACA(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{  
		texcoord = texcoord * 2.0 - 1.0;
		float offsetfact = length(texcoord);
		offsetfact = pow(offsetfact, YACA_ImageChromaCurve) * YACA_ImageChromaAmount * ReShade::PixelSize.x;
 
		float3 scenecolor = 0.0;
		float3 chromaweight = 0.0;
 
		[unroll]
		for (float c = 0; c < YACA_ImageChromaHues && c < 90; c++)
		{
				float  temphue = c / YACA_ImageChromaHues;
				float3 tempchroma = saturate(float3(abs(temphue * 6.0 - 3.0) - 1.0,2.0 - abs(temphue * 6.0 - 2.0),2.0 - abs(temphue * 6.0 - 4.0)));
				float  tempoffset = (c + 0.5) / YACA_ImageChromaHues - 0.5;
				float3 tempsample = tex2Dlod(ReShade::BackBuffer, float4(texcoord * (1.0 + offsetfact * tempoffset) * 0.5 + 0.5, 0, 0)).xyz;

				scenecolor += tempsample * tempchroma;
				chromaweight += tempchroma;
		}

		//not all hues have the same brightness, FF0000 and FFFF00 are obviously differently bright but are just different hues.
		//there is no generic way to make it work for all different hue options. Sometimes / samples * 0.5 works, then * 0.666, then something completely different.
		scenecolor /= dot(chromaweight, 0.333);
 
		return scenecolor;
}

technique YACA
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_YACA;
	}
}
