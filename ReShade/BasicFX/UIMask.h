NAMESPACE_ENTER(BFX)

#include BFX_SETTINGS_DEF

#if USE_UIMask

/**
 * Copyright (C) 2015 Lucifer Hawk (mediehawk@gmail.com)
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

//UI Mask Shader

const static int uiTolHigh = pow(2,UIMask_Tolerance);
const static int uiTolLow = pow(2,int(max(0f,UIMask_Tolerance-(2*UIMask_Tolerance)/5)));

texture uiMaskTex < source = "ReShade/BasicFX/Textures/uiMask.png"; > { Width = 1920; Height = 1080; MipLevels = 1; Format = RGBA8; };
sampler uiMaskColor { Texture = uiMaskTex; };

texture2D uiMaskPrevTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F; };
sampler2D uiMaskPrevColor { Texture = uiMaskPrevTex; };

texture2D uiMaskFinalTexLowPing { Width = BUFFER_WIDTH/uiTolHigh; Height = BUFFER_HEIGHT/uiTolHigh; Format = RGBA8; };
sampler2D uiMaskFinalColorLowPing { Texture = uiMaskFinalTexLowPing; };

texture2D uiMaskFinalTexLowPong { Width = BUFFER_WIDTH/uiTolHigh; Height = BUFFER_HEIGHT/uiTolHigh; Format = RGBA8; };
sampler2D uiMaskFinalColorLowPong { Texture = uiMaskFinalTexLowPong; };

texture2D uiMaskFinalTexHighPing { Width = BUFFER_WIDTH/uiTolLow; Height = BUFFER_HEIGHT/uiTolLow; Format = RGBA8; };
sampler2D uiMaskFinalColorHighPing { Texture = uiMaskFinalTexHighPing; };

texture2D uiMaskFinalTexHighPong { Width = BUFFER_WIDTH/uiTolLow; Height = BUFFER_HEIGHT/uiTolLow; Format = RGBA8; };
sampler2D uiMaskFinalColorHighPong { Texture = uiMaskFinalTexHighPong; };

texture2D uiMaskFinalStartTex { Width = 1; Height = 1; Format = RGBA32F; };
sampler2D uiMaskFinalStartColor { Texture = uiMaskFinalStartTex; };

float4 PS_UIMask(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	#if UIMask_Direct 
		return lerp(tex2D(RFX_originalColor, texcoord), tex2D(RFX_backbufferColor, texcoord), tex2D(uiMaskFinalColorHighPong, texcoord).r); 
	#else
		return lerp(tex2D(RFX_originalColor, texcoord), tex2D(RFX_backbufferColor, texcoord), tex2D(uiMaskColor, texcoord).r); 
	#endif
}


void PS_UIMaskHelperComparePing(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 finalR : SV_Target0)
{
	finalR = tex2D(uiMaskFinalColorLowPong,texcoord);//lerp(float4(0,0,0,0),float4(1,1,1,1),diff);
}

void PS_UIMaskHelperComparePong(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 finalR : SV_Target0)
{
	float diff = 0;
	if(tex2D(uiMaskFinalStartColor,float2(0,0)).r != 0) {
		float3 ori = tex2D(RFX_originalColor, texcoord).rgb;
		float3 prev = tex2D(uiMaskPrevColor, texcoord).rgb;
		diff = (abs(ori.r-prev.r)+abs(ori.g-prev.g)+abs(ori.b-prev.b))/3f;
	}
	finalR = tex2D(uiMaskFinalColorLowPing,texcoord)+float4(1,1,1,1)*(max(0.0f,diff-0.8f*(0.5f-pow(max(abs(0.5f-texcoord.x),abs(0.5f-texcoord.y)),3))));//lerp(float4(0,0,0,0),float4(1,1,1,1),diff);
}

void PS_UIMaskHelperStore(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 prevR : SV_Target0)
{ 
	prevR = tex2D(RFX_originalColor, texcoord);
}

float4 PS_UIMaskHelperFinal(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(uiMaskFinalColorHighPong, texcoord);
}

void PS_UIMaskHelperStart(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 startR : SV_Target0)
{
	startR = float4(1,1,1,1);
}

void PS_UIMaskHelperStop(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 startR : SV_Target0)
{
	startR = float4(0,0,0,0);
}

void PS_UIMaskHelperFinalReset(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 finalPingR : SV_Target0, out float4 finalPongR : SV_Target1)
{
	finalPingR = float4(0,0,0,0);
	finalPongR = float4(0,0,0,0);
}

void PS_UIMaskHelperBlurLowH(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 finalPingR : SV_Target0)
{
	float4 finalPong = tex2D(uiMaskFinalColorLowPong, texcoord);
if(finalPong.r >= 0.59f) {	
	float weight[10] = { 0.9f,0.85f,0.75f,0.5f,0.2f,0.1f,0.04f,0.004f,0.002f,0.0002f };

	float pixelBlur = BUFFER_RCP_WIDTH; 

	[unroll]
	for (int z = 0; z < 10; z++) //set quality level by user
	{
		if(tex2D(uiMaskFinalColorLowPong, texcoord + float2(3f*z*pixelBlur, 0)).r <= 0.2f) finalPong *= (1.0f-weight[z]);
		if(tex2D(uiMaskFinalColorLowPong, texcoord - float2(3f*z*pixelBlur, 0)).r <= 0.2f) finalPong *= (1.0f-weight[z]);
	}
}
	finalPingR = finalPong;
}

void PS_UIMaskHelperBlurLowV(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 finalPongR : SV_Target0)
{
	float4 finalPing = tex2D(uiMaskFinalColorLowPing, texcoord);
if(finalPing.r >= 0.59f) {
	float weight[10] = { 0.9f,0.85f,0.75f,0.5f,0.2f,0.1f,0.04f,0.004f,0.002f,0.0002f };

	float pixelBlur = BUFFER_RCP_HEIGHT; 

	[unroll]
	for (int z = 0; z < 10; z++) //set quality level by user
	{
		if(tex2D(uiMaskFinalColorLowPing, texcoord + float2(0, 3f*z*pixelBlur)).r <= 0.2f) finalPing *= (1.0f-weight[z]);
		if(tex2D(uiMaskFinalColorLowPing, texcoord - float2(0, 3f*z*pixelBlur)).r <= 0.2f) finalPing *= (1.0f-weight[z]);
	}
}
	finalPongR = finalPing;
}

void PS_UIMaskHelperBlurHighH(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 finalPingR : SV_Target0)
{
	float4 finalPong = tex2D(uiMaskFinalColorHighPong, texcoord);
if(finalPong.r >= 0.59f) {	
	float weight[10] = { 0.9f,0.85f,0.75f,0.5f,0.2f,0.1f,0.04f,0.004f,0.002f,0.0002f };

	float pixelBlur = BUFFER_RCP_WIDTH; 

	[unroll]
	for (int z = 0; z < 10; z++) //set quality level by user
	{
		if(tex2D(uiMaskFinalColorHighPong, texcoord + float2(3f*z*pixelBlur, 0)).r <= 0.2f) finalPong *= (1.0f-weight[z]);
		if(tex2D(uiMaskFinalColorHighPong, texcoord - float2(3f*z*pixelBlur, 0)).r <= 0.2f) finalPong *= (1.0f-weight[z]);
	}
}
	finalPingR = finalPong;
}

void PS_UIMaskHelperBlurHighV(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 finalPongR : SV_Target0)
{
	float4 finalPing = tex2D(uiMaskFinalColorHighPing, texcoord);
if(finalPing.r >= 0.59f) {
	float weight[10] = { 0.9f,0.85f,0.75f,0.5f,0.2f,0.1f,0.04f,0.004f,0.002f,0.0002f };

	float pixelBlur = BUFFER_RCP_HEIGHT; 

	[unroll]
	for (int z = 0; z < 10; z++) //set quality level by user
	{
		if(tex2D(uiMaskFinalColorHighPing, texcoord + float2(0, 3f*z*pixelBlur)).r <= 0.2f) finalPing *= (1.0f-weight[z]);
		if(tex2D(uiMaskFinalColorHighPing, texcoord - float2(0, 3f*z*pixelBlur)).r <= 0.2f) finalPing *= (1.0f-weight[z]);
	}
}
	finalPongR = finalPing;
}

#if UIMask_Helper
technique UIMaskHelperReset_Tech <bool enabled = !RFX_Start_Enabled; int toggle = UIMaskReset_HelperKey; >
{
	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperFinalReset;
		RenderTarget0 = uiMaskFinalTexLowPing;
		RenderTarget1 = uiMaskFinalTexLowPong;
	}

	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperStop;
		RenderTarget = uiMaskFinalStartTex;
	}

}

technique UIMaskHelper_Tech <bool enabled = !RFX_Start_Enabled; int toggle = UIMask_HelperKey; >
{
	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperComparePing;
		RenderTarget0 = uiMaskFinalTexLowPing;
	}

	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperComparePong;
		RenderTarget0 = uiMaskFinalTexLowPong;
	}

	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperBlurLowH;
		RenderTarget0 = uiMaskFinalTexLowPing;
	}

	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperBlurLowV;
		RenderTarget0 = uiMaskFinalTexHighPong;
	}

	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperBlurHighH;
		RenderTarget0 = uiMaskFinalTexHighPing;
	}

	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperBlurHighV;
		RenderTarget0 = uiMaskFinalTexHighPong;
	}

	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperStart;
		RenderTarget0 = uiMaskFinalStartTex;
	}

	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperFinal;
	}

	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMaskHelperStore;
		RenderTarget0 = uiMaskPrevTex;
	}
}
#endif

#if UIMask_Direct
technique UIMask_Tech <bool enabled = RFX_Start_Enabled; int toggle = RFX_ToggleKey; >
{
#else 
technique UIMask_Tech <bool enabled = RFX_Start_Enabled; int toggle = UIMask_HelperKey; >
{
#endif
	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_UIMask;
	}
}

#endif

#include BFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()