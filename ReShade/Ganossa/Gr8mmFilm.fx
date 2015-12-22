#include "Common.fx"
#include Ganossa_SETTINGS_DEF

#if USE_GR8MMFILM

/**
 * Copyright (C) 2015 Ganossa (mediehawk@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software with restriction, including without limitation the rights to
 * use and/or sell copies of the Software, and to permit persons to whom the Software 
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and below) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "Software"), to deal in the Software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the Software, and subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

namespace Ganossa
{

#define Ganossa_Gr8mmFilm_TY Gr8mmFilmTextureSizeY/Gr8mmFilmTileAmount
#define Ganossa_Gr8mmFilm_VP Gr8mmFilmVignettePower*0.65f
#define Ganossa_Gr8mmFilm_AP Gr8mmFilmAlphaPower/3f

uniform float2 filmroll < source = "pingpong"; min = 0.0f; max = (Gr8mmFilmTileAmount-Gr8mmFilmBlackFrameMix)/**speed*/; step = float2(1.0f, 2.0f); >;

texture Gr8mmFilmTex	< string source = "ReShade/Ganossa/Textures/" Gr8mmFilmTexture; > {Width = Gr8mmFilmTextureSizeX; Height = Gr8mmFilmTextureSizeY; Format = RGBA8;};
sampler	Gr8mmFilmColor 	{ Texture = Gr8mmFilmTex; };

float4 PS_Gr8mmFilm(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 original = tex2D(ReShade::BackBuffer, texcoord);
	float4 singleGr8mmFilm = tex2D(Gr8mmFilmColor, float2(texcoord.x, texcoord.y/Gr8mmFilmTileAmount + (Ganossa_Gr8mmFilm_TY/Gr8mmFilmTextureSizeY)* 
#if Gr8mmFilmScroll
filmroll.x
#else
trunc(filmroll.x/* / speed*/) 
#endif
));
	float alpha = max(0.0f,min(1.0f,max(abs(texcoord.x-0.5f),abs(texcoord.y-0.5f))*Gr8mmFilmVignettePower + 0.75f - (singleGr8mmFilm.x+singleGr8mmFilm.y+singleGr8mmFilm.z)*Ganossa_Gr8mmFilm_AP));
	return lerp(original, singleGr8mmFilm, Gr8mmFilmPower*pow(alpha,2));
}

technique Gr8mmFilm_Tech <bool enabled = RFX_Start_Enabled; int toggle = Gr8mmFilm_ToggleKey; >
{
	pass Gr8mmFilmPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Gr8mmFilm;
	}
}

}

#endif

#include Ganossa_SETTINGS_UNDEF
