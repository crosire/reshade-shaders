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
 *	Fast Approximate Gaussian Bloom FX (FXGB) by Pascal Matthäus
 *	Ported by WLHM15
 *------------------------------------------------------------------------------------*/
 
#include EFFECT_CONFIG(WLHM15)
#include "Common.fx"

#if USE_FXGB
#pragma message "Fast Approximate Gaussian Bloom by Euda (Ported by WLHM15)\n"

namespace Wlhm15
{
	float3 threshold(float3 colInput, float colThreshold)
	{
		return colInput*max(0.0,sign(max(colInput.x,max(colInput.y,colInput.z))-colThreshold));
	}

	float3 FXGBlurH( float3 colInput, sampler source, float2 txCoords, float radius, float downsampling )
	{
		float	texelSize = ReShade::PixelSize.x*downsampling;
		float2	fetchCoords = txCoords;
		float	weight;
		float	weightDiv = 1.0+5.0/radius;
		float	sampleSum = 0.5;
		
		colInput+=tex2D(source,txCoords).xyz*0.5;
		
		[unroll]
		for (float hOffs=1.5; hOffs<radius; hOffs+=2.0)
		{
			weight = 1.0/pow(weightDiv,hOffs*hOffs/radius);
			fetchCoords = txCoords;
			fetchCoords.x += texelSize * hOffs;
			colInput+=tex2D(source, fetchCoords).xyz * weight;
			fetchCoords = txCoords;
			fetchCoords.x -= texelSize * hOffs;
			colInput+=tex2D(source, fetchCoords).xyz * weight;
			sampleSum += 2.0 * weight;
		}
		colInput /= sampleSum;
		
		return colInput;
	}
	
	float3 FXGBlurV( float3 colInput, sampler source, float2 txCoords, float radius, float downsampling )
	{
		float	texelSize = ReShade::PixelSize.y*downsampling;
		float2	fetchCoords = txCoords;
		float	weight;
		float	weightDiv = 1.0+5.0/radius;
		float	sampleSum = 0.5;
		
		colInput+=tex2D(source,txCoords).xyz*0.5;
		
		[unroll]
		for (float vOffs=1.5; vOffs<radius; vOffs+=2.0)
		{
			weight = 1.0/pow(weightDiv,vOffs*vOffs/radius);
			fetchCoords = txCoords;
			fetchCoords.y += texelSize * vOffs;
			colInput+=tex2D(source, fetchCoords).xyz * weight;
			fetchCoords = txCoords;
			fetchCoords.y -= texelSize * vOffs;
			colInput+=tex2D(source, fetchCoords).xyz * weight;
			sampleSum += 2.0 * weight;
		}
		colInput /= sampleSum;
		
		return colInput;
	}
	
	float4 FXGBloomMix( float3 colInput, float2 txCoords )
	{
		float3 blurTexture = tex2D(samplerBloomA,txCoords).xyz;
		float3 dirtylensa = tex2D(samplerDirt, txCoords.xy).r;
		#if (FXGBLensdirt == 1)
		colInput += tex2D(samplerDirt, txCoords).xyz*pow(abs(dot(blurTexture,lumaCoeff)),FXGBLensdirtCurve)*FXGBLensdirtIntensity;
		#endif
		blurTexture = pow(abs(blurTexture),FXGBCurve);
		blurTexture = lerp(dot(blurTexture.xyz,lumaCoeff.xyz),blurTexture,FXGBSaturation);
		blurTexture /= max(1.0,max(blurTexture.x,max(blurTexture.y,blurTexture.z)));
		#if (FXGBBlendMode == 1)
			colInput = colInput+blurTexture*FXGBIntensity;
			return float4(colInput,1.0+FXGBIntensity);
		#elif (FXGBBlendMode == 2)
			colInput = max(colInput,blurTexture*FXGBIntensity);
			return float4(colInput,max(1.0,FXGBIntensity));
		#elif (FXGBBlendMode == 3)
			colInput = blurTexture+colInput*FXGBIntensity;
			return float4(min(colInput, FXGBIntensity), 1.0);
		#elif (FXGBBlendMode == 4)
			colInput = blurTexture;
			return float4(colInput,FXGBIntensity);
		#endif
	}

	///////////////////////////////////////////////////////
	float4 PS_FXGB_Threshold(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return float4(threshold(tex2D(samplerHDRA, texcoord.xy).xyz,FXGBThreshold),1.0);
	}

	float4 PS_FXGB_Horizontal(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return float4(FXGBlurH(0.0,samplerBloomA,texcoord.xy,FXGBRadius,FXGBDownsampling),1.0);
	}

	float4 PS_FXGB_Vertical(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return float4(FXGBlurV(0.0,samplerBloomB,texcoord.xy,FXGBRadius,FXGBDownsampling),1.0);
	}

	float4 PS_FXGB_Combine(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return FXGBloomMix(tex2D(samplerHDRA,texcoord.xy).xyz,texcoord.xy);
	}
	
	///////////////////////////////////////////////////////
	float4 PS_Uninitialization(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
		return tex2D(samplerHDRB, texcoord.xy);
	}

	///////////////////////////////////////////////////////
	technique FXGB_FX_Tech < bool enabled = RESHADE_START_ENABLED;  int toggle = FXGB_FX_ToggleKey; >
	{
	
		pass FXGBThresholdInit
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_FXGB_Threshold;
			RenderTarget0 = texBloomA;
		}
		
		pass FXGBBlurHorizontal
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_FXGB_Horizontal;
			RenderTarget0 = texBloomB;
		}
		
		pass FXGBBlurVertical
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_FXGB_Vertical;
			RenderTarget0 = texBloomA;
		}
		
		pass FXGBCombine
		{
			VertexShader = ReShade::VS_PostProcess;
			PixelShader = PS_FXGB_Combine;
			RenderTarget0 = texHDRB;
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
