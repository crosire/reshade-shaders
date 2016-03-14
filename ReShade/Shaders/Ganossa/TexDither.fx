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

#include EFFECT_CONFIG(Ganossa)

#if USE_TEXDITHER

#pragma message "TexDither by Ganossa\n"

namespace Ganossa
{

texture TexDitherTex	< string source = "ReShade/Shaders/Ganossa/Textures/TexDither.png"; > {Width = 8; Height = 8; Format = RGBA8;};
sampler	TexDitherColor 
	{ 
	Texture = TexDitherTex; 	
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = REPEAT;
	AddressV = REPEAT;
	};

float4 PS_TexDither(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{    
   	float3 texDitherRes = tex2D(ReShade::BackBuffer, floor(texcoord*100.0*fTexDitherSize)/(100.0*fTexDitherSize)).rgb;
	texDitherRes += (tex2D(TexDitherColor, texcoord*fTexDitherSize*8.0).r-0.5)*float3(1.0/16.0,1.0/16.0,1.0/16.0);
    	return float4(texDitherRes, 1);
}

technique TexDither_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = TexDither_ToggleKey; >
{
	pass TexDitherPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_TexDither;
	}
}

}

#endif

#include EFFECT_CONFIG_UNDEF(Ganossa)
