//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//LICENSE AGREEMENT AND DISTRIBUTION RULES:
//1 Copyrights of the Master Effect exclusively belongs to author - Gilcher Pascal aka Marty McFly.
//2 Master Effect (the SOFTWARE) is DonateWare application, which means you may or may not pay for this software to the author as donation.
//3 If included in ENB presets, credit the author (Gilcher Pascal aka Marty McFly).
//4 Software provided "AS IS", without warranty of any kind, use it on your own risk. 
//5 You may use and distribute software in commercial or non-commercial uses. For commercial use it is required to warn about using this software (in credits, on the box or other places). Commercial distribution of software as part of the games without author permission prohibited.
//6 Author can change license agreement for new versions of the software.
//7 All the rights, not described in this license agreement belongs to author.
//8 Using the Master Effect means that user accept the terms of use, described by this license agreement.
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//For more information about license agreement contact me:
//https://www.facebook.com/MartyMcModding
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Copyright (c) 2009-2015 Gilcher Pascal aka Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Credits :: Boris Vorontsov (Lenz), Matso (Anamorphic lensflare), icelaglace (Lenz offsets), AAA aka opezdl (Lenz code parts)
//Credits :: PetkaGtA (Lightscattering implementation)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include EFFECT_CONFIG(Ganossa)

#if (USE_BLOOM || USE_LENSDIRT || USE_GAUSSIAN_ANAMFLARE || USE_LENZFLARE || USE_CHAPMAN_LENS || USE_GODRAYS || USE_ANAMFLARE)

#pragma message "Bloom by Ganossa"
#if USE_LENZFLARE
	#pragma message "Lenz by Boris Vorontsov, icelaglace, AAA aka opezdl\n"
#endif
#if USE_ANAMFLARE
	#pragma message "Anamorphic Lensflare by Matso\n"
#endif

#if AL_Adaptation && USE_AMBIENT_LIGHT
#include "BrightDetect.fx"
#endif

#if( Ganossa_HDR_MODE == 0)
 #define Ganossa_RENDERMODE RGBA8
#elif( Ganossa_HDR_MODE == 1)
 #define Ganossa_RENDERMODE RGBA16F
#else
 #define Ganossa_RENDERMODE RGBA32F
#endif

namespace Ganossa
{

//textures
texture   texBloom1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = Ganossa_RENDERMODE;};
texture   texBloom2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = Ganossa_RENDERMODE;};
texture   texBloom3 { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = Ganossa_RENDERMODE;};
texture   texBloom4 { Width = BUFFER_WIDTH/4; Height = BUFFER_HEIGHT/4; Format = Ganossa_RENDERMODE;};
texture   texBloom5 { Width = BUFFER_WIDTH/8; Height = BUFFER_HEIGHT/8; Format = Ganossa_RENDERMODE;};

texture   Ganossa_texHDR1 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;  Format = Ganossa_RENDERMODE;};
texture   Ganossa_texHDR2 	{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT;  Format = Ganossa_RENDERMODE;};

texture   texDirt   < string source = "ReShade/Shaders/Ganossa/Textures/" lensDirtTex ;   > {Width = BUFFER_WIDTH;Height = BUFFER_HEIGHT;Format = RGBA8;};

texture   texLens1 { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = Ganossa_RENDERMODE;};
texture   texLens2 { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = Ganossa_RENDERMODE;};
texture   texSprite < string source = "ReShade/Shaders/Ganossa/Textures/Ganossa_sprite.png"; > {Width = BUFFER_WIDTH;Height = BUFFER_HEIGHT;Format = RGBA8;};

//samplers
sampler SamplerLens1 { Texture = texLens1; };
sampler SamplerLens2 { Texture = texLens2; };

sampler SamplerBloom1 { Texture = texBloom1; };
sampler SamplerBloom2 { Texture = texBloom2; };
sampler SamplerBloom3 { Texture = texBloom3; };
sampler SamplerBloom4 { Texture = texBloom4; };
sampler SamplerBloom5 { Texture = texBloom5; };

