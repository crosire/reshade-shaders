
//Gaussian Blur by Ioxa
//Version 1.0 for ReShade 3.0

//Settings

uniform int GaussianBlurRadius
<
	ui_type = "drag";
	ui_min = 1; ui_max = 3;
	ui_tooltip = "[1|2|3] Adjusts the blur radius. Higher values increase the radius";
> = 1;

uniform float GaussianBlurOffset
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Additional adjustment for the blur radius. Values less than 1.00 will reduce the radius.";
	ui_step = 0.20;
> = 1.00;

uniform float GaussianBlurStrength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of the effect.";
	ui_step = 0.10;
> = 1.00;


#define GaussianBlur_ToggleKey 0x2D //[undef] //-Default is the "Insert" key. Change to RESHADE_TOGGLE_KEY to toggle with the rest of the Framework shaders.   

#include "ReShade.fxh"

texture GaussianBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler GaussianBlurSampler { Texture = GaussianBlurTex;};

//compute Sigma 

#define GaussSigma 2
#define Sigma1 0.39894*exp(-0.5*0*0/(GaussSigma*GaussSigma))/GaussSigma
#define Sigma2 0.39894*exp(-0.5*1*1/(GaussSigma*GaussSigma))/GaussSigma
#define Sigma3 0.39894*exp(-0.5*2*2/(GaussSigma*GaussSigma))/GaussSigma
#define Sigma4 0.39894*exp(-0.5*3*3/(GaussSigma*GaussSigma))/GaussSigma
#define Sigma5 0.39894*exp(-0.5*4*4/(GaussSigma*GaussSigma))/GaussSigma
#define Sigma6 0.39894*exp(-0.5*5*5/(GaussSigma*GaussSigma))/GaussSigma
#define Sigma7 0.39894*exp(-0.5*6*6/(GaussSigma*GaussSigma))/GaussSigma

#define GaussWeight1 (Sigma1)
#define GaussOffset1 (0.0)

#define GaussWeight2 (Sigma2 + Sigma3)
#define GaussOffset2 ((Sigma2*1.0)+(Sigma3*2.0))/GaussWeight2

#define GaussWeight3 (Sigma4 + Sigma5 )
#define GaussOffset3 ((Sigma4*3.0)+(Sigma5*4.0))/GaussWeight3

#define GaussWeight4 (Sigma6 + Sigma7)
#define GaussOffset4 ((Sigma6*5.0)+(Sigma7*6.0))/GaussWeight4

#define GaussSigmaA 4
#define SigmaA1 0.39894*exp(-0.5*0*0/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA2 0.39894*exp(-0.5*1*1/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA3 0.39894*exp(-0.5*2*2/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA4 0.39894*exp(-0.5*3*3/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA5 0.39894*exp(-0.5*4*4/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA6 0.39894*exp(-0.5*5*5/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA7 0.39894*exp(-0.5*6*6/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA8 0.39894*exp(-0.5*7*7/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA9 0.39894*exp(-0.5*8*8/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA10 0.39894*exp(-0.5*9*9/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA11 0.39894*exp(-0.5*10*10/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA12 0.39894*exp(-0.5*11*11/(GaussSigmaA*GaussSigmaA))/GaussSigmaA
#define SigmaA13 0.39894*exp(-0.5*12*12/(GaussSigmaA*GaussSigmaA))/GaussSigmaA

#define GaussWeightA1 (SigmaA1)
#define GaussOffsetA1 (0.0)

#define GaussWeightA2 (SigmaA2 + SigmaA3)
#define GaussOffsetA2 ((SigmaA2*1.0)+(SigmaA3*2.0))/GaussWeightA2

#define GaussWeightA3 (SigmaA4 + SigmaA5 )
#define GaussOffsetA3 ((SigmaA4*3.0)+(SigmaA5*4.0))/GaussWeightA3

#define GaussWeightA4 (SigmaA6 + SigmaA7)
#define GaussOffsetA4 ((SigmaA6*5.0)+(SigmaA7*6.0))/GaussWeightA4

#define GaussWeightA5 (SigmaA8 + SigmaA9)
#define GaussOffsetA5 ((SigmaA8*7.0)+(SigmaA9*8.0))/GaussWeightA5

#define GaussWeightA6 (SigmaA10 + SigmaA11)
#define GaussOffsetA6 ((SigmaA10*9.0)+(SigmaA11*10.0))/GaussWeightA6

#define GaussWeightA7 (SigmaA12 + SigmaA13)
#define GaussOffsetA7 ((SigmaA12*11.0)+(SigmaA13*12.0))/GaussWeightA7

#define GaussSigmaB 6
#define SigmaB1 0.39894*exp(-0.5*0*0/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB2 0.39894*exp(-0.5*1*1/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB3 0.39894*exp(-0.5*2*2/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB4 0.39894*exp(-0.5*3*3/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB5 0.39894*exp(-0.5*4*4/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB6 0.39894*exp(-0.5*5*5/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB7 0.39894*exp(-0.5*6*6/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB8 0.39894*exp(-0.5*7*7/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB9 0.39894*exp(-0.5*8*8/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB10 0.39894*exp(-0.5*9*9/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB11 0.39894*exp(-0.5*10*10/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB12 0.39894*exp(-0.5*11*11/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB13 0.39894*exp(-0.5*12*12/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB14 0.39894*exp(-0.5*13*13/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB15 0.39894*exp(-0.5*14*14/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB16 0.39894*exp(-0.5*15*15/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB17 0.39894*exp(-0.5*16*16/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB18 0.39894*exp(-0.5*17*17/(GaussSigmaB*GaussSigmaB))/GaussSigmaB
#define SigmaB19 0.39894*exp(-0.5*18*18/(GaussSigmaB*GaussSigmaB))/GaussSigmaB

