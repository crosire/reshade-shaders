/** Aspect Ratio PS, version 1.0.2
by Fubax 2019 for ReShade
*/

#include "ReShadeUI.fxh"

uniform float A < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Correct proportions";
	ui_category = "Aspect ratio";
	ui_min = -1.0; ui_max = 1.0;
> = 0.0;

uniform float Zoom < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Scale image";
	ui_category = "Aspect ratio";
	ui_min = 1.0; ui_max = 1.5;
> = 1.0;

uniform bool FitScreen < __UNIFORM_INPUT_BOOL1
	ui_label = "Scale image to borders";
	ui_category = "Borders";
> = true;

uniform float3 Color < __UNIFORM_COLOR_FLOAT3
	ui_label = "Background color";
	ui_category = "Borders";
> = float3(0.027, 0.027, 0.027);

#include "ReShade.fxh"

	  //////////////
	 /// SHADER ///
	//////////////

float3 AspectRatioPS(float4 pos : SV_Position, float2 coord : TEXCOORD0) : SV_Target
{
	bool Mask = false;

	// Center coordinates
	coord -= 0.5;

	// if (Zoom != 1.0) coord /= Zoom;
	if (Zoom != 1.0) coord /= clamp(Zoom, 1.0, 1.5); // Anti-cheat

	// Squeeze horizontally
	if (A<0)
	{
		coord.x *= abs(A)+1.0; // Apply distortion

		// Scale to borders
		if (FitScreen) coord /= abs(A)+1.0;
		else // Mask image borders
			Mask = abs(coord.x)>0.5;
	}
	// Squeeze vertically
	else if (A>0)
	{
		coord.y *= A+1.0; // Apply distortion

		// Scale to borders
		if (FitScreen) coord /= abs(A)+1.0;
		else // Mask image borders
			Mask = abs(coord.y)>0.5;
	}
	
	// Coordinates back to the corner
	coord += 0.5;

	// Sample display image and return
	return Mask? Color : tex2D(ReShade::BackBuffer, coord).rgb;
}


	  ///////////////
	 /// DISPLAY ///
	///////////////

technique AspectRatioPS
<
	ui_label = "Aspect Ratio";
	ui_tooltip = "Correct image aspect ratio";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AspectRatioPS;
	}
}