sampler2D Ganossa_SamplerHDR1
{
	Texture = Ganossa_texHDR1;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=8;
	MipMapLodBias=0;
};

sampler2D Ganossa_SamplerHDR2
{
	Texture = Ganossa_texHDR2;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=8;
	MipMapLodBias=0;
};

sampler2D SamplerSprite
{
	Texture = texSprite;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU = Clamp;
	AddressV = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

sampler2D SamplerDirt
{
	Texture = texDirt;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = NONE;
	AddressU = Clamp;
	AddressV = Clamp;
	SRGBTexture=FALSE;
	MaxMipLevel=0;
	MipMapLodBias=0;
};

void PS_Init(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdrT : SV_Target0) 
{
	hdrT = tex2D(ReShade::OriginalColor, texcoord.xy);
}

float4 GaussBlur22(float2 coord, sampler tex, float mult, float lodlevel, bool isBlurVert) //texcoord, texture, blurmult in pixels, tex2dlod level, axis (0=horiz, 1=vert)
{
	float4 sum = 0;
	float2 axis = (isBlurVert) ? float2(0, 1) : float2(1, 0);
	float  weight[11] = {0.082607, 0.080977, 0.076276, 0.069041, 0.060049, 0.050187, 0.040306, 0.031105, 0.023066, 0.016436, 0.011254};

	for(int i=-10; i < 11; i++)
	{
		float currweight = weight[abs(i)];	
		sum	+= tex2Dlod(tex, float4(coord.xy + axis.xy * (float)i * ReShade::PixelSize * mult,0,lodlevel)) * currweight;
	}

	return sum;

}

float3 GetDnB (sampler2D tex, float2 coords)
{
	float3 Color = max(0,dot(tex2Dlod(tex,float4(coords.xy,0,4)).rgb,0.333) - ChapFlareTreshold)*ChapFlareIntensity;
	#if(CHAPMAN_DEPTH_CHECK == 1)
	if(tex2Dlod(ReShade::OriginalDepth,float4(coords.xy,0,3)).x<0.99999) Color = 0;
	#endif
	return Color;
}

float2 GetFlippedTC(float2 texcoords) 
{
	return -texcoords + 1.0;
}

float3 GetDistortedTex(
	sampler2D tex,
	float2 sample_center, // where we'd normally sample
	float2 sample_vector,
	float3 distortion // per-channel distortion coeffs
) {

	float2 final_vector = sample_center + sample_vector * min(min(distortion.r, distortion.g),distortion.b); 

	if(final_vector.x > 1.0 
	|| final_vector.y > 1.0 
	|| final_vector.x < -1.0 
	|| final_vector.y < -1.0)
	return 0;

	else return float3(
		GetDnB(tex,sample_center + sample_vector * distortion.r).r,
		GetDnB(tex,sample_center + sample_vector * distortion.g).g,
		GetDnB(tex,sample_center + sample_vector * distortion.b).b
	);
}

float3 GetBrightPass(float2 tex)
{
	float3 c = tex2D(Ganossa_SamplerHDR1, tex).rgb;
    	float3 bC = max(c - float3(fFlareLuminance, fFlareLuminance, fFlareLuminance), 0.0);
    	float bright = dot(bC, 1.0);
    	bright = smoothstep(0.0f, 0.5, bright);
	float3 result = lerp(0.0, c, bright);
#if (FLARE_DEPTH_CHECK == 1)
	float checkdepth = tex2D(ReShade::OriginalDepth, tex).x;
	if(checkdepth < 0.99999) result = 0;
#endif
	return result;

}

float3 GetAnamorphicSample(int axis, float2 tex, float blur)
{
	tex = 2.0 * tex - 1.0;
	tex.x /= -blur;
	tex = 0.5 * tex + 0.5;
	return GetBrightPass(tex);
}

void LensPrepass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 lensT : SV_Target0)
{
	float4 lens=0;

#if (USE_LENZFLARE == 1)

	float3 lfoffset[19]={
		float3(0.9, 0.01, 4),
		float3(0.7, 0.25, 25),
		float3(0.3, 0.25, 15),
		float3(1, 1.0, 5),
		float3(-0.15, 20, 1),
		float3(-0.3, 20, 1),
		float3(6, 6, 6),
		float3(7, 7, 7),
		float3(8, 8, 8),
		float3(9, 9, 9),
		float3(0.24, 1, 10),
		float3(0.32, 1, 10),
		float3(0.4, 1, 10),
		float3(0.5, -0.5, 2),
		float3(2, 2, -5),
		float3(-5, 0.2, 0.2),
		float3(20, 0.5, 0),
		float3(0.4, 1, 10),
		float3(0.00001, 10, 20)
	};

	float3 lffactors[19]={
		float3(1.5, 1.5, 0),
		float3(0, 1.5, 0),
		float3(0, 0, 1.5),
		float3(0.2, 0.25, 0),
		float3(0.15, 0, 0),
		float3(0, 0, 0.15),
		float3(1.4, 0, 0),
		float3(1, 1, 0),
		float3(0, 1, 0),
		float3(0, 0, 1.4),
		float3(1, 0.3, 0),
		float3(1, 1, 0),
		float3(0, 2, 4),
		float3(0.2, 0.1, 0),
		float3(0, 0, 1),
		float3(1, 1, 0),
		float3(1, 1, 0),
		float3(0, 0, 0.2),
 	       	float3(0.012,0.313,0.588)
	};

	float3 lenstemp = 0;

	float2 lfcoord = float2(0,0);
	float2 distfact=(texcoord.xy-0.5);
	distfact.x *= ReShade::AspectRatio;

	for (int i=0; i<19; i++)
	{
		lfcoord.xy=lfoffset[i].x*distfact;
		lfcoord.xy*=pow(2.0*length(float2(distfact.x,distfact.y)), lfoffset[i].y*3.5);
		lfcoord.xy*=lfoffset[i].z;
		lfcoord.xy=0.5-lfcoord.xy;
		float2 tempfact = (lfcoord.xy-0.5)*2;
		float templensmult = clamp(1.0-dot(tempfact,tempfact),0,1);
		float3 lenstemp1 = dot(tex2Dlod(Ganossa_SamplerHDR1, float4(lfcoord.xy,0,1)).xyz,0.333);

#if (LENZ_DEPTH_CHECK == 1)
		float templensdepth = tex2D(ReShade::OriginalDepth, lfcoord.xy).x;
		if(templensdepth < 0.99999) lenstemp1 = 0;
#endif	
	
		lenstemp1 = max(0,lenstemp1.xyz - fLenzThreshold);
		lenstemp1 *= lffactors[i].xyz*templensmult;

		lenstemp += lenstemp1;
	}

	lens.xyz += lenstemp.xyz*fLenzIntensity;
#endif

#if(USE_CHAPMAN_LENS == 1)
	float2 sample_vector = (float2(0.5,0.5) - texcoord.xy) * ChapFlareDispersal;
	float2 halo_vector = normalize(sample_vector) * ChapFlareSize;

	float3 chaplens = GetDistortedTex(Ganossa_SamplerHDR1, texcoord.xy + halo_vector,halo_vector,ChapFlareCA*2.5f).rgb;

	for (int j = 0; j < ChapFlareCount; ++j) 
	{
		float2 foffset = sample_vector * float(j);
		chaplens += GetDistortedTex(Ganossa_SamplerHDR1, texcoord.xy + foffset,foffset,ChapFlareCA).rgb;

	}
	chaplens *= 1/float(ChapFlareCount);
	lens.xyz += chaplens;
#endif

#if(USE_GODRAYS == 1)
	float2 ScreenLightPos = float2(0.5, 0.5);
	float2 texCoord = texcoord.xy;
	float2 deltaTexCoord = (texCoord.xy - ScreenLightPos.xy);
	deltaTexCoord *= 1.0 / (float)iGodraySamples * fGodrayDensity;


	float illuminationDecay = 1.0;

	for(int g = 0; g < iGodraySamples; g++) {
	
		texCoord -= deltaTexCoord;;
		float4 sample2 = tex2D(Ganossa_SamplerHDR1, texCoord.xy);
		float sampledepth = tex2D(ReShade::OriginalDepth, texCoord.xy).x;
		sample2.w = saturate(dot(sample2.xyz, 0.3333) - fGodrayThreshold);
		sample2.r *= 1.0;
		sample2.g *= 0.95;
		sample2.b *= 0.85;
		sample2 *= illuminationDecay * fGodrayWeight;
#if (GODRAY_DEPTH_CHECK == 1)
		if(sampledepth>0.99999) lens.xyz += sample2.xyz*sample2.w;
#else
		lens.xyz += sample2.xyz*sample2.w;
#endif
		illuminationDecay *= fGodrayDecay;
	}
#endif

#if(USE_ANAMFLARE == 1)
	float3 anamFlare=0;
	float gaussweight[5] = {0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162};
	for(int z=-4; z < 5; z++)
	{
		anamFlare+=GetAnamorphicSample(0, texcoord.xy + float2(0, z * ReShade::PixelSize.y * 2), fFlareBlur) * fFlareTint* gaussweight[abs(z)];
	}
	lens.xyz += anamFlare * fFlareIntensity;
#endif

	lensT = lens;
}

