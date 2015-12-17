#ifndef INCLUDE_GUARD_GANOSSA_COMMON
#define INCLUDE_GUARD_GANOSSA_COMMON

//Stuff all/most of Ganossa shared shaders need

#define Ganossa_SETTINGS_DEF "ReShade/Ganossa.cfg"
#define Ganossa_SETTINGS_UNDEF "ReShade/Ganossa.undef" 

#include Ganossa_SETTINGS_DEF

#if USE_TUNINGPALETTE && ( TuningColorMap || ( TuningColorLUT && TuningColorLUTTileAmountZ > 1 ))
	#define USE_AL_DETECTLOW 1
#else 
	#define USE_AL_DETECTLOW 0
#endif

#if (AL_Adaptation && USE_AMBIENT_LIGHT) || USE_AL_DETECTLOW
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
#if AL_HQAdapt
texture2D detectIntTex { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = RGBA8; };
sampler2D detectIntColor { Texture = detectIntTex; };
#else
texture2D detectIntTex { Width = 32; Height = 32; Format = RGBA8; };
sampler2D detectIntColor { Texture = detectIntTex; };
#endif
texture2D detectLowTex { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = RGBA8; };
sampler2D detectLowColor { Texture = detectLowTex; };

void PS_AL_DetectInt(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectInt : SV_Target0)
{
	detectInt = tex2D(RFX_backbufferColor,texcoord);
}

void PS_AL_DetectLow(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectLow : SV_Target0)
{
	detectLow = float4(0,0,0,0);	
#if AL_HQAdapt	
	if(!(texcoord.x <= BUFFER_RCP_WIDTH*2 && texcoord.y <= BUFFER_RCP_HEIGHT*2))
	discard;

	float2 coord = float2(0.0,0.0);
	[loop]
	for (float i = 2.0f; i < BUFFER_WIDTH/2; i=i+xSprint)
	{
		coord.x = BUFFER_RCP_WIDTH*i*2;
		[unroll]
		for (float j = 2.0f; j < BUFFER_HEIGHT/2; j=j+ySprint )
		{
			coord.y = BUFFER_RCP_HEIGHT*j*2;
			detectLow.xyz += tex2D(detectIntColor, coord).xyz;
		}
	}
	detectLow.xyz /= 20736f;
#else
	if(!(texcoord.x <= BUFFER_RCP_WIDTH*2 && texcoord.y <= BUFFER_RCP_HEIGHT*2))
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
#endif
}
#undef xSprint
#undef ySprint

technique Utility_Tech <bool enabled = RFX_Start_Enabled; int toggle = AmbientLight_ToggleKey; >
{
	pass AL_DetectInt
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_DetectInt;
		RenderTarget = detectIntTex;
	}

	pass AL_DetectLow
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_AL_DetectLow;
		RenderTarget = detectLowTex;
	}
}

}

#endif

#include Ganossa_SETTINGS_UNDEF

#pragma message "Ganossa 1.502.11.1\n"

#endif
