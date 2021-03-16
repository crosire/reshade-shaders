
//Gaussian Blur by Ioxa
//Version 1.1 for ReShade 3.0

//Settings

#include "ReShadeUI.fxh"

uniform int GaussianBlurTaps < __UNIFORM_SLIDER_INT1
	ui_min = 0; ui_max = 4;
	ui_tooltip = "[0|1|2|3|4] Adjusts the number of taps. 0 - 7 taps, 1 - 11 taps, 2 - 21 taps, 3 - 29 taps, 4 - 35 taps";
> = 1;

uniform float GaussianBlurKernelWidthX < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 11.567;
	ui_tooltip = "Adjusts the gaussian kernel width in the X axis.";
> = 2.777;

uniform float GaussianBlurKernelWidthY < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 11.567;
	ui_tooltip = "Adjusts the gaussian kernel width in the Y axis.";
> = 2.777;

uniform float GaussianBlurStrength < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of the effect.";
> = 0.300;

#include "ReShade.fxh"

texture GaussianBlurTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler GaussianBlurSampler { Texture = GaussianBlurTex;};

float3 GaussianBlurFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

float3 color = tex2D(GaussianBlurSampler, texcoord).rgb;

if(GaussianBlurTaps == 0)	
{
	float offset[4] = { 0.0, 1.464892229860, 3.752977129974, 6.199480064362 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
		color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
	}
}	

if(GaussianBlurTaps == 1)	
{
	float offset[6] = { 0.0, 0.525192450062, 1.225802892806, 1.927229226733, 2.629848945809, 3.333939367578 };
	float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
		color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
	}
}	

if(GaussianBlurTaps == 2)	
{
	float offset[11] = { 0.0, 0.258245007859, 0.602574391468, 0.946910254048, 1.291256250958, 1.635615975647, 1.979992938314, 2.324390545639, 2.668812081924, 3.013260691528, 3.357739363231 };
	float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
		color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
	}
}	

if(GaussianBlurTaps == 3)	
{
	float offset[15] = { 0.0, 0.171497579991, 0.400161177289, 0.628825151971, 0.857489719143, 1.086155093163, 1.314821487461, 1.543489114194, 1.772158184029, 2.000828905900, 2.229501486756, 2.458176131324, 2.686853041851, 2.915532417915, 3.144214456165 };
	float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
		color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
	}
}

if(GaussianBlurTaps == 4)	
{
	float offset[18] = { 0.0, 0.129283051016, 0.301660570959, 0.474038375393, 0.646416626474, 0.818795485795, 0.991175114250, 1.163555671774, 1.335937317176, 1.508320207961, 1.682960441166, 1.855572827605, 2.028185522994, 2.200798555567, 2.373411953459, 2.546025744645, 2.718639956965, 2.891254618102 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
		color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y) * GaussianBlurKernelWidthY).rgb * weight[i];
	}
}		

	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	orig = lerp(orig, color, GaussianBlurStrength);

	return saturate(orig);
}

float3 GaussianBlur1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

if(GaussianBlurTaps == 0)	
{
	float offset[4] = { 0.0, 1.464892229860, 3.752977129974, 6.199480064362 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
	}
}	

if(GaussianBlurTaps == 1)	
{
	float offset[6] = { 0.0, 0.525192450062, 1.225802892806, 1.927229226733, 2.629848945809, 3.333939367578 };
	float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
	}
}	

if(GaussianBlurTaps == 2)	
{
	float offset[11] = { 0.0, 0.258245007859, 0.602574391468, 0.946910254048, 1.291256250958, 1.635615975647, 1.979992938314, 2.324390545639, 2.668812081924, 3.013260691528, 3.357739363231 };
	float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
	}
}	

if(GaussianBlurTaps == 3)	
{
	float offset[15] = { 0.0, 0.171497579991, 0.400161177289, 0.628825151971, 0.857489719143, 1.086155093163, 1.314821487461, 1.543489114194, 1.772158184029, 2.000828905900, 2.229501486756, 2.458176131324, 2.686853041851, 2.915532417915, 3.144214456165 };
	float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
	}
}	

if(GaussianBlurTaps == 4)	
{
	float offset[18] = { 0.0, 0.129283051016, 0.301660570959, 0.474038375393, 0.646416626474, 0.818795485795, 0.991175114250, 1.163555671774, 1.335937317176, 1.508320207961, 1.682960441166, 1.855572827605, 2.028185522994, 2.200798555567, 2.373411953459, 2.546025744645, 2.718639956965, 2.891254618102 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0) * GaussianBlurKernelWidthX).rgb * weight[i];
	}
}	
	return saturate(color);
}

technique GaussianBlur
{
	pass Blur1
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianBlur1;
		RenderTarget = GaussianBlurTex;
	}
	pass BlurFinal
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianBlurFinal;
	}
}
