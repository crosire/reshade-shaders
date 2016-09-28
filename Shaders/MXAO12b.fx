//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Ambient Obscurance with Indirect Lighting "MXAO" 1.2b by Marty McFly
// For ReShade 3.X only!
// Copyright (c) 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float fMXAOAmbientOcclusionAmount <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 3.00;
	ui_tooltip = "MXAO: Linearly increases AO intensity. Can cause pitch black clipping if set too high.";
> = 2.00;

uniform bool bMXAOIndirectLightingEnable <
	ui_tooltip = "MXAO: Enables Indirect Lighting calculation. Will cause a major fps hit.";
> = false;

uniform float fMXAOIndirectLightingAmount <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 12.00;
	ui_tooltip = "MXAO: Linearly increases IL intensity. Can cause overexposured white spots if set too high.";
> = 4.00;

uniform float fMXAOIndirectLightingSaturation <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 3.00;
	ui_tooltip = "MXAO: Boosts IL saturation for more pronounced effect.";
> = 1.00;

uniform float fMXAOSampleRadius <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 20.00;
	ui_tooltip = "MXAO: Sample radius of GI, higher values drop performance.\nHeavily depending on game, GTASA: 2 = GTA V: 10ish.";
> = 2.50;

uniform int iMXAOSampleCount <
	ui_type = "drag";
	ui_min = 12; ui_max = 255;
	ui_tooltip = "MXAO: Amount of MXAO samples. Higher means more accurate and less noisy AO at the cost of fps.";
> = 32;

uniform bool bMXAOSmartSamplingEnable <
	ui_tooltip = "MXAO: Enables smart sample count reduction for far areas.\nEffect is lowered for low sample counts to prevent single digit sample counts in far areas.";
> = true;

uniform float fMXAOSampleRandomization <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "MXAO: Breaks up the dither pattern a bit if sample spiral gets too visible,\nwhich can happen with low samples and/or high radius.\nNeeds stronger blurring though.";
> = 1.00;

uniform float fMXAONormalBias <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.8;
	ui_tooltip = "MXAO: Normals bias to reduce self-occlusion of surfaces that have a low angle to each other.";
> = 0.8;

uniform bool bMXAOBackfaceCheckEnable <
	ui_tooltip = "MXAO: For indirect lighting only!\nEnables back face check so surfaces facing away from the source position don't cast light. \nIt comes with a slight fps drop.";
> = true;

uniform float fMXAOBlurSharpness <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 5.00;
	ui_tooltip = "MXAO: AO sharpness, higher means sharper geometry edges but noisier AO, less means smoother AO but blurry in the distance.";
> = 1.00;

uniform int fMXAOBlurSteps <
	ui_type = "drag";
	ui_min = 0; ui_max = 5;
	ui_tooltip = "MXAO: Offset count for AO bilateral blur filter. Higher means smoother but also blurrier AO.";
> = 3;

uniform bool bMXAODebugViewEnable <
	ui_tooltip = "MXAO: Enables raw AO/IL output for debugging and tuning purposes.";
> = false;

//non GUI-able variables/variables I was too lazy to add 
#define fMXAOSizeScale  1.0	//[0.5 to 1.0] 	 Resolution scale in which AO is being calculated.
#define iMXAOMipLevelIL 2	//[0 to 4]       Miplevel of IL texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth. 
#define iMXAOMipLevelAO 0	//[0 to 2]	 Miplevel of AO texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth. Best results: IL MipLevel = AO MipLevel + 2
#define bMXAOBoundaryCheckEnable 0	//[0 or 1]	 Enables screen boundary check for samples. Can be useful to remove odd behaviour with too high sample radius / objects very close to camera. It comes with a slight fps drop.

//custom variables, depleted after Framework implementation.
#define AO_FADE____START 		0.6		//[0.0 to 1.0]	 Depth at which AO starts to fade out. 0.0 = camera, 1.0 = sky. Must be lower than AO fade end.
#define AO_FADE____END   		0.9		//[0.0 to 1.0]	 Depth at which AO completely fades out. 0.0 = camera, 1.0 = sky. Must be higher than AO fade start.

#include "ReShade.fxh"