void LensPass1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 lensT : SV_Target0)
{
	lensT = GaussBlur22(texcoord.xy, SamplerLens1, 2, 0, 1);	
}

void LensPass2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 lensT : SV_Target0)
{
	lensT = GaussBlur22(texcoord.xy, SamplerLens2, 2, 0, 0);	
}

void PS_BloomPrePass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloomT : SV_Target0)
{
	
	float4 bloom=0.0;
	float2 bloomuv;

	float2 offset[4]=
	{
		float2(1.0, 1.0),
		float2(1.0, 1.0),
		float2(-1.0, 1.0),
		float2(-1.0, -1.0)
	};

	for (int i=0; i<4; i++)
	{
		bloomuv.xy=offset[i]*ReShade::PixelSize.xy*2;
		bloomuv.xy=texcoord.xy + bloomuv.xy;
		float4 tempbloom=tex2Dlod(ReShade::OriginalColor, float4(bloomuv.xy, 0, 0));
		tempbloom.w = max(0,dot(tempbloom.xyz,0.333)-fAnamFlareThreshold);
		tempbloom.xyz = max(0, tempbloom.xyz-fBloomThreshold); 
		bloom+=tempbloom;
	}

	bloom *= 0.25;
	bloomT = bloom;
}

void PS_BloomPass1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloomT : SV_Target0)
{

	float4 bloom=0.0;
	float2 bloomuv;

	float2 offset[8]=
	{
		float2(1.0, 1.0),
		float2(0.0, -1.0),
		float2(-1.0, 1.0),
		float2(-1.0, -1.0),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};

	for (int i=0; i<8; i++)
	{
		bloomuv.xy=offset[i]*ReShade::PixelSize.xy*4;
		bloomuv.xy=texcoord.xy + bloomuv.xy;
		float4 tempbloom=tex2Dlod(SamplerBloom1, float4(bloomuv.xy, 0, 0));
		bloom+=tempbloom;
	}

	bloom *= 0.125;
	bloomT = bloom;
}

