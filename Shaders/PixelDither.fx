#include "ReShade.fxh"
#include "ReShadeUI.fxh"

/*
PixelDither.fx
This is a simple shader that I ported from 
a Unity project I'd been working on, after 
a friend requested it. It's simple and not 
super configurable, as is. The only option 
that can be changed in the UI is the width 
of the screen in pixels. If you want a new 
palette, just save it as a 1xN .gif in the
textures directory as palette.gif, and add 
PIXELDITHER_PALETTESIZE = N to your prepro 
directives (unless N=32, in which case you
don't have to do anything). The bigger the
palette is, the bigger the performance hit
so try to be thrifty! Using a huge palette
kinda misses the point anyway.
For best results, try increasing the gamma
and saturation before applying PixelDither
since a lot of dark-ish colors tend to map
to pure grey.
Have fun!
*/

#ifndef PIXELDITHER_PALETTESIZE
	#define PIXELDITHER_PALETTESIZE 32
#endif

uniform float _ResolutionX <
	ui_type = "input";
	ui_tooltip = "Sets the screen width in pixels. For best results, use an integer that cleanly divides your screen resolution.";
> = 480.0;

uniform texture _DitherTex < source = "./dither.png"; > {
	Width = 4;
	Height = 4;
};

uniform texture _PaletteTex < source = "./palette.gif"; > {
	Width = PIXELDITHER_PALETTESIZE;
	Height = 1;
};

sampler ditherTex{
	Texture = _DitherTex;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = REPEAT;
	AddressV = REPEAT;
};

sampler paletteTex{
	Texture = _PaletteTex;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = REPEAT;
	AddressV = REPEAT;
};

struct Colors{
	float4 col1;
	float4 col2;
};

float indexValue(float2 uv, float2 ratio) {
	float2 t = (uv) / (4 * ratio);
	float4 ret = tex2D(ditherTex, t);
	return (1.0 - float(ret.r));
}

float hueDistance(float4 col1, float4 col2) {
	float tempr = col1.r - col2.r;
	float tempg = col1.g - col2.g;
	float tempb = col1.b - col2.b; 
	return sqrt((tempr * tempr) + (tempg * tempg) + (tempb * tempb));
}

Colors closestColors(float4 color) {
	Colors ret;
	float temp[PIXELDITHER_PALETTESIZE];
	float first = 2;
	float second = 2;
	int firstIndex = 0;
	int secondIndex = 0;
	for (int i = 0; i < PIXELDITHER_PALETTESIZE; ++i) {
		temp[i] = hueDistance(color, tex2D(paletteTex, float2((i+0.5)/PIXELDITHER_PALETTESIZE, 0.5)));
	}	
	for (int i = 0; i < PIXELDITHER_PALETTESIZE; ++i) {
		if(temp[i] < first){
			second = first;
			secondIndex = firstIndex;
			first = temp[i];
			firstIndex = i;
		}
		else if(temp[i] < second){
			second = temp[i];
			secondIndex = i;
		}
	}//I'm not sure how these loops unroll or if this is an efficient way to do this, but it works with a 32 color palette.
	ret.col1 = tex2D(paletteTex, float2((firstIndex + 0.5)/PIXELDITHER_PALETTESIZE, 0.5));
	ret.col2 = tex2D(paletteTex, float2((secondIndex + 0.5)/PIXELDITHER_PALETTESIZE, 0.5));
	return ret;
}

float4 dither(float4 color, float d) {
	Colors col = closestColors(color);
	float hueDiff = hueDistance(color, col.col1);
	if(hueDiff < d)
		return col.col1;
	return col.col2;
}

float4 PS_PixelDither (float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 temp = texcoord;
	float2 ratio = float2(1/_ResolutionX, 16/(9*_ResolutionX));
	temp -= (texcoord % ratio) - (0.5/_ResolutionX);
	float4 col = tex2D(ReShade::BackBuffer, temp);
	float d = indexValue(texcoord, ratio);
	float4 finalPix = dither(col, d);
	return finalPix;
}

technique DitherPixel{
	pass DitherPixel{
		VertexShader=PostProcessVS;
		PixelShader = PS_PixelDither;
	}
}
