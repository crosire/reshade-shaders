#include "ReShade.fxh"

float4 PS_Nostalgia(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, texcoord.xy);
	float3 color = colorInput.rgb;
	float3 palette[16]; //Palette from http://www.c64-wiki.com/index.php/Color
	palette[0] =  float3(  0. ,   0. ,   0. ); //Black
	palette[1] =  float3(255. , 255. , 255. ); //White
	palette[2] =  float3(136. ,   0. ,   0. ); //Red
	palette[3] =  float3(170. , 255. , 238. ); //Cyan
	palette[4] =  float3(204. ,  68. , 204. ); //Violet
	palette[5] =  float3(  0. , 204. ,  85. ); //Green
	palette[6] =  float3(  0. ,   0. , 170. ); //Blue
	palette[7] =  float3(238. , 238. , 119. ); //Yellow
	palette[8] =  float3(221. , 136. ,  85. ); //Orange
	palette[9] =  float3(102. ,  68. ,   0. ); //Brown
	palette[10] = float3(255. , 119. , 119. ); //Yellow
	palette[11] = float3( 51. ,  51. ,  51. ); //Grey 1
	palette[12] = float3(119. , 119. , 119. ); //Grey 2
	palette[13] = float3(170. , 255. , 102. ); //Lightgreen
	palette[14] = float3(  0. , 136. , 255. ); //Lightblue
	palette[15] = float3(187. , 187. , 187. ); //Grey 3
	
	float3 diff = color;
	
	float dist = dot(diff,diff); //squared distance

	float closest_dist = dist;
	float3 closest_color = float3(0.0,0.0,0.0);
	
	for (int i = 1 ; i <= 15 ; i++) 
	{
		diff = color - (palette[i]/255.0);
	
		dist = dot(diff,diff); //squared distance
    
	if (dist < closest_dist){ //ternary would also work here
		closest_dist = dist;
		closest_color = palette[i]/255.0;
		}
	}

	colorInput.rgb = closest_color; //return the pixel
	return colorInput; //return the pixel
}

technique Nostalgia
{
	pass NostalgiaPass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Nostalgia;
	}
}