#ifndef INCLUDE_GUARD_GANOSSA_BRIGHTDETECT
#define INCLUDE_GUARD_GANOSSA_BRIGHTDETECT

#include "Common.fx"
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

#define xSprint BUFFER_WIDTH/192f
#define ySprint BUFFER_HEIGHT/108f

namespace Ganossa
{
texture2D detectIntTex { Width = 32; Height = 32; Format = RGBA8; };
sampler2D detectIntColor { Texture = detectIntTex; };

texture2D detectLowTex { Width = 1; Height = 1; Format = RGBA8; };
sampler2D detectLowColor { Texture = detectLowTex; };

void PS_AL_DetectInt(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectInt : SV_Target0)
{
	detectInt = tex2D(ReShade::BackBuffer,texcoord);
}

void PS_AL_DetectLow(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectLow : SV_Target0)
{
	detectLow = float4(0,0,0,0);	
	if(texcoord.x != 0.5 && texcoord.y != 0.5)
	discard;
	[loop]
	for (float i = 0.0; i <= 1; i+=0.03125)
	{	[unroll]
		for ( float j = 0.0; j <= 1; j+=0.03125 )
		{
			detectLow.xyz += tex2D(detectIntColor,float2(i,j)).xyz;
		}
	}
	detectLow.xyz /= 32*32;
}
#undef xSprint
#undef ySprint

technique Utility_Tech <bool enabled = RFX_Start_Enabled; int toggle = AmbientLight_ToggleKey; >
{
	pass AL_DetectInt
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_DetectInt;
		RenderTarget = detectIntTex;
	}

	pass AL_DetectLow
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_AL_DetectLow;
		RenderTarget = detectLowTex;
	}
}

}

#endif