// Edge Detection for OBS Studio /Reshade
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit https://github.com/Oncorporation/reshade-shaders news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// originally from Andersama (https://github.com/Andersama)
// Modified and improved my Charles Fettinger (https://github.com/Oncorporation)  1/2019
// Surn Predator Thermal Vision LUT shader 1.0 for ReShade 3.0
// Copyright © 20019 Charles Fettinger
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//uniform float rand_f;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShadeUI.fxh"

uniform float sensitivity < __UNIFORM_SLIDER_FLOAT1
	ui_min = -2.00; ui_max = 2.00;
	ui_label = "Sensitivity";
	ui_tooltip = "'sensativity' - 0.01 is max and will create the most edges. Increasing this value decreases the number of edges detected.";
> = 0.07;

uniform bool invert_edge <
	ui_label = "Invert Edge";
	ui_tooltip = "flips the sensativity and is great for testing and fine tuning.";
> = false;

uniform float3 Edge_Color <
	ui_category = "Adjustments";
	ui_label = "Edge Color";
	ui_type= "color";
	ui_tooltip = "Specifies the color edges to recolor vs the original image.";
> = float3(1.0,1.0,1.0);

uniform bool edge_multiply <
	ui_label = "Edge Multiply";
	ui_tooltip = "multiplies the color against the original color giving it a tint instead of replacing the color. White represents no tint.";
> = false;

uniform float3 Non_Edge_Color <
	ui_category = "Adjustments";
	ui_label = "Non Edge Color";
	ui_type= "color";
	ui_tooltip = "Specifies the color of the areas between edges to recolor vs the original image.";
> = float3(0.0,0.0,0.0);

uniform bool non_edge_multiply <
	ui_label = "Non Edge Multiply";
	ui_tooltip = "multiplies the color against the original color giving it a tint instead of replacing the color. White represents no tint.";
> = false;

uniform bool alpha_channel <
	ui_label = "Alpha Channel";
	ui_tooltip = "use an alpha channel to replace original color with transparency.";
> = false;

uniform float alpha_level < __UNIFORM_SLIDER_FLOAT1
	ui_min = -2.00; ui_max = 2.00;
	ui_label = "Alpha Level";
	ui_tooltip = "transparency amount modifier where 1.0 = base luminance  (recommend 0.00 - 2.00).";
> = 1.00;

uniform bool alpha_invert <
	ui_label = "Alpha Invert";
	ui_tooltip = "flip what is transparent from darks (default) to lights";
> = false;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float4 PS_Edge_Detection(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{

	float4 color = tex2D(ReShade::BackBuffer, texcoord);
	float4 edge_color = float4(Edge_Color, 1.0);
	float4 non_edge_color = float4(Non_Edge_Color, 1.0);
	
	const float s = 3;
    const float hstep = ReShade::PixelSize.x;
    const float vstep = ReShade::PixelSize.y;
	
	float offsetx = (hstep * (float)s) / 2.0;
	float offsety = (vstep * (float)s) / 2.0;
	
	float4 lum = float4(0.30, 0.59, 0.11, 1 );
	float samples[9];
	
	int index = 0;
	for(int i = 0; i < s; i++){
		for(int j = 0; j < s; j++){
			samples[index] = dot(tex2D(ReShade::BackBuffer, float2(texcoord.x + (i * hstep) - offsetx, texcoord.y + (j * vstep) - offsety )), lum);
			index++;
		}
	}
	
	float vert = samples[2] + samples[8] + (2 * samples[5]) - samples[0] - (2 * samples[3]) - samples[6];
	float hori = samples[6] + (2 * samples[7]) + samples[8] - samples[0] - (2 * samples[1]) - samples[2];
	float4 col;
	
	float o = ((vert * vert) + (hori * hori));
	bool isEdge = o > sensitivity;
	if(invert_edge){
		isEdge = !isEdge;
	}
	if(isEdge) {
		col = edge_color;
		if(edge_multiply){
			col *= color;
		}
	} else {
		col = non_edge_color;
		if(non_edge_multiply){
			col *= color;
		}
	}

	if (alpha_invert) {
		lum = 1.0 - lum;
	}

	if(alpha_channel){
		if (edge_multiply && isEdge) {
			return float4(col.r,col.g,col.b,clamp(dot(color,lum )* alpha_level,0.0,1.0));
		} else {
			// use max instead of multiply
			return float4(max(color.r, col.r),max(color.g,col.g),max(color.b, col.b),clamp(dot(color,lum ) * alpha_level,0.0,1.0));
		}
	} else {
		// col.a = col.a * alpha_level;
		return col;
	}
}

technique Edge_Detection < ui_label = "Edge Detection"; >
{
	pass Edge_Detection_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Edge_Detection;
	}
}