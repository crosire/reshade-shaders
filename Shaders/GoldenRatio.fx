///////////////////////////////////////////////////////////////////
// This effects shows an overlay with fibonacci spirals to quickly
// see where the golden ratios are in the image. For screenshotters mainly. 
///////////////////////////////////////////////////////////////////
// By Otis / Infuse Project
///////////////////////////////////////////////////////////////////

uniform float Opacity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Opacity of overlay. 0 is invisible, 1 is opaque lines.";
> = 0.30;
uniform int ResizeMode <
	ui_type = "combo";
	ui_items = "Clamp to screen\0Keep aspect ratio\0";
	ui_label = "Resize Mode";
	ui_tooltip = "Either clamp to screen (so resizing of overlay, no golden ratio by definition), or resize to either full with or full height while keeping aspect ratio: golden ratio by definition in lined area";
> = 1;

#include "Reshade.fxh"

texture texSpirals < source = "GoldenSpirals.png"; > { Width = 720; Height = 480; Format = R8; };
sampler samplerSpirals { Texture = texSpirals; };

void PS_RenderSpirals(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target)
{
	float phiValue = (1.0 + sqrt(5.0)) * 0.5;
	float idealWidth = ReShade::ScreenSize.y * phiValue;
	float idealHeight = ReShade::ScreenSize.x / phiValue;
	float4 sourceCoordFactor = float4(1.0, 1.0, 1.0, 1.0);

	if (ResizeMode == 1)
	{
		if (ReShade::AspectRatio < phiValue)
		{
			// display spirals at full width, but resize across height
			sourceCoordFactor = float4(1.0, ReShade::ScreenSize.y / idealHeight, 1.0, idealHeight / ReShade::ScreenSize.y);
		}
		else
		{
			// display spirals at full height, but resize across width
			sourceCoordFactor = float4(ReShade::ScreenSize.x / idealWidth, 1.0, idealWidth / ReShade::ScreenSize.x, 1.0);
		}
	}

	float4 colFragment = tex2D(ReShade::BackBuffer, texcoord);
	float spiralFragment = tex2D(samplerSpirals, texcoord * sourceCoordFactor.xy - ((1.0 - sourceCoordFactor.zw) * 0.5)).x;
	outFragment = saturate(colFragment + (spiralFragment * Opacity));
}

technique GoldenRatio
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_RenderSpirals;
	}
}