//textures
texture texLOD { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 5 + iMXAOMipLevelIL; };
texture texDepthLOD { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; MipLevels = 5 + iMXAOMipLevelAO; }; //no high prec mode anymore
texture texNormal { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 5 + iMXAOMipLevelIL; };
texture texSSAO { Width = BUFFER_WIDTH*fMXAOSizeScale; Height = BUFFER_HEIGHT*fMXAOSizeScale; Format = RGBA8; };
texture texDither < source = "bayer16x16.png";> { Width = 16; Height = 16; Format = R8; };

sampler SamplerLOD { Texture = texLOD; };
sampler SamplerDepthLOD { Texture = texDepthLOD; };
sampler SamplerNormal { Texture = texNormal; };
sampler SamplerSSAO { Texture = texSSAO; };

sampler SamplerDither
{
	Texture = texDither;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
	AddressU = WRAP;
	AddressV = WRAP;
};


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float GetLinearDepth(float2 coords)
{
	return ReShade::GetLinearizedDepth(coords);
}

float3 GetPosition(float2 coords)
{
	float EyeDepth = GetLinearDepth(coords.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	return float3((coords.xy * 2.0 - 1.0)*EyeDepth,EyeDepth);
}

float3 GetPositionLOD(float2 coords, int mipLevel)
{
	float EyeDepth = tex2Dlod(SamplerDepthLOD, float4(coords.xy,0,mipLevel)).x;
	return float3((coords.xy * 2.0 - 1.0)*EyeDepth,EyeDepth);
}

float3 GetNormalFromDepth(float2 coords) 
{
	float3 centerPos = GetPosition(coords.xy);
	float2 offs = ReShade::PixelSize.xy*1.0;
	float3 ddx1 = GetPosition(coords.xy + float2(offs.x, 0)) - centerPos;
	float3 ddx2 = centerPos - GetPosition(coords.xy + float2(-offs.x, 0));

	float3 ddy1 = GetPosition(coords.xy + float2(0, offs.y)) - centerPos;
	float3 ddy2 = centerPos - GetPosition(coords.xy + float2(0, -offs.y));

	ddx1 = lerp(ddx1, ddx2, abs(ddx1.z) > abs(ddx2.z));
	ddy1 = lerp(ddy1, ddy2, abs(ddy1.z) > abs(ddy2.z));

	float3 normal = cross(ddy1, ddx1);
	
	return normalize(normal);
}

float4 GetBlurFactors(float2 coords)
{
	return float4(tex2Dlod(SamplerNormal, float4(coords.xy,0,0)).xyz*2.0-1.0,GetLinearDepth(coords.xy));
}

float GetBlurWeight(float r, float4 z, float4 z0)
{
	float normaldiff = distance(z.xyz,z0.xyz);
	float depthdiff = abs(z.w-z0.w);

	float depthfalloff = pow(saturate(1.0 - z0.w),3.0);
	float fresnelfactor  = saturate(min(-z0.z,-z.z)); 

	float normalweight = saturate(1.0-normaldiff * fMXAOBlurSharpness);
	float depthweight = saturate(1.0-depthdiff * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE * fMXAOBlurSharpness * fresnelfactor * depthfalloff * 0.5);
	
	return min(depthweight,normalweight);
}

float2 GetRandom2FromCoord(float2 coords)
{
	coords *= 1000.0;
	float3 coords3 = frac(float3(coords.xyx) * 0.1031);
		coords3 += dot(coords3.xyz, coords3.yzx+19.19);
		return frac(float2((coords3.x + coords3.y)*coords3.z, (coords3.x+coords3.z)*coords3.y));
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_AO_Pre(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0, out float4 depth : SV_Target1, out float4 normal : SV_Target2)
{
	color = tex2D(ReShade::BackBuffer, texcoord.xy);
	depth = GetLinearDepth(texcoord.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	normal = GetNormalFromDepth(texcoord.xy).xyzz*0.5+0.5; // * 0.5 + 0.5; //packing into 2 components not possible.
}

void PS_AO_Gen(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float3 ScreenSpaceNormals = GetNormalFromDepth(texcoord.xy); //tex2D(SamplerNormal, texcoord.xy).xyz * 2.0 - 1.0; //better to use best possible data than rounded texture values
	float3 ScreenSpacePosition = GetPositionLOD(texcoord.xy, 0);

	float scenedepth = ScreenSpacePosition.z / RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	ScreenSpacePosition += ScreenSpaceNormals * scenedepth;

	float numSamples = iMXAOSampleCount;
if(bMXAOSmartSamplingEnable) numSamples = lerp(iMXAOSampleCount,12,scenedepth / AO_FADE____END); //AO FADEOUT //12 is minimum acceptable sampling count and max(12,...) makes falloff ineffective for small sample counts.

	float2 SampleRadiusScaled  = fMXAOSampleRadius / (numSamples * ScreenSpacePosition.z * float2(1.0, 1.0/ReShade::AspectRatio) * 0.6);
	float radialJitter = (GetRandom2FromCoord(texcoord.xy).x-0.5) * fMXAOSampleRandomization;

	float rotAngle = tex2D(SamplerDither, texcoord.xy * float2(BUFFER_WIDTH,BUFFER_HEIGHT) * fMXAOSizeScale * 0.0625).x; 
	float mipFactor = SampleRadiusScaled.x*numSamples*19.0;

	float4 AOandGI = 0.0;

	float2x2 radialMatrix = float2x2(0.575,0.81815,-0.81815,0.575); //E.F
	float2 currentVector = float2(cos(rotAngle*6.283), sin(rotAngle*6.283));

	float fNegInvR2 = -1.0/(fMXAOSampleRadius*fMXAOSampleRadius);

	[loop]
		for (float i=1.0; i <= numSamples; i++) 
	{
		currentVector = mul(currentVector.xy,  radialMatrix);	
		float2 currentOffset = texcoord.xy + currentVector.xy * SampleRadiusScaled.xy * (i+radialJitter); 
#if(bMXAOBoundaryCheckEnable != 0)
		[branch]
		if(currentOffset.x < 1.0 && currentOffset.y < 1.0 && currentOffset.x > 0.0 && currentOffset.y > 0.0)
		{
#endif
			float mipLevel = clamp((int)floor(log2(mipFactor*i)) - 3, iMXAOMipLevelAO, 5); //AO must not go beyond 5

			float3 occlVec = GetPositionLOD(currentOffset.xy, mipLevel) - ScreenSpacePosition;
			float occlDistance = length(occlVec);
			float SurfaceAngle = dot(occlVec/occlDistance, ScreenSpaceNormals); 

			float fAO = saturate(occlDistance * fNegInvR2 + 1.0)  * saturate(SurfaceAngle - fMXAONormalBias); 	

			if(bMXAOIndirectLightingEnable)
			{
				float3 fIL = tex2Dlod(SamplerLOD, float4(currentOffset,0,mipLevel + iMXAOMipLevelIL)).xyz;
				if(bMXAOBackfaceCheckEnable)
				{
					float3 offsetNormals = tex2Dlod(SamplerNormal, float4(currentOffset,0,mipLevel + iMXAOMipLevelIL)).xyz * 2.0 - 1.0; 
					float facingtoSource = dot(-normalize(occlVec),offsetNormals);
					facingtoSource = smoothstep(-0.5,0.0,facingtoSource); 
					fIL *= facingtoSource;
				}
				AOandGI.w += fAO*saturate(1-dot(fIL,float3(0.299,0.587,0.114)));
				AOandGI.xyz += fIL*fAO;
			}
			else
			{
				AOandGI.w += fAO;
			}
#if(bMXAOBoundaryCheckEnable != 0)
		}
#endif
	}

	AOandGI *= 20.0 / ((1.0-fMXAONormalBias)*numSamples*fMXAOSampleRadius); 
	res = lerp(AOandGI,float4(0.0.xxx,0.0), AO_FADE____END < scenedepth); //AO FADEOUT
}

void PS_AO_Blur1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float4 center_factor = GetBlurFactors(texcoord.xy);
	float4 temp_factor = 0.0;

	float totalweight = 1.0;
	float tempweight = 0.0;

	float4 total_ao = tex2Dlod(SamplerSSAO, float4(texcoord.xy,0,0));
	float4 temp_ao = 0.0;

	[loop]
	for(float r = 1.0; r <= min(5,fMXAOBlurSteps); r += 1.0)
	{
		float2 axis = float2(-r,r)/fMXAOSizeScale*1.25;

		temp_factor = GetBlurFactors(texcoord.xy + axis * ReShade::PixelSize.xy);
		temp_ao = tex2Dlod(SamplerSSAO, float4(texcoord.xy + axis * ReShade::PixelSize.xy,0,0));
		tempweight = GetBlurWeight(r, temp_factor, center_factor);

		total_ao += temp_ao * tempweight;
		totalweight += tempweight;

		temp_factor = GetBlurFactors(texcoord.xy - axis * ReShade::PixelSize.xy);
		temp_ao = tex2Dlod(SamplerSSAO, float4(texcoord.xy - axis * ReShade::PixelSize.xy,0,0));
		tempweight = GetBlurWeight(r, temp_factor, center_factor);

		total_ao += temp_ao * tempweight;
		totalweight += tempweight;
	}

	total_ao /= totalweight;
	res = total_ao;
}

void PS_AO_Blur2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float4 center_factor = GetBlurFactors(texcoord.xy);
	float4 temp_factor = 0.0;

	float totalweight = 1.0;
	float tempweight = 0.0;

	float4 total_ao = tex2Dlod(ReShade::BackBuffer, float4(texcoord.xy,0,0));
	float4 temp_ao = 0.0;
	
	[loop]
	for(float r = 1.0; r <= min(5,fMXAOBlurSteps); r += 1.0)
	{
		float2 axis = float2(r,r)/fMXAOSizeScale*1.25;

		temp_factor = GetBlurFactors(texcoord.xy + axis * ReShade::PixelSize.xy);
		temp_ao = tex2Dlod(ReShade::BackBuffer, float4(texcoord.xy + axis * ReShade::PixelSize.xy,0,0));
		tempweight = GetBlurWeight(r, temp_factor, center_factor);

		total_ao += temp_ao * tempweight;
		totalweight += tempweight;

		temp_factor = GetBlurFactors(texcoord.xy - axis * ReShade::PixelSize.xy);
		temp_ao = tex2Dlod(ReShade::BackBuffer, float4(texcoord.xy - axis * ReShade::PixelSize.xy,0,0));
		tempweight = GetBlurWeight(r, temp_factor, center_factor);

		total_ao += temp_ao * tempweight;
		totalweight += tempweight;
	}

	total_ao /= totalweight;
	float4 mxao = saturate(total_ao);

	float scenedepth = GetLinearDepth(texcoord.xy); //might change center_factor so better fetch depth directly here.
	float4 color = max(0.0,tex2D(SamplerLOD, texcoord.xy)); 
	float colorgray = dot(color.xyz,float3(0.299,0.587,0.114));

	mxao.xyz  = lerp(dot(mxao.xyz,float3(0.299,0.587,0.114)),mxao.xyz,fMXAOIndirectLightingSaturation) * fMXAOIndirectLightingAmount;
	mxao.w    = 1.0-pow(1.0-mxao.w, fMXAOAmbientOcclusionAmount * 2.0);

	if (!bMXAODebugViewEnable)
	{
		mxao = lerp(mxao, 0.0, pow(colorgray,2.0));
	}

	mxao.w    = lerp(mxao.w, 0.0,smoothstep(AO_FADE____START, AO_FADE____END, scenedepth)); 			//AO FADEOUT
	mxao.xyz  = lerp(mxao.xyz,0.0,smoothstep(AO_FADE____START*0.5, AO_FADE____END*0.5, scenedepth)); 		//AO FADEOUT //IL can look really bad on far objects.

	float3 GI = mxao.w - mxao.xyz;
	GI = max(0.0,1-GI);
	color.xyz *= GI;

	if (bMXAODebugViewEnable)
	{
		if (bMXAOIndirectLightingEnable)
		{	
			color.xyz = (texcoord.x > 0.5) ? mxao.xyz : 1-mxao.w;
		}
		else
		{
			color.xyz = 1-mxao.w;
		}
	}

	res = color;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique MXAO
{
	pass P0
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Pre;
		RenderTarget0 = texLOD;
		RenderTarget1 = texDepthLOD;
		RenderTarget2 = texNormal;
	}
	pass P1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Gen;
		RenderTarget = texSSAO;
	}
	pass P2_0
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Blur1;
	}
	pass P2_1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Blur2;
	}
}