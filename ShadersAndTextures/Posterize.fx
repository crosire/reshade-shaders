/*=============================================================================
by Pascal Gilcher
	1) erode details with an edge aware paint filter
	2) posterize based on luma
	3) index palette

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#define NUM_PASSES 				4		
#define OUTLINE_INTENSITY		0
#define SHARPEN_INTENSITY		0.7
#define NUM_DIRS				5
#define NUM_STEPS_PER_PASS		4

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float ZEBRA_INTENSITY <
    ui_type = "drag";
    ui_label = "Zebra Lines Intensity";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.0;

uniform float3 PALETTE_COLOR_1 <
    ui_type = "color";
    ui_label = "Color 1";
> = float3(1/255.0, 48/255.0, 74/255.0);

uniform float3 PALETTE_COLOR_2 <
    ui_type = "color";
    ui_label = "Color 2";
> = float3(219/255.0, 33/255.0, 38/255.0);

uniform float3 PALETTE_COLOR_3 <
    ui_type = "color";
    ui_label = "Color 3";
> = float3(113/255.0, 153/255.0, 165/255.0);

uniform float3 PALETTE_COLOR_4 <
    ui_type = "color";
    ui_label = "Color 4";
> = float3(255/255.0, 250/255.0, 182/255.0);

/*=============================================================================
	Textures, Samplers, Globals
=============================================================================*/

#include "qUINT_common.fxh"

/*=============================================================================
	Vertex Shader
=============================================================================*/

struct VSOUT
{
	float4   vpos        : SV_Position;
    float2   uv          : TEXCOORD0;
};

VSOUT VS_Paint(in uint id : SV_VertexID)
{
    VSOUT o;
    o.uv.x = (id == 2) ? 2.0 : 0.0;
    o.uv.y = (id == 1) ? 2.0 : 0.0;       
    o.vpos = float4(o.uv.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
    return o;
}

/*=============================================================================
	Functions
=============================================================================*/

float3 paint_filter(in VSOUT i, in float pass_id)
{
	float3 least_divergent = 0;
	float3 total_sum = 0;
	float min_divergence = 1e10;

	[loop]
	for(int j = 0; j < NUM_DIRS; j++)
	{
		float2 dir; sincos(radians(180.0 * (j + pass_id / NUM_PASSES) / NUM_DIRS), dir.y, dir.x);

		float3 col_avg_per_dir = 0;
		float curr_divergence = 0;

		float3 col_prev = tex2Dlod(qUINT::sBackBufferTex, float4(i.uv.xy - dir * NUM_STEPS_PER_PASS * qUINT::PIXEL_SIZE, 0, 0)).rgb;

		for(int k = -NUM_STEPS_PER_PASS + 1; k <= NUM_STEPS_PER_PASS; k++)
		{
			float3 col_curr = tex2Dlod(qUINT::sBackBufferTex, float4(i.uv.xy + dir * k * qUINT::PIXEL_SIZE, 0, 0)).rgb;
			col_avg_per_dir += col_curr;

			float3 color_diff = abs(col_curr - col_prev);

			curr_divergence += max(max(color_diff.x, color_diff.y), color_diff.z);
			col_prev = col_curr;
		}

		[flatten]
		if(curr_divergence < min_divergence)
		{
			least_divergent = col_avg_per_dir;
			min_divergence = curr_divergence;
		}

		total_sum += col_avg_per_dir;
	}

	least_divergent /= 2 * NUM_STEPS_PER_PASS;
	total_sum /= 2 * NUM_STEPS_PER_PASS * NUM_DIRS;
	min_divergence /= 2 * NUM_STEPS_PER_PASS;

	float lumasharpen = dot(least_divergent - total_sum, 0.333);
	least_divergent += lumasharpen * SHARPEN_INTENSITY;

	least_divergent *= saturate(1 - min_divergence * OUTLINE_INTENSITY);
	return least_divergent;
}

/*=============================================================================
	Pixel Shaders
=============================================================================*/

void PS_Paint_1(in VSOUT i, out float4 o : SV_Target0)
{
	o.rgb = paint_filter(i, 1);
	o.w = 1;
}

void PS_Paint_2(in VSOUT i, out float4 o : SV_Target0)
{
	o.rgb = paint_filter(i, 2);
	o.w = 1;
}

void PS_Paint_3(in VSOUT i, out float4 o : SV_Target0)
{
	o.rgb = paint_filter(i, 3);
	o.w = 1;
}

void PS_Paint_4(in VSOUT i, out float4 o : SV_Target0)
{
	o.rgb = paint_filter(i, 4);
	o.w = 1;
}

void PS_Paint_5(in VSOUT i, out float4 o : SV_Target0)
{
	o.rgb = paint_filter(i, 5);
	o.w = 1;
}

void PS_Posterize(in VSOUT i, out float4 o : SV_Target0)
{	
	float3 color = tex2D(qUINT::sBackBufferTex, i.uv).rgb;

	bool zebra = frac(i.vpos.y * 0.125) > 0.5;

	float lum = dot(color, float3(0.3, 0.59, 0.11));
	int posterized = round(lum * 3 + (zebra - 0.5) * ZEBRA_INTENSITY * 0.2);
	posterized = clamp(posterized, 0, 3); 

	float3 palette[4] = 
	{
		PALETTE_COLOR_1, 
		PALETTE_COLOR_2,
		PALETTE_COLOR_3,
		PALETTE_COLOR_4
	};

	o = palette[posterized];


}

/*=============================================================================
	Techniques
=============================================================================*/

technique Posterize
{
	pass
	{
		VertexShader = VS_Paint;
		PixelShader  = PS_Paint_1;
	}
	pass
	{
		VertexShader = VS_Paint;
		PixelShader  = PS_Paint_2;
	}
	pass
	{
		VertexShader = VS_Paint;
		PixelShader  = PS_Paint_3;
	}
	pass
	{
		VertexShader = VS_Paint;
		PixelShader  = PS_Paint_4;
	}
	pass
	{
		VertexShader = VS_Paint;
		PixelShader  = PS_Posterize;
	}
}