void PS_BloomPass2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloomT : SV_Target0)
{

	float4 bloom=0.0;
	float2 bloomuv;

	float2 offset[8]=
	{
		float2(0.707, 0.707),
		float2(0.707, -0.707),
		float2(-0.707, 0.707),
		float2(-0.707, -0.707),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};

	for (int i=0; i<8; i++)
	{
		bloomuv.xy=offset[i]*ReShade::PixelSize.xy*8;
		bloomuv.xy=texcoord.xy + bloomuv.xy;
		float4 tempbloom=tex2Dlod(SamplerBloom2, float4(bloomuv.xy, 0, 0));
		bloom+=tempbloom;
	}

	bloom *= 0.5; //to brighten up the sample, it will lose brightness in H/V gaussian blur 
	bloomT = bloom;
}

void PS_BloomPass3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloomT : SV_Target0)
{
	float4 bloom = 0.0;
	bloom = GaussBlur22(texcoord.xy, SamplerBloom3, 16, 0, 0);
	bloom.a *= fAnamFlareAmount;
	bloom.xyz *= fBloomAmount;

#if AL_Adaptation && USE_AMBIENT_LIGHT
//DetectLow	
	float4 detectLow = tex2D(detectLowColor, 0.5)/4.215;
	float low = sqrt(0.241*detectLow.r*detectLow.r+0.691*detectLow.g*detectLow.g+0.068*detectLow.b*detectLow.b);
//.DetectLow

	float adapt = low*(low+1.0f)*alAdapt*alInt*5.0f;
	bloom.xyz *= max(0.0f,(1.0f - adapt*0.1f*alAdaptBloomMult));
	bloom.a *= max(0.0f,(1.0f - adapt*0.1f*alAdaptFlareMult));
#endif

	bloomT = bloom;
}

