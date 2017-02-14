//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade 3.0 effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Ambient Obscurance with Indirect Lighting "MXAO" 2.0 by Marty McFly
// CC BY-NC-ND 3.0 licensed.
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Preprocessor Settings
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef MXAO_MIPLEVEL_AO
#define MXAO_MIPLEVEL_AO		0	//[0 to 2]      Miplevel of AO texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth. Best results: IL MipLevel = AO MipLevel + 2
#endif

#ifndef MXAO_MIPLEVEL_IL
 #define MXAO_MIPLEVEL_IL		2	//[0 to 4]      Miplevel of IL texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth.
#endif

#ifndef MXAO_ENABLE_IL
#define MXAO_ENABLE_IL			0	//[0 or 1]	Enables Indirect Lighting calculation. Will cause a major fps hit.
#endif

#ifndef MXAO_ENABLE_BACKFACE
#define MXAO_ENABLE_BACKFACE		1	//[0 or 1]	Enables back face check so surfaces facing away from the source position don't cast light. Will cause a major fps hit.
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// UI variables
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform float fMXAOAmbientOcclusionAmount <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 3.00;
        ui_label = "Ambient Occlusion Amount";
	ui_tooltip = "Linearly increases AO intensity. Can cause pitch black clipping if set too high.";
> = 2.00;

uniform float fMXAOIndirectLightingAmount <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 12.00;
        ui_label = "Indirect Lighting Amount";
	ui_tooltip = "Linearly increases IL intensity. Can cause overexposured white spots if set too high.\nEnable SSIL in preprocessor section.";
> = 4.00;

uniform float fMXAOIndirectLightingSaturation <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 3.00;
        ui_label = "Indirect Lighting Saturation";
	ui_tooltip = "Boosts IL saturation for more pronounced effect.\nEnable SSIL in preprocessor section.";
> = 1.00;

uniform float fMXAOSampleRadius <
	ui_type = "drag";
	ui_min = 1.00; ui_max = 8.00;
        ui_label = "Sample Radius";
	ui_tooltip = "Sample radius of GI, higher means more large-scale occlusion with less fine-scale details.";
> = 2.50;

uniform int iMXAOSampleCount <
	ui_type = "drag";
	ui_min = 8; ui_max = 255;
        ui_label = "Sample Count";
	ui_tooltip = "Amount of MXAO samples. Higher means more accurate and less noisy AO at the cost of fps.";
> = 24;

uniform int iMXAOBayerDitherLevel <
	ui_type = "drag";
	ui_min = 2; ui_max = 8;
        ui_label = "Dither Size";
	ui_tooltip = "Factor of 'random' rotation pattern size.\nHigher means less distinctive haloing but noisier AO.\nSet Blur Steps to 0 to see effect better.";
> = 3;

uniform float fMXAONormalBias <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.8;
        ui_label = "Normal Bias";
	ui_tooltip = "Normals bias to reduce self-occlusion of surfaces that have a low angle to each other.";
> = 0.2;

uniform bool bMXAOSmoothNormalsEnable <
        ui_label = "Enable Smoothed Normals";
	ui_tooltip = "Enable smoothed normals. WIP.";
> = false;

uniform float fMXAOBlurSharpness <
	ui_type = "drag";
	ui_min = 0.00; ui_max = 5.00;
        ui_label = "Blur Sharpness";
	ui_tooltip = "AO sharpness, higher means sharper geometry edges but noisier AO, less means smoother AO but blurry in the distance.";
> = 2.00;

uniform int fMXAOBlurSteps <
	ui_type = "drag";
	ui_min = 0; ui_max = 5;
        ui_label = "Blur Steps";
	ui_tooltip = "Offset count for AO bilateral blur filter. Higher means smoother but also blurrier AO.";
> = 2;

uniform bool bMXAODebugViewEnable <
        ui_label = "Enable Debug View";
	ui_tooltip = "Enables raw AO/IL output for debugging and tuning purposes.";
