/**-----------------------------------------------------------------------------------/
 * Copyright (C) 2014 - 2016 WLHM15 (thewlhm15@gmail.com)
 *------------------------------------------------------------------------------------/
 * Permission needs to be specifically granted by the author of the FireFX to any
 * person obtaining a copy of this FireFX and associated documentation files 
 * (the "FireFX"), to deal in the FireFX without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the FireFX.
 *-------------------------------------------------------------------------------------/
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the FireFX.
 *-------------------------------------------------------------------------------------/
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *-------------------------------------------------------------------------------------/
 * Yet Another Technicolor FX by WLHM15
 *------------------------------------------------------------------------------------*/
 
 
#include EFFECT_CONFIG(WLHM15)
#include "Common.fx"
#if USE_YATC

#pragma message "Yet Another Technicolor by WLHM15\n"

namespace Wlhm15
{

	float4 PS_YATC_FX(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
	    float4 color = tex2D(samplerHDRB, texcoord.xy);
		  
	    float3 redmatte = color.r - ((color.g + color.b) / 2.0);
	    float3 greenmatte = color.g - ((color.r + color.b) / 2.0);
	    float3 bluematte = color.b - ((color.r + color.g) / 2.0);
	
	    redmatte   = 1.0 - redmatte;
	    greenmatte = 1.0 - greenmatte;
	    bluematte  = 1.0 - bluematte;
	
	    float3 red   = redmatte * bluematte  * color.r;
	    float3 green = greenmatte   * bluematte  * color.g; 
	    float3 blue  = bluematte   * redmatte * color.b;

	    float4 result = float4(red.r, green.g, blue.b, color.a);
	
	    return lerp(color, result, YATCAmonut);
	}

  //////////////////////////////////////////////////
	float4 PS_Uninitialization(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return tex2D(samplerHDRA, texcoord.xy);
	}
	
	///////////////////////////////////////////////////
	technique YATC_FX_Tech < bool enabled = RESHADE_START_ENABLED;  int toggle = YATC_FX_ToggleKey; >
	{
		pass YATC_FX_Pass
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_YATC_FX;
			RenderTarget = texHDRA;
		}
		
		pass Uninitialization
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_Uninitialization;
			SRGBWriteEnable = TRUE;
		}
	}

}

#endif
#include EFFECT_CONFIG_UNDEF(WLHM15)
 