void PS_BloomPass4(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloomT : SV_Target0)
{
	float4 bloom = 0.0;
	bloom.xyz = GaussBlur22(texcoord.xy, SamplerBloom4, 16, 0, 1).xyz*2.5;	
	bloom.w   = GaussBlur22(texcoord.xy, SamplerBloom4, 32*fAnamFlareWideness, 0, 0).w*2.5; //to have anamflare texture (bloom.w) avoid vertical blur
	bloomT = bloom;
}

void PS_LightingCombine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdrT : SV_Target0)
{
 
	//float4 color = tex2D(Ganossa_SamplerHDR2, texcoord.xy);
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);

	float3 colorbloom=0;

	colorbloom.xyz += tex2D(SamplerBloom3, texcoord.xy).xyz*1.0;
	colorbloom.xyz += tex2D(SamplerBloom5, texcoord.xy).xyz*9.0;
	colorbloom.xyz *= 0.1;

	colorbloom.xyz = saturate(colorbloom.xyz);
	float colorbloomgray = dot(colorbloom.xyz, 0.333);
	colorbloom.xyz = lerp(colorbloomgray, colorbloom.xyz, fBloomSaturation);
	colorbloom.xyz *= fBloomTint;
	float colorgray = dot(color.xyz, 0.333);

#if(BLOOM_MIXMODE == 1) 
	color.xyz = color.xyz + colorbloom.xyz; 
#endif
#if(BLOOM_MIXMODE == 2) 
	color.xyz = 1-(1-color.xyz)*(1-colorbloom.xyz); 
#endif
#if(BLOOM_MIXMODE == 3) 
	color.xyz = max(0.0f,max(color.xyz,lerp(color.xyz,(1.0f - (1.0f - saturate(colorbloom.xyz)) *(1.0f - saturate(colorbloom.xyz * 1.0))),1.0))); 
#endif
#if(BLOOM_MIXMODE == 4) 
	color.xyz = max(color.xyz, colorbloom.xyz); 
#endif

#if(USE_GAUSSIAN_ANAMFLARE == 1)
	float3 anamflare = tex2D(SamplerBloom5, texcoord.xy).w*2*fAnamFlareColor;
	anamflare.xyz = max(anamflare.xyz,0);
	color.xyz += pow(anamflare.xyz,1/fAnamFlareCurve);
#endif

