/**
 * Copyright © 2016 Wilham A. Putro (thewlhm15@gmail.com)
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "software"), to deal in the software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the software.
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
 *                          Cinematic Elements 1.3b
 *------------------------------------------------------------------------------
 * 
 */

uniform bool bUseLetterbox <
	ui_tooltip = "Enable Letterbox";
> = false;

uniform bool bUseVignette <
	ui_tooltip = "Enable Vignette";
> = false;
//--------------------------------------------------------
uniform int iLetterboxMode <
	ui_type = "combo";
	ui_items = "Colored Box\0Textured Box\0Blurred Box\0";
	ui_tooltip = "Letterbox Mode";
> = 0;
 
uniform float fLetterboxSize <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 50.0;
	ui_tooltip = "How big the size of letterbox will be";
> = 0.8; 
//--------------------------------------------------------
uniform int iVignetteMode <
	ui_type = "combo";
	ui_items = "Colored Vignette\0Textured Vignette\0Blurred Vignette\0";
	ui_tooltip = "Vignette Mode";
> = 0;

uniform float fVignetteAmount <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 50.0;
	ui_tooltip = "Amount of vignette will be";
> = 0.8;

uniform float fVignetteCurve <
	ui_type = "drag";
	ui_min = 0.5; ui_max = 2.0;
	ui_tooltip = "Vignette Curve";
> = 1.2;

uniform float fVignetteRadius <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 5.0;
	ui_tooltip = "The radius of vignette";
> = 1.5;
//---------------------------------------------------------
uniform float3 fCineColor <
	ui_type = "color";
	ui_tooltip = "R, G and B components of cinematic element color";
> = float3(0.0, 0.0, 0.0);

uniform float fTexSize <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 25.0;
	ui_tooltip = "How big the size of texture will be";
> = 4.8; 

uniform float fGaussianMult <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 25.0;
	ui_tooltip = "How big the gaussian blur will be";
> = 4.0; 

uniform float fGaussianDensity <
	ui_type = "drag";
	ui_min = 0.1; ui_max = 2.0;
	ui_tooltip = "Density of the gaussian blur";
> = 0.7; 

/* Jangan ubah apapun dibawah garis ini, kecuali kau tau apa yang kau lakukan! */
#include "ReShade.fxh"

//tekstur
texture tekBorder <source = "bordertex.png";> {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;}; //Ukuran disesuaikan dengan tekstur

//sampler
sampler samplerBorder {Texture = tekBorder; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = WRAP; AddressV = WRAP;};

float4 GaussBlur22(float2 coord, sampler tex, float mult, bool isBlurVert)
{
	float2 blurmult = ReShade::PixelSize * mult;
	float4 warna = tex2D(tex, coord);

	float4 blurcolor = 0;
	
	float weights[3] = { 1.0,0.75,0.5 };
	for (float x = -2; x <= 2; x++)
	{
		for (float y = -2; y <= 2; y++)
		{
			float2 offset = float2(x, y);
			float offsetweight = weights[abs(x)] * weights[abs(y)];
			blurcolor.rgb += tex2Dlod(tex, float4(coord + offset.xy * blurmult, 0, 0)).rgb * offsetweight;
			blurcolor.a += offsetweight;
		}
	}

	warna.rgb = blurcolor.rgb / blurcolor.a;
	return warna;
}


//pixelshader
void CineElmts(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 warna : SV_Target)
{
	float letboxsize = fLetterboxSize * 0.01;
	warna = tex2D(ReShade::BackBuffer, texcoord.xy);
	
	if (bUseLetterbox)
	{
		if (iLetterboxMode == 0)
			warna.rgb = texcoord.y > letboxsize && texcoord.y < 1.0 - letboxsize ? warna.rgb : fCineColor;
		else if (iLetterboxMode == 1)
			warna = texcoord.y > letboxsize && texcoord.y < 1.0 - letboxsize ? warna.rgba : tex2D(samplerBorder, texcoord.xy * fTexSize);
		else if (iLetterboxMode == 2)
			warna = texcoord.y > letboxsize && texcoord.y < 1.0 - letboxsize ? warna.rgba : GaussBlur22(texcoord, ReShade::BackBuffer, fGaussianMult, 0) * fGaussianDensity;
	}
	
	if (bUseVignette)
	{
		float2 koordinat = (texcoord.xy - 0.5) * fVignetteRadius;
		float vignette = saturate(dot(koordinat.xy, koordinat.xy));
		vignette = pow(vignette, fVignetteCurve);
		if (iVignetteMode == 0)
			warna.rgb = lerp(warna.rgb, fCineColor, vignette * fVignetteAmount);
		else if (iVignetteMode == 1)
			warna = lerp(warna, tex2D(samplerBorder, texcoord.xy * fTexSize), vignette * fVignetteAmount);
		else if (iVignetteMode == 2)
			warna = lerp(warna, GaussBlur22(texcoord, ReShade::BackBuffer, fGaussianMult, 0) * fGaussianDensity, vignette * fVignetteAmount);
	}

}
	
	
//teknik
technique CinematicElements
{
	pass Cinematic
	{
		VertexShader = PostProcessVS;
		PixelShader = CineElmts;
	}
}
