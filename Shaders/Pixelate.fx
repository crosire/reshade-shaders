//Pixelate by sYNTHwAVE88
//Version 1.0 for ReShade

uniform int cell_size
<
	ui_type		= "slider";
	ui_min		= 2;
	ui_max		= 48;
	ui_label	= "Cell Size";
> = 4;

uniform float avg_amount
<
	ui_type		= "slider";
	ui_min		= 0.0;
	ui_max		= 1.0;
	ui_label	= "Smoothness";
> = 0.333;

uniform int stats
<
	ui_type		= "combo";
	ui_items	= "NO\0YES\0";
	ui_label	= "Display Stats";
> = 0;

#include "ReShade.fxh"
#include "DrawText.fxh"
#define get_pixel(x) tex2D(ReShade::BackBuffer, ((x) + 0.5) * ReShade::PixelSize)

void PixelatePass(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	int2 pixcoord = floor((ReShade::ScreenSize * texcoord) / cell_size) * cell_size;
	color = get_pixel(pixcoord);

	if(avg_amount > 0.1)
	{
		float step = cell_size * 0.25;
		float4 avg_color = 0.0;

		for( int x = 0 ; x < 4 ; ++x )
			for( int y = 0 ; y < 4 ; ++y )
				avg_color += get_pixel(float2(pixcoord.x + (x * step), pixcoord.y + (y * step)));

		avg_color *= 0.0625;
		color = (avg_color * avg_amount) + (color * (1.0 - avg_amount));
	}

	if(stats)
	{
		DrawText_Digit(float2(ReShade::ScreenSize.x - 256, 128), 64, 1, texcoord, -1, (ReShade::ScreenSize.x / cell_size), color);
		DrawText_Digit(float2(ReShade::ScreenSize.x - 256, 192), 64, 1, texcoord, -1, (ReShade::ScreenSize.y / cell_size), color);
	}
}

technique Pixelate
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PixelatePass;
	}
}