#if(USE_LENSDIRT == 1)
	float lensdirtmult = dot(tex2D(SamplerBloom5, texcoord.xy).xyz,0.333);
	float3 dirttex = tex2D(SamplerDirt, texcoord.xy).xyz;
	float3 lensdirt = dirttex.xyz*lensdirtmult*fLensdirtIntensity;
	
	lensdirt = lerp(dot(lensdirt.xyz,0.333), lensdirt.xyz, fLensdirtSaturation);
	if(iLensdirtMixmode == 1) color.xyz = color.xyz + lensdirt.xyz;
	if(iLensdirtMixmode == 2) color.xyz = 1-(1-color.xyz)*(1-lensdirt.xyz);
	if(iLensdirtMixmode == 3) color.xyz = max(0.0f,max(color.xyz,lerp(color.xyz,(1.0f - (1.0f - saturate(lensdirt.xyz)) *(1.0f - saturate(lensdirt.xyz * 1.0))),1.0)));
	if(iLensdirtMixmode == 4) color.xyz = max(color.xyz, lensdirt.xyz);
#endif


	float3 LensflareSample = tex2D(SamplerLens1, texcoord.xy).xyz;
	float3 LensflareMask   = tex2D(SamplerSprite, texcoord.xy+float2(0.5,0.5)*ReShade::PixelSize.xy).xyz;
	LensflareMask   += tex2D(SamplerSprite, texcoord.xy+float2(-0.5,0.5)*ReShade::PixelSize.xy).xyz;
	LensflareMask   += tex2D(SamplerSprite, texcoord.xy+float2(0.5,-0.5)*ReShade::PixelSize.xy).xyz;
	LensflareMask   += tex2D(SamplerSprite, texcoord.xy+float2(-0.5,-0.5)*ReShade::PixelSize.xy).xyz;

	color.xyz += LensflareMask*0.25*LensflareSample;


	hdrT = color;

}

float4 PS_Overlay(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 color = tex2D(Ganossa_SamplerHDR1, texcoord.xy);
	return color;
}

technique Bloom_Tech <bool enabled = 
#if (Bloom_TimeOut > 0)
1; int toggle = Bloom_ToggleKey; timeout = Bloom_TimeOut; >
#else
RESHADE_START_ENABLED; int toggle = Bloom_ToggleKey; >
#endif
{
	pass ME_Init						//later, numerous DOF shaders have different passnumber but later passes depend
	{							//on fixed HDR1 HDR2 HDR1 HDR2... sequence so a 2 pass DOF outputs HDR1 in pass 1 and 	
		VertexShader = ReShade::VS_PostProcess;			//HDR2 in second pass, a 3 pass DOF outputs HDR2, HDR1, HDR2 so last pass outputs always HDR2
		PixelShader = PS_Init;
		RenderTarget = Ganossa_texHDR1;
	}

	pass ME_Init						//later, numerous DOF shaders have different passnumber but later passes depend
	{							//on fixed HDR1 HDR2 HDR1 HDR2... sequence so a 2 pass DOF outputs HDR1 in pass 1 and 	
		VertexShader = ReShade::VS_PostProcess;			//HDR2 in second pass, a 3 pass DOF outputs HDR2, HDR1, HDR2 so last pass outputs always HDR2
		PixelShader = PS_Init;
		RenderTarget = Ganossa_texHDR2;
	}

	pass BloomPrePass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_BloomPrePass;
		RenderTarget = texBloom1;
	}
	
	pass BloomPass1
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_BloomPass1;
		RenderTarget = texBloom2;
	}

	pass BloomPass2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_BloomPass2;
		RenderTarget = texBloom3;
	}

	pass BloomPass3
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_BloomPass3;
		RenderTarget = texBloom4;
	}

	pass BloomPass4
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_BloomPass4;
		RenderTarget = texBloom5;
	}

#if (USE_LENZFLARE == 1 || USE_CHAPMAN_LENS == 1 || USE_GODRAYS == 1 || USE_ANAMFLARE == 1)
	pass LensPrepass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = LensPrepass;
		RenderTarget = texLens1;
	}
	
	pass LensPass1
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = LensPass1;
		RenderTarget = texLens2;
	}

	pass LensPass2
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = LensPass2;
		RenderTarget = texLens1;
	}
#endif

	pass LightingCombine
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_LightingCombine;
		RenderTarget = Ganossa_texHDR1;
	}

	pass Overlay
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Overlay;
	}
}

}

#endif

#include "ReShade/Shaders/Ganossa.undef" 