> = false;

uniform float fMXAOFadeoutStart <
	ui_type = "drag";
        ui_label = "Fade Out Start";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Fadeout start.";
> = 0.2;

uniform float fMXAOFadeoutEnd <
	ui_type = "drag";
        ui_label = "Fade Out End";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Fadeout end.";
> = 0.4;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Textures, Samplers
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"
#define     AO_BLUR_GAMMA   2.0


texture2D texColorBypass 	{ Width = BUFFER_WIDTH; 			  Height = BUFFER_HEIGHT; 			    Format = RGBA8; MipLevels = 5+MXAO_MIPLEVEL_IL;};
texture2D texDistance 		{ Width = BUFFER_WIDTH; 			  Height = BUFFER_HEIGHT;  			    Format = R16F;  MipLevels = 5+MXAO_MIPLEVEL_AO;};
texture2D texSurfaceNormal	{ Width = BUFFER_WIDTH;                           Height = BUFFER_HEIGHT; 		            Format = RGBA8; MipLevels = 5+MXAO_MIPLEVEL_IL;};
sampler2D SamplerColorBypass	{	Texture = texColorBypass;	};
sampler2D SamplerDistance	{	Texture = texDistance;		};
sampler2D SamplerSurfaceNormal	{	Texture = texSurfaceNormal;	};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Functions
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/* Fetches linearized depth value. depth data ~ distance from camera
   and 0 := camera, 1:= "infinite" distance, e.g. sky. */
float GetLinearDepth(float2 coords)
{
	return ReShade::GetLinearizedDepth(coords);
}

/* Fetches position relative to camera. This is somewhat inaccurate
   as it assumes FoV == 90 degrees but yields good enough results.
   Axes are multiplied with far plane to better scale the occlusion
   falloff and save instruction in AO main pass. Also using a bigger
   data range seems to reduce precision artifacts for logarithmic
   depth buffer option. */
