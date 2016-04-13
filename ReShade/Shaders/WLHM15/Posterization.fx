/**-----------------------------------------------------------------------------------/
 * Copyright (C) 2014 - 2016 WLHM15 (thewlhm15@gmail.com)
 *------------------------------------------------------------------------------------/
 * Permission needs to be specifically granted by the author of the FireFX to any
 * person obtaining a copy of this FireFX and associated documentation files 
 * of FireFX, to deal in the FireFX without restriction, including without 
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
 * Posterization FX by WLHM15
 *------------------------------------------------------------------------------------*/
 
#include EFFECT_CONFIG(WLHM15)
#include "Common.fx"
#if USE_Posterization

#pragma message "Posterization by WLHM15\n"

namespace Wlhm15
{

	float4 PosterizationPass(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		float4 color = tex2D(samplerHDRB, texcoord.xy);
		color.rgb = (color.rgb * fPostzSteps);
		color.rgb = (floor(color.rgb));
		color.rgb /= fPostzSteps;
		return color;
	}

	float4 PS_Uninitialization(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return tex2D(samplerHDRA, texcoord.xy);
	}
	
	technique PosterizationFX_Tech < bool enabled = RESHADE_START_ENABLED;  int toggle = PosterizationFX_ToggleKey; >
	{
		pass Posterization_Pass
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PosterizationPass;
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
