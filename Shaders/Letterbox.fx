// Shader by Jacob Maximilian Fober
// https://creativecommons.org/publicdomain/mark/1.0/
// This work is free of known copyright restrictions.
// Letterbox PS

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float3 Color <
	ui_label = "Bars Color";
	ui_type = "Color";
> = float3(0.027, 0.027, 0.027);

uniform float UserAspect <
	ui_label = "Aspect Ratio";
	ui_tooltip = "Desired Aspect Ratio Float";
	ui_type = "drag";
	ui_min = 1.0; ui_max = 3.0;
> = 2.4;

uniform float Opacity <
	ui_label = "Opacity";
	ui_tooltip = "Bars opacity";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

float3 LetterboxPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Get Aspect Ratio
	float RealAspect = ReShade::AspectRatio;
	// Sample display image
	float3 Display = tex2D(ReShade::BackBuffer, texcoord).rgb;

	if (RealAspect == UserAspect)
	{
		return Display;
	}
	else if (UserAspect > RealAspect)
	{
		// Get Letterbox Bars width
		float Bars = (1.0 - RealAspect / UserAspect) * 0.5;

		if (texcoord.y > Bars && texcoord.y < 1.0 - Bars)
		{
			return Display;
		}
		else
		{
			return lerp(Display, Color, Opacity);
		}
	}
	else
	{
		// Get Pillarbox Bars width
		float Bars = (1.0 - UserAspect / RealAspect) * 0.5;

		if (texcoord.x > Bars && texcoord.x < 1.0 - Bars)
		{
			return Display;
		}
		else
		{
			return lerp(Display, Color, Opacity);
		}
	}
}


technique Letterbox
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LetterboxPS;
	}
}