float3 GetPosition(float2 coords)
{
	return float3(coords.xy*2.0-1.0,1.0)*GetLinearDepth(coords.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

/* Same as above, except linearized and scaled data is already stored
   in dedicated texture and we're sampling mipmaps here. */
float3 GetPositionLOD(float2 coords, int mipLevel)
{
	return float3(coords.xy*2.0-1.0,1.0)*tex2Dlod(SamplerDistance, float4(coords.xy,0,mipLevel)).x;
}

/* Calculates normals based on partial depth buffer derivatives.
   Does a similar job to ddx/ddy but this is higher quality and
   it also takes care for object borders where usual ddx/ddy produce
   inaccurate normals.*/
float3 GetNormalFromDepth(float2 coords)
{
	float3 offs = float3(ReShade::PixelSize.xy,0);

	float3 f 	 =       GetPosition(coords.xy);
	float3 d_dx1 	 = - f + GetPosition(coords.xy + offs.xz);
	float3 d_dx2 	 =   f - GetPosition(coords.xy - offs.xz);
	float3 d_dy1 	 = - f + GetPosition(coords.xy + offs.zy);
	float3 d_dy2 	 =   f - GetPosition(coords.xy - offs.zy);

	d_dx1 = lerp(d_dx1, d_dx2, abs(d_dx1.z) > abs(d_dx2.z));
	d_dy1 = lerp(d_dy1, d_dy2, abs(d_dy1.z) > abs(d_dy2.z));

	return normalize(cross(d_dy1,d_dx1));
}

/* Box blur on normal map texture. Yes, it's as stupid as it sounds
   but helps nicely to get rid of too obvious geometry lines in
   landscape where a plain normal bias doesn't cut it. After all
   we're doing approximations over approximations. */
float3 GetSmoothedNormals(float2 texcoord, float3 ScreenSpaceNormals, float3 ScreenSpacePosition)
{
	float4 blurnormal = 0.0;
	[loop]
	for(float x = -3; x <= 3; x++)
	{
		[loop]
		for(float y = -3; y <= 3; y++)
		{
			float2 offsetcoord 	= texcoord.xy + float2(x,y) * ReShade::PixelSize.xy * 3.5;
			float3 samplenormal 	= normalize(tex2Dlod(SamplerSurfaceNormal,float4(offsetcoord,0,2)).xyz * 2.0 - 1.0);
			float3 sampleposition	= GetPositionLOD(offsetcoord.xy,2);
			float weight 		= saturate(1.0 - distance(ScreenSpacePosition.xyz,sampleposition.xyz)*1.2);
			weight 		       *= smoothstep(0.5,1.0,dot(samplenormal,ScreenSpaceNormals));
			blurnormal.xyz += samplenormal * weight;
			blurnormal.w += weight;
		}
	}

	return normalize(blurnormal.xyz / (0.0001 + blurnormal.w) + ScreenSpaceNormals*0.05);
}

/* Fetches normal and depth data for bilateral AO blur weight
   calculation. As we already have linearized depth as own texture,
   we might as well use it and save some instructions, also R16F
   is lower than usual R32F original game depth data.*/
float4 GetBlurFactors(float2 coords)
{
	return float4(tex2Dlod(SamplerSurfaceNormal, float4(coords.xy,0,0)).xyz*2.0-1.0,tex2Dlod(SamplerDistance, float4(coords.xy,0,0)).x);
}

/* Calculates weights for bilateral AO blur. Using only
   depth is surely faster but it doesn't really cut it, also
   areas with a flat angle to the camera will have high depth
   differences, hence blur will cause stripes as seen in many
   AO implementations, even HBAO+. Taking view angle into
   account greatly helps to reduce these problems. */
float GetBlurWeight(float4 tempKey, float4 centerKey, float surfacealignment)
{
	float depthdiff = abs(tempKey.w-centerKey.w);
	float normaldiff = 1.0-saturate(dot(normalize(tempKey.xyz),normalize(centerKey.xyz)));

	float depthweight = saturate(rcp(fMXAOBlurSharpness*depthdiff*5.0*surfacealignment));
	float normalweight = saturate(rcp(fMXAOBlurSharpness*normaldiff*10.0));

	return min(normalweight,depthweight);
}

/* Bilateral blur, exploiting bilinear filter
   for additional blurring. Intel paper covered
   faster gaussian blur with similar offset and
   weight development of discrete gaussian, this
   here is basically the same, only applied on
   box blur. This function only blurs AO and reads
   the normals from RGB channel of backbuffer.*/
float4 GetBlurredAO( float2 texcoord, sampler inputsampler, float2 axis, int nSteps)
{
	float4 tempsample;
	float4 centerkey   , tempkey;
	float  centerweight, tempweight;
	float surfacealignment;
	float4 blurcoord = 0.0;
	float AO         = 0.0;

	tempsample 	 = tex2D(inputsampler,texcoord.xy);
	centerkey 	 = float4(tempsample.xyz*2-1,tex2Dlod(SamplerDistance,float4(texcoord.xy,0,0)).x);
	centerweight     = 0.5;
	AO               = tempsample.w * 0.5;
	surfacealignment = saturate(-dot(centerkey.xyz,normalize(float3(texcoord.xy*2.0-1.0,1.0)*centerkey.w)));

	[loop]
	for(int orientation=-1;orientation<=1; orientation+=2)
	{
		[loop]
		for(float iStep = 1.0; iStep <= nSteps; iStep++)
		{
			blurcoord.xy 	= (2.0 * iStep - 0.5) * orientation * axis * ReShade::PixelSize.xy + texcoord.xy;
			tempsample = tex2Dlod(inputsampler, blurcoord);
			tempkey    = float4(tempsample.xyz*2-1,tex2Dlod(SamplerDistance,blurcoord).x);
			tempweight = GetBlurWeight(tempkey, centerkey, surfacealignment);
			AO += tempsample.w * tempweight;
			centerweight   += tempweight;
		}
	}

	return float4(centerkey.xyz*0.5+0.5, AO / centerweight);
}

/* Same as above, except it blurs RGBA and hence
   needs to read normals separately. */
float4 GetBlurredAOIL( float2 texcoord, sampler inputsampler, float2 axis, int nSteps)
{
	float4 tempsample;
	float4 centerkey   , tempkey;
	float  centerweight, tempweight;
	float surfacealignment;
	float4 blurcoord = 0.0;
	float4 AO_IL         = 0.0;

	tempsample 	 = tex2D(inputsampler,texcoord.xy);
	centerkey 	 = float4(tex2Dlod(SamplerSurfaceNormal,float4(texcoord.xy,0,0)).xyz*2-1,tex2Dlod(SamplerDistance,float4(texcoord.xy,0,0)).x);
	centerweight     = 0.5;
	AO_IL            = tempsample * 0.5;
	surfacealignment = saturate(-dot(centerkey.xyz,normalize(float3(texcoord.xy*2.0-1.0,1.0)*centerkey.w)));

	[loop]
	for(int orientation=-1;orientation<=1; orientation+=2)
	{
		[loop]
		for(float iStep = 1.0; iStep <= nSteps; iStep++)
		{
			blurcoord.xy 	= (2.0 * iStep - 0.5) * orientation * axis * ReShade::PixelSize.xy + texcoord.xy;
			tempsample = tex2Dlod(inputsampler, blurcoord);
			tempkey    = float4(tex2Dlod(SamplerSurfaceNormal,blurcoord).xyz*2-1,tex2Dlod(SamplerDistance,blurcoord).x);
			tempweight = GetBlurWeight(tempkey, centerkey, surfacealignment);
			AO_IL += tempsample * tempweight;
			centerweight   += tempweight;
		}
	}

	return float4(AO_IL / centerweight);
}

/* Calculates the bayer dither pattern that's used to jitter
   the direction of the AO samples per pixel.
   Why this instead of precalculated texture? BECAUSE I CAN.
   Using this ordered jitter instead of a pseudorandom one
   has 3 advantages: it seems to be more cache-aware, the AO
   is (given a fitting AO sample distribution pattern) a lot less
   noisy (better variance, see Alchemy AO) and bilateral blur
   needs a much smaller kernel: from my tests a blur kernel
   of 5x5 is fine for most settings, but using a pseudorandom
   distribution still has noticeable grain with 12x12++.
   Smaller bayer matrix sizes have more obvious directional
   AO artifacts but are easier to blur. */
float GetBayerFromCoordLevel(float2 pixelpos, int maxLevel)
{
	float finalBayer = 0.0;

	for(float i = 1-maxLevel; i<= 0; i++)
	{
		float bayerSize = exp2(i);
	        float2 bayerCoord = floor(pixelpos * bayerSize) % 2.0;
		float bayer = 2.0 * bayerCoord.x - 4.0 * bayerCoord.x * bayerCoord.y + 3.0 * bayerCoord.y;
		finalBayer += exp2(2.0*(i+maxLevel))* bayer;
	}

	float finalDivisor = 4.0 * exp2(2.0 * maxLevel)- 4.0;
	//raising all values by increment is false but in AO pass it makes sense. Can you see it?
	return finalBayer/ finalDivisor + 1.0/exp2(2.0 * maxLevel);
}

/* Main AO pass. The samples are taken in an outward spiral,
   that way a simple rotation matrix is enough to provide
   the sample locations. The rotation angle is fine-tuned,
   it yields an optimal (optimal as in "I couldn't find a better one")
   sample distribution. Vogel algorithm uses the golden angle,
   and samples are more uniformly distributed over the disc but
   AO quality suffers a lot of samples are lining up (having the
   same sampling direction). Test it yourself: make angle depending
   on texcoord.x and you'll see that AO quality is highly depending
   on angle. Mara and McGuire solve this in their Alchemy AO approach
   by providing a hand-selected rotation for each sample count,
   however my angle seems to produce better results and doesn't require
   declaring a huge constant array or any CPU side code. */
float4 GetMXAO(float2 texcoord, float3 normal, float3 position, float nSamples, float2 currentVector, float mipFactor, float fNegInvR2, float radiusJitter, float sampleRadius)
{
	float4 AO_IL = 0.0;
	float2 currentOffset;

	[loop]
	for(int iSample=0; iSample < nSamples; iSample++)
	{
		currentVector = mul(currentVector.xy, float2x2(0.575,0.81815,-0.81815,0.575));
		currentOffset = texcoord.xy + currentVector.xy * float2(1.0,ReShade::AspectRatio) * (iSample + radiusJitter);

		float mipLevel = saturate(log2(mipFactor*iSample)*0.2 - 0.6) * 5.0;

		float3 occlVec 		= -position + GetPositionLOD(currentOffset.xy, mipLevel);
		float  occlDistanceRcp 	= rsqrt(dot(occlVec,occlVec));
		float  occlAngle 	= dot(occlVec, normal)*occlDistanceRcp;

		float fAO = saturate(1.0 + fNegInvR2/occlDistanceRcp)  * saturate(occlAngle - fMXAONormalBias);

		#if(MXAO_ENABLE_IL != 0)
			float3 fIL = tex2Dlod(SamplerColorBypass, float4(currentOffset,0,mipLevel + MXAO_MIPLEVEL_IL)).xyz;
			#if(MXAO_ENABLE_BACKFACE != 0)
				float3 offsetNormals = normalize(tex2Dlod(SamplerSurfaceNormal, float4(currentOffset,0,mipLevel + MXAO_MIPLEVEL_IL)).xyz * 2.0 - 1.0);
				float facingtoSource = dot(occlVec,offsetNormals)*occlDistanceRcp;
				fIL = fIL - fIL*saturate(facingtoSource*2.0);
			#endif
			AO_IL.w += fAO - fAO * saturate(dot(fIL,float3(0.299,0.587,0.114)));
			AO_IL.xyz += fIL*fAO;
		#else
			AO_IL.w += fAO;
		#endif
	}

	return saturate(AO_IL/(0.4*(1.0-fMXAONormalBias)*nSamples*sqrt(sampleRadius)));
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Pixel Shaders
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/* Setup color, depth and normal data. Alpha channel of normal
   texture provides the per pixel jitter for AO sampling. */
void PS_AO_Pre(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0, out float4 depth : SV_Target1, out float4 normal : SV_Target2)
{
	color 		= tex2D(ReShade::BackBuffer, texcoord.xy);
	depth 		= GetLinearDepth(texcoord.xy)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	normal.xyz 	= GetNormalFromDepth(texcoord.xy).xyz * 0.5 + 0.5;
	normal.w	= GetBayerFromCoordLevel(vpos.xy,iMXAOBayerDitherLevel);
}

void PS_AO_Gen(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float4 normalSample = tex2D(SamplerSurfaceNormal, texcoord.xy);

	float3 ScreenSpaceNormals = normalSample.xyz * 2.0 - 1.0;
	float3 ScreenSpacePosition = GetPositionLOD(texcoord.xy, 0);

	[branch]
	if(bMXAOSmoothNormalsEnable)
	{
		ScreenSpaceNormals = GetSmoothedNormals(texcoord, ScreenSpaceNormals, ScreenSpacePosition);
	}

	float scenedepth = ScreenSpacePosition.z / RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	ScreenSpacePosition += ScreenSpaceNormals * scenedepth;

	float SampleRadiusScaled  = 0.2*fMXAOSampleRadius*fMXAOSampleRadius / (iMXAOSampleCount * ScreenSpacePosition.z);
	float mipFactor = SampleRadiusScaled * 3200.0;

	float2 currentVector;
	sincos(2.0*3.14159274*normalSample.w, currentVector.y, currentVector.x);
	static const float fNegInvR2 = -1.0/(fMXAOSampleRadius*fMXAOSampleRadius);
	currentVector *= SampleRadiusScaled;

	res = GetMXAO(texcoord,
		      ScreenSpaceNormals,
		      ScreenSpacePosition,
		      iMXAOSampleCount,
		      currentVector,
		      mipFactor,
		      fNegInvR2,
		      normalSample.w,
		      fMXAOSampleRadius);

	res = pow(abs(res),1.0 / AO_BLUR_GAMMA);

	#if(MXAO_ENABLE_IL == 0)
		res.xyz = normalSample.xyz;
	#endif
}

/* Box blur instead of gaussian seems to produce better
   results for low kernel sizes. The offsets and weights
   here make use of bilinear sampling, hence sampling
   in 1.5 .. 3.5 ... 5.5 pixel offsets.*/
void PS_AO_Blur1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	#if(MXAO_ENABLE_IL != 0)
		res = GetBlurredAOIL(texcoord.xy, ReShade::BackBuffer, float2(1.0,0.0), fMXAOBlurSteps);
	#else
		res = GetBlurredAO(texcoord.xy, ReShade::BackBuffer, float2(1.0,0.0), fMXAOBlurSteps);
	#endif
}

/* Second box blur pass and AO/IL combine. The given formula
   yields to actual physical background or anything, it's just
   a lot more visually pleasing than most formulas of similar
   implementations.*/
void PS_AO_Blur2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	#if(MXAO_ENABLE_IL != 0)
		float4 MXAO = GetBlurredAOIL(texcoord.xy, ReShade::BackBuffer, float2(0.0,1.0), fMXAOBlurSteps);
		MXAO = pow(saturate(MXAO),AO_BLUR_GAMMA);
	#else
		float4 MXAO = GetBlurredAO(texcoord.xy, ReShade::BackBuffer, float2(0.0,1.0), fMXAOBlurSteps);
		MXAO.xyz = 0;
		MXAO.w = pow(saturate(MXAO.w),AO_BLUR_GAMMA);
	#endif

	float scenedepth = GetLinearDepth(texcoord.xy);
	float4 color = max(0.0,tex2D(SamplerColorBypass, texcoord.xy));
	float colorgray = dot(color.xyz,float3(0.299,0.587,0.114));

	MXAO.xyz  = lerp(dot(MXAO.xyz,float3(0.299,0.587,0.114)),MXAO.xyz,fMXAOIndirectLightingSaturation) * fMXAOIndirectLightingAmount * 4;
	MXAO.w    = 1.0-pow(1.0-MXAO.w, fMXAOAmbientOcclusionAmount*4.0);

	MXAO    = (bMXAODebugViewEnable) ? MXAO : lerp(MXAO, 0.0, pow(colorgray,2.0));

	MXAO.w    = lerp(MXAO.w, 0.0,smoothstep(fMXAOFadeoutStart, fMXAOFadeoutEnd, scenedepth));
	MXAO.xyz  = lerp(MXAO.xyz,0.0,smoothstep(fMXAOFadeoutStart*0.5, fMXAOFadeoutEnd*0.5, scenedepth));

	float3 GI = MXAO.w - MXAO.xyz;
	GI = max(0.0,1-GI);
	color.xyz *= GI;

	if(bMXAODebugViewEnable) //can't move this into ternary as one is preprocessor def and the other is a uniform
	{
		color.xyz = (MXAO_ENABLE_IL != 0) ? GI*0.5 : GI;
	}

	res = color;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Technique
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique MXAO
{
	pass P0
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Pre;
		RenderTarget0 = texColorBypass;
		RenderTarget1 = texDistance;
		RenderTarget2 = texSurfaceNormal;
	}
	pass P1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Gen;
		/*Render Target is Backbuffer*/
	}
	pass P2_0
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Blur1;
		/*Render Target is Backbuffer*/
	}
	pass P2_1
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_AO_Blur2;
		/*Render Target is Backbuffer*/
	}
}