#define GaussWeightB1 (SigmaB1)
#define GaussOffsetB1 (0.0)

#define GaussWeightB2 (SigmaB2 + SigmaB3)
#define GaussOffsetB2 ((SigmaB2*1.0)+(SigmaB3*2.0))/GaussWeightB2

#define GaussWeightB3 (SigmaB4 + SigmaB5 )
#define GaussOffsetB3 ((SigmaB4*3.0)+(SigmaB5*4.0))/GaussWeightB3

#define GaussWeightB4 (SigmaB6 + SigmaB7)
#define GaussOffsetB4 ((SigmaB6*5.0)+(SigmaB7*6.0))/GaussWeightB4

#define GaussWeightB5 (SigmaB8 + SigmaB9)
#define GaussOffsetB5 ((SigmaB8*7.0)+(SigmaB9*8.0))/GaussWeightB5

#define GaussWeightB6 (SigmaB10 + SigmaB11)
#define GaussOffsetB6 ((SigmaB10*9.0)+(SigmaB11*10.0))/GaussWeightB6

#define GaussWeightB7 (SigmaB12 + SigmaB13)
#define GaussOffsetB7 ((SigmaB12*11.0)+(SigmaB13*12.0))/GaussWeightB7

#define GaussWeightB8 (SigmaB14 + SigmaB15)
#define GaussOffsetB8 ((SigmaB14*13.0)+(SigmaB15*14.0))/GaussWeightB8


#define GaussWeightB9 (SigmaB16 + SigmaB17)
#define GaussOffsetB9 ((SigmaB16*15.0)+(SigmaB17*16.0))/GaussWeightB9

#define GaussWeightB10 (SigmaB18 + SigmaB19)
#define GaussOffsetB10 ((SigmaB18*17.0)+(SigmaB19*18.0))/GaussWeightB10

float3 GaussianBlurFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(GaussianBlurSampler, texcoord).rgb;
	
	switch(GaussianBlurRadius)
	{
		case 1:
			{
				color *= GaussWeight1;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffset2 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeight2;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffset2 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeight2;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffset3 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeight3;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffset3 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeight3;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffset4 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeight4;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffset4 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeight4;
				break;
			}
		case 2:
			{
				color *= GaussWeightA1;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetA2 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA2;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetA2 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA2;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetA3 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA3;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetA3 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA3;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetA4 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA4;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetA4 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA4;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetA5 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA5;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetA5 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA5;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetA6 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA6;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetA6 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA6;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetA7 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA7;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetA7 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightA7;
				break;
			}
		case 3:
			{
				color *= GaussWeightB1;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB2 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB2;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB2 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB2;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB3 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB3;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB3 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB3;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB4 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB4;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB4 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB4;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB5 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB5;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB5 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB5;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB6 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB6;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB6 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB6;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB7 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB7;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB7 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB7;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB8 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB8;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB8 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB8;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB9 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB9;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB9 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB9;
				color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, GaussOffsetB10 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB10;
				color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, GaussOffsetB10 * ReShade::PixelSize.y) * GaussianBlurOffset).rgb * GaussWeightB10;
				break;
			}
	}
	
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	orig = lerp(orig, color, GaussianBlurStrength);

	return saturate(orig);
}

float3 GaussianBlur1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	switch(GaussianBlurRadius)
	{
		case 1:
			{
				color *= GaussWeight1;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffset2 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeight2;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffset2 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeight2;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffset3 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeight3;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffset3 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeight3;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffset4 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeight4;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffset4 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeight4;
				break;
			}
		case 2:
			{
				color *= GaussWeightA1;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetA2 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA2;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetA2 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA2;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetA3 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA3;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetA3 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA3;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetA4 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA4;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetA4 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA4;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetA5 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA5;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetA5 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA5;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetA6 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA6;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetA6 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA6;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetA7 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA7;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetA7 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightA7;
				break;
			}
		case 3:
			{
				color *= GaussWeightB1;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB2 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB2;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB2 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB2;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB3 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB3;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB3 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB3;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB4 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB4;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB4 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB4;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB5 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB5;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB5 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB5;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB6 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB6;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB6 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB6;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB7 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB7;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB7 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB7;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB8 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB8;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB8 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB8;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB9 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB9;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB9 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB9;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(GaussOffsetB10 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB10;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(GaussOffsetB10 * ReShade::PixelSize.x, 0.0) * GaussianBlurOffset).rgb * GaussWeightB10;
				
				break;
			}
	}
	
	return saturate(color);
}

technique GaussianBlur <bool enabled = true; int toggle = GaussianBlur_ToggleKey; >
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
