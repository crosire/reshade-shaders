/**
 * Depth-buffer based cel shading for ENB by kingeric1992
 * http://enbseries.enbdev.com/forum/viewtopic.php?f=7&t=3244#p53168
 *
 * Modified and optimized for ReShade by JPulowski
 * http://reshade.me/forum/shader-presentation/261
 *
 * Do not distribute without giving credit to the original author(s).
 * 
 * 1.0  - Initial release/port
 * 1.1  - Replaced depth linearization algorithm with another one by crosire
 *        Added an option to tweak accuracy
 *        Modified the code to make it compatible with SweetFX 2.0 Preview 7 and new Operation Piggyback which should give some performance increase
 * 1.1a - Framework port
 * 1.2  - Changed the name to "Outline" since technically this is not Cel shading (See https://en.wikipedia.org/wiki/Cel_shading)
 *        Added custom outline and background color support
 *        Added a threshold and opacity modifier
 * 1.2a - Now uses the depth buffer linearized by ReShade therefore it should work with pseudo/logaritmic/negative/flipped depth
 *        It is now possible to use the color texture for edge detection
 *        Rewritten and simplified some parts of the code
 * 1.3  - Rewritten for ReShade 3.0 by crosire
 */

uniform int OutlineEdgeDetection <
	ui_type = "combo";
	ui_items = "Normal-depth edge detection\0Color edge detection\0";
> = 1;
uniform float OutlineAccuracy <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 100.0;
	ui_tooltip = "Edge detection accuracy.";
> = 1.0;
uniform float3 OutlineColor <
	ui_type = "color";
	ui_tooltip = "Outline color";
> = float3(0.0, 0.0, 0.0);
uniform float OutlineThreshold <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 10.0;
	ui_tooltip = "Ignores soft edges (less sharp corners) when increased.";
> = 1.0;
uniform float OutlineOpacity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Outline opacity";
> = 1.0;
uniform bool OutlineCustomBackground <
	ui_tooltip = "Uses a custom color as background when set to true.";
> = false;
uniform float3 OutlineBackgroundColor <
	ui_type = "color";
	ui_tooltip = "Background color";
> = float3(0.0, 0.0, 0.0);

#include "ReShade.fxh"

float3 GetEdgeSample(float2 coord)
{
	if (OutlineEdgeDetection)
	{
		float4 depth = float4(
			ReShade::GetLinearizedDepth(coord + ReShade::PixelSize * float2(1, 0)),
			ReShade::GetLinearizedDepth(coord - ReShade::PixelSize * float2(1, 0)),
			ReShade::GetLinearizedDepth(coord + ReShade::PixelSize * float2(0, 1)),
			ReShade::GetLinearizedDepth(coord - ReShade::PixelSize * float2(0, 1)));

		return normalize(float3(float2(depth.x - depth.y, depth.z - depth.w) * ReShade::ScreenSize, 1.0));
	}
	else
	{
		return tex2D(ReShade::BackBuffer, coord).rgb;
	}
}

float3 PS_Outline(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = OutlineCustomBackground ? OutlineBackgroundColor : tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 origcolor = color;

	// Sobel operator matrices
	const float3 Gx[3] =
	{
		float3(-1.0, 0.0, 1.0),
		float3(-2.0, 0.0, 2.0),
		float3(-1.0, 0.0, 1.0)
	};
	const float3 Gy[3] =
	{
		float3( 1.0,  2.0,  1.0),
		float3( 0.0,  0.0,  0.0),
		float3(-1.0, -2.0, -1.0)
	};
	
	float3 dotx = 0.0, doty = 0.0;
	
	// Edge detection
	for (int i = 0, j; i < 3; i++)
	{
		j = i - 1;

		dotx += Gx[i].x * GetEdgeSample(texcoord + ReShade::PixelSize * float2(-1, j));
		dotx += Gx[i].y * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 0, j));
		dotx += Gx[i].z * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 1, j));
		
		doty += Gy[i].x * GetEdgeSample(texcoord + ReShade::PixelSize * float2(-1, j));
		doty += Gy[i].y * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 0, j));
		doty += Gy[i].z * GetEdgeSample(texcoord + ReShade::PixelSize * float2( 1, j));
	}
	
	// Boost edge detection
	dotx *= OutlineAccuracy;
	doty *= OutlineAccuracy;

	// Return custom color when weight over threshold
	color = lerp(color, OutlineColor, sqrt(dot(dotx, dotx) + dot(doty, doty)) >= OutlineThreshold);
	
	// Set opacity
	color = lerp(origcolor, color, OutlineOpacity);
	
	return color;
}

technique Outline
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Outline;
	}
}
