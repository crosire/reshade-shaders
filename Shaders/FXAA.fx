/**
 * Copyright © 2016 Wilham A. Putro (thewlhm15@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. As clarification, there
 * is no requirement that the copyright notice and permission be included in
 * binary distributions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE. 
 *------------------------------------------------------------------------------
 *                       FireFX Shader File by WLHM15
 *                        For ReShade 3.0 by Crosire 
 *------------------------------------------------------------------------------
 *                     Fast Approximate Anti Aliasing 3.11
 *------------------------------------------------------------------------------
 * 
 */

uniform float fFXAASubpix <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Amount of sub-pixel aliasing removal. Higher values makes the image softer/blurrier.";
> = 0.1; 

uniform float fFXAAThreshold <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Edge detection threshold. The minimum amount of local contrast required to apply algorithm.";
> = 0.1;

uniform float fFXAAEdgeThresholdMin <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Darkness threshold. Pixels darker than this are not processed in order to increase performance.";
> = 0.1;  

/* Jangan ubah apapun dibawah garis ini, kecuali kau tau apa yang kau lakukan! */
#include "ReShade.fxh"
#include "FXAA311.fxh"

//pixelshader
void FXAntiAliasing(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 warna : SV_Target)
{
	warna = FxaaPixelShader(texcoord, ReShade::BackBuffer, ReShade::PixelSize, float4(0.0f, 0.0f, 0.0f, 0.0f), fFXAASubpix, fFXAAThreshold, fFXAAEdgeThresholdMin);
}
	
	
//teknik
technique FXAA
{
	pass TheFXAA
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAntiAliasing;
	}
}
