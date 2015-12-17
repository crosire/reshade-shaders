#include "Common.fx"

#ifndef RFX_duplicate
#include Ganossa_SETTINGS_DEF
#endif

#if USE_MOTION_FOCUS

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

#define Ganossa_MF_BUFFERX BUFFER_WIDTH/2
#define Ganossa_MF_BUFFERY BUFFER_HEIGHT/2

#define Ganossa_MF_BUFFERXHalf Ganossa_MF_BUFFERX/2
#define Ganossa_MF_BUFFERYHalf Ganossa_MF_BUFFERY/2

texture2D Ganossa_MF_NormTex { Width = Ganossa_MF_BUFFERX; Height = Ganossa_MF_BUFFERY; Format = RGBA8; };
texture2D Ganossa_MF_PrevTex { Width = Ganossa_MF_BUFFERX; Height = Ganossa_MF_BUFFERY; Format = RGBA8; };
texture2D Ganossa_MF_QuadFullTex { Width = Ganossa_MF_BUFFERX; Height = Ganossa_MF_BUFFERY; Format = RGBA8; };
texture2D Ganossa_MF_QuadFullPrevTex { Width = Ganossa_MF_BUFFERX; Height = Ganossa_MF_BUFFERY; Format = RGBA8; };
texture2D Ganossa_MF_QuadTex { Width = Ganossa_MF_BUFFERX; Height = Ganossa_MF_BUFFERY; Format = RGBA16F; };

sampler2D Ganossa_MF_NormColor { Texture = Ganossa_MF_NormTex; };
sampler2D Ganossa_MF_PrevColor { Texture = Ganossa_MF_PrevTex; };
sampler2D Ganossa_MF_QuadFullColor { Texture = Ganossa_MF_QuadFullTex; };
sampler2D Ganossa_MF_QuadFullPrevColor { Texture = Ganossa_MF_QuadFullPrevTex; };
sampler2D Ganossa_MF_QuadColor { Texture = Ganossa_MF_QuadTex; };

#define xSprint BUFFER_WIDTH/192f
#define ySprint BUFFER_HEIGHT/108f

void PS_MotionFocusNorm(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 normR : SV_Target0)
{
	normR = tex2D(RFX_originalColor, texcoord);
}

void PS_MotionFocusQuadFull(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 quadFullR : SV_Target0)
{
	float3 orig = tex2D(Ganossa_MF_NormColor, texcoord).rgb;
	float3 prev = tex2D(Ganossa_MF_PrevColor, texcoord).rgb;
	float diff = (abs(orig.r-prev.r)+abs(orig.g-prev.g)+abs(orig.b-prev.b))/3f;

	float3 quadFullPrev = tex2D(Ganossa_MF_QuadFullPrevColor,texcoord).rgb;

	float3 quadFull = 0.968*quadFullPrev + float3(diff,diff,diff);

	float3 quadFulldiff = float3(abs(quadFull.r-quadFullPrev.r),abs(quadFull.g-quadFullPrev.g),abs(quadFull.b-quadFullPrev.b));

	quadFullR = float4((0.978-0.2*max(1.0f-pow(1.0f-quadFulldiff,2)*100000f,0))*quadFullPrev + float3(diff,diff,diff),1);

}

void PS_MotionFocusStorage(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 prevR : SV_Target0, out float4 prevQuadFullR : SV_Target1)
{
	prevR = tex2D(Ganossa_MF_NormColor, texcoord);
	prevQuadFullR = tex2D(Ganossa_MF_QuadFullColor, texcoord);
}

void PS_MotionFocus(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 quadR : SV_Target0)
{
	quadR = float4(0,0,0,0);

	if (!(texcoord.x <= BUFFER_RCP_WIDTH*2 && texcoord.y <= BUFFER_RCP_HEIGHT*2)) 
	discard;

	float2 coord = float2(0.0,0.0);
	[loop]
	for (float i = 2.0f; i < Ganossa_MF_BUFFERX; i=i+xSprint)
	{
		coord.x = BUFFER_RCP_WIDTH*i*2;
		[unroll]
		for (float j = 2.0f; j < Ganossa_MF_BUFFERY; j=j+ySprint )
		{
			coord.y = BUFFER_RCP_HEIGHT*j*2;
			float3 quadFull = tex2D(Ganossa_MF_QuadFullColor, coord).xyz;
			float quadFullPow = quadFull.x+quadFull.y+quadFull.z;
			[flatten]
			if(i < Ganossa_MF_BUFFERXHalf && j < Ganossa_MF_BUFFERYHalf)
			quadR.x += quadFullPow;
			else [flatten]if(i > Ganossa_MF_BUFFERXHalf && j < Ganossa_MF_BUFFERYHalf)
			quadR.y += quadFullPow;
			else [flatten]if(i < Ganossa_MF_BUFFERXHalf && j > Ganossa_MF_BUFFERYHalf)
			quadR.z += quadFullPow;
			else
			quadR.w += quadFullPow;
		}
	}
	quadR.xyzw /= 5184f;
}

float4 PS_MotionFocusDisplay(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 Ganossa_MF_Quad = max(0,tex2D(Ganossa_MF_QuadColor, float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT))-0.1f);

#if mfDebug
//debug
	if(texcoord.y < 0.01f) if(texcoord.x > Ganossa_MF_Quad.x-0.01f && texcoord.x < Ganossa_MF_Quad.x+0.01f) return float4(1,0,0,0);
	if(texcoord.y > 0.01f && texcoord.y < 0.02f) if(texcoord.x > Ganossa_MF_Quad.y-0.01f && texcoord.x < Ganossa_MF_Quad.y+0.01f) return float4(0,1,0,0);
	if(texcoord.y > 0.02f && texcoord.y < 0.03f) if(texcoord.x > Ganossa_MF_Quad.z-0.01f && texcoord.x < Ganossa_MF_Quad.z+0.01f) return float4(0,0,1,0);
	if(texcoord.y > 0.03f && texcoord.y < 0.04f) if(texcoord.x > Ganossa_MF_Quad.w-0.01f && texcoord.x < Ganossa_MF_Quad.w+0.01f) return float4(1,1,0,0);
//debug
#endif
	float2 focus = 0.5f + float2(max(min(0.5,(Ganossa_MF_Quad.y + Ganossa_MF_Quad.w - Ganossa_MF_Quad.x - Ganossa_MF_Quad.z)/2f),-1.0),max(min(0.5,(Ganossa_MF_Quad.z + Ganossa_MF_Quad.w - Ganossa_MF_Quad.x - Ganossa_MF_Quad.y)/2f),-0.5));
	
	float focusPow = max(Ganossa_MF_Quad.x,max(Ganossa_MF_Quad.y,max(Ganossa_MF_Quad.z,Ganossa_MF_Quad.w)));	

	float focusPowDiff = 1.0f;
	[branch]if (focusPow == Ganossa_MF_Quad.x) focusPowDiff += Ganossa_MF_Quad.x-(Ganossa_MF_Quad.y + Ganossa_MF_Quad.z + Ganossa_MF_Quad.w)/3f;
	else [branch]if(focusPow == Ganossa_MF_Quad.y) focusPowDiff += Ganossa_MF_Quad.y-(Ganossa_MF_Quad.x + Ganossa_MF_Quad.z + Ganossa_MF_Quad.w)/3f;
	else [branch]if(focusPow == Ganossa_MF_Quad.z) focusPowDiff += Ganossa_MF_Quad.z-(Ganossa_MF_Quad.x + Ganossa_MF_Quad.y + Ganossa_MF_Quad.w)/3f;
	else focusPowDiff += Ganossa_MF_Quad.w-(Ganossa_MF_Quad.y + Ganossa_MF_Quad.z + Ganossa_MF_Quad.x)/3f;

	float focusPowFull = 0.5f*max(1.0f,min(2.0f - pow((Ganossa_MF_Quad.x + Ganossa_MF_Quad.y + Ganossa_MF_Quad.z + Ganossa_MF_Quad.w)/4f,3),1.0f));

#if mfDebug
//debug
	if(texcoord.x < 0.5025f && texcoord.x > 0.4975f && texcoord.y < 0.505f && texcoord.y > 0.495f) return float4(0,1,0,0);
	if(texcoord.x > pow(focus.x,2)+0.25f-0.0025f && texcoord.x < pow(focus.x,2)+0.25f+0.0025f && texcoord.y > pow(focus.y,2)+0.25f-0.005f && texcoord.y < pow(focus.y,2)+0.25f+0.005f) return float4(1,0,0,0);
//debug
#endif
	float2 finalZoom = focusPow*focusPowDiff*focusPowFull*mfZoomStrength;
	float2 finalFocus = focus*focusPow*pow(focusPowDiff,3)*focusPowFull*mfFocusStrength;

	float2 focusCorrection = min(0,float2(1,1)-(float2(1,1)*(1.0f-finalZoom)+finalFocus*min(0.55,0.6*mfZoomStrength)));

	return tex2D(RFX_backbufferColor, texcoord*(1.0f-finalZoom)+finalFocus*min(0.55,0.6*mfZoomStrength)+focusCorrection);
}

technique MotionFocus_Tech <bool enabled = 
#if (MotionFocus_TimeOut > 0)
1; int toggle = MotionFocus_ToggleKey; timeout = MotionFocus_TimeOut; >
#else
RFX_Start_Enabled; int toggle = MotionFocus_ToggleKey; >
#endif
{
	pass MotionFocusNormPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_MotionFocusNorm;
		RenderTarget0 = Ganossa_MF_NormTex;
	}

	pass MotionFocusQuadFullPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_MotionFocusQuadFull;
		RenderTarget0 = Ganossa_MF_QuadFullTex;
	}
	
	pass MotionFocusPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_MotionFocus;
		RenderTarget0 = Ganossa_MF_QuadTex;
	}
	
	pass MotionFocusDisplayPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_MotionFocusDisplay;
	}

	pass MotionFocusStoragePass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_MotionFocusStorage;
		RenderTarget0 = Ganossa_MF_PrevTex;
		RenderTarget1 = Ganossa_MF_QuadFullPrevTex;
	}
}
#undef xSprint
#undef ySprint

}

#endif

#ifndef RFX_duplicate
#include Ganossa_SETTINGS_UNDEF
#endif
