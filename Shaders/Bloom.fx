// Copyright (c) 2009-2015 Gilcher Pascal aka Marty McFly

#include "ReShadeUI.fxh"

uniform int iBloomMixmode <
	ui_type = "combo";
	ui_items = "Linear add\0Screen add\0Screen/Lighten/Opacity\0Lighten\0";
> = 2;
uniform float fBloomThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1; ui_max = 1.0;
	ui_tooltip = "Every pixel brighter than this value triggers bloom.";
> = 0.8;
uniform float fBloomAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 20.0;
	ui_tooltip = "Intensity of bloom.";
> = 0.8;
uniform float fBloomSaturation < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Bloom saturation. 0.0 means white bloom, 2.0 means very, very colorful bloom.";
> = 0.8;
uniform float3 fBloomTint < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "R, G and B components of bloom tint the bloom color gets shifted to.";
> = float3(0.7, 0.8, 1.0);

uniform bool bLensdirtEnable <
> = false;
uniform int iLensdirtMixmode <
	ui_type = "combo";
	ui_items = "Linear add\0Screen add\0Screen/Lighten/Opacity\0Lighten\0";
> = 1;
uniform float fLensdirtIntensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Intensity of lensdirt.";
> = 0.4;
uniform float fLensdirtSaturation < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Color saturation of lensdirt.";
> = 2.0;
uniform float3 fLensdirtTint < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "R, G and B components of lensdirt tint the lensdirt color gets shifted to.";
> = float3(1.0, 1.0, 1.0);

uniform bool bAnamFlareEnable <
> = false;
uniform float fAnamFlareThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1; ui_max = 1.0;
	ui_tooltip = "Every pixel brighter than this value gets a flare.";
> = 0.9;
uniform float fAnamFlareWideness < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 2.5;
	ui_tooltip = "Horizontal wideness of flare. Don't set too high, otherwise the single samples are visible.";
> = 2.4;
uniform float fAnamFlareAmount < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 20.0;
	ui_tooltip = "Intensity of anamorphic flare.";
> = 14.5;
uniform float fAnamFlareCurve < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 2.0;
	ui_tooltip = "Intensity curve of flare with distance from source.";
> = 1.2;
uniform float3 fAnamFlareColor < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "R, G and B components of anamorphic flare. Flare is always same color.";
> = float3(0.012, 0.313, 0.588);

uniform bool bLenzEnable <
> = false;
uniform float fLenzIntensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.2; ui_max = 3.0;
	ui_tooltip = "Power of lens flare effect";
> = 1.0;
uniform float fLenzThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.6; ui_max = 1.0;
	ui_tooltip = "Minimum brightness an object must have to cast lensflare.";
> = 0.8;

uniform bool bChapFlareEnable <
> = false;
uniform float fChapFlareTreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.70; ui_max = 0.99;
	ui_tooltip = "Brightness threshold for lensflare generation. Everything brighter than this value gets a flare.";
> = 0.90;
uniform int iChapFlareCount < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 20;
	ui_tooltip = "Number of single halos to be generated. If set to 0, only the curved halo around is visible.";
> = 15;
uniform float fChapFlareDispersal < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 1.00;
	ui_tooltip = "Distance from screen center (and from themselves) the flares are generated. ";
> = 0.25;
uniform float fChapFlareSize < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.20; ui_max = 0.80;
	ui_tooltip = "Distance (from screen center) the halo and flares are generated.";
> = 0.45;
uniform float3 fChapFlareCA < __UNIFORM_SLIDER_FLOAT3
	ui_min = -0.5; ui_max = 0.5;
	ui_tooltip = "Offset of RGB components of flares as modifier for Chromatic abberation. Same 3 values means no CA.";
> = float3(0.00, 0.01, 0.02);
uniform float fChapFlareIntensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 5.0; ui_max = 200.0;
	ui_tooltip = "Intensity of flares and halo, remember that higher threshold lowers intensity, you might play with both values to get desired result.";
> = 100.0;

uniform bool bGodrayEnable <
> = false;
uniform float fGodrayDecay <
	ui_type = "drag";
	ui_min = 0.5000; ui_max = 0.9999;
	ui_tooltip = "How fast they decay. It's logarithmic, 1.0 means infinite long rays which will cover whole screen";
> = 0.9900;
uniform float fGodrayExposure < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.7; ui_max = 1.5;
	ui_tooltip = "Upscales the godray's brightness";
> = 1.0;
uniform float fGodrayWeight < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.80; ui_max = 1.70;
	ui_tooltip = "weighting";
> = 1.25;
uniform float fGodrayDensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.2; ui_max = 2.0;
	ui_tooltip = "Density of rays, higher means more and brighter rays";
> = 1.0;
uniform float fGodrayThreshold < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.6; ui_max = 1.0;
	ui_tooltip = "Minimum brightness an object must have to cast godrays";
> = 0.9;
uniform int iGodraySamples <
	ui_tooltip = "2^x format values; How many samples the godrays get";
> = 128;

uniform float fFlareLuminance < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.000; ui_max = 1.000;
	ui_tooltip = "bright pass luminance value ";
> = 0.095;
uniform float fFlareBlur < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 10000.0;
	ui_tooltip = "manages the size of the flare";
> = 200.0;
uniform float fFlareIntensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.20; ui_max = 5.00;
	ui_tooltip = "effect intensity";
> = 2.07;
uniform float3 fFlareTint < __UNIFORM_COLOR_FLOAT3
	ui_tooltip = "effect tint RGB";
> = float3(0.137, 0.216, 1.0);

// If 1, only pixels with depth = 1 get lens flares
// This prevents white objects from getting lens flares sources, which would normally happen in LDR
#ifndef LENZ_DEPTH_CHECK
	#define LENZ_DEPTH_CHECK 0
#endif
#ifndef CHAPMAN_DEPTH_CHECK
	#define CHAPMAN_DEPTH_CHECK 0
#endif
#ifndef GODRAY_DEPTH_CHECK
	#define GODRAY_DEPTH_CHECK 0
#endif
#ifndef FLARE_DEPTH_CHECK
	#define FLARE_DEPTH_CHECK 0
#endif

texture texDirt < source = "LensDB.png"; > { Width = 1920; Height = 1080; Format = RGBA8; };
texture texSprite < source = "LensSprite.png"; > { Width = 1920; Height = 1080; Format = RGBA8; };

sampler SamplerDirt { Texture = texDirt; };
sampler SamplerSprite { Texture = texSprite; };

texture texBloom1
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
};
texture texBloom2
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
};
texture texBloom3
{
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	Format = RGBA16F;
};
texture texBloom4
{
	Width = BUFFER_WIDTH / 4;
	Height = BUFFER_HEIGHT / 4;
	Format = RGBA16F;
};
texture texBloom5
{
	Width = BUFFER_WIDTH / 8;
	Height = BUFFER_HEIGHT / 8;
	Format = RGBA16F;
};
texture texLensFlare1
{
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	Format = RGBA16F;
};
texture texLensFlare2
{
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	Format = RGBA16F;
};

sampler SamplerBloom1 { Texture = texBloom1; };
sampler SamplerBloom2 { Texture = texBloom2; };
sampler SamplerBloom3 { Texture = texBloom3; };
sampler SamplerBloom4 { Texture = texBloom4; };
sampler SamplerBloom5 { Texture = texBloom5; };
sampler SamplerLensFlare1 { Texture = texLensFlare1; };
sampler SamplerLensFlare2 { Texture = texLensFlare2; };

#include "ReShade.fxh"
/*
// original
float4 GaussBlur22(float2 coord, sampler tex, float mult, float lodlevel, bool isBlurVert)
{
	float4 sum = 0;
	float2 axis = isBlurVert ? float2(0, 1) : float2(1, 0);

	const float weight[11] = {
		0.082607,
		0.080977,
		0.076276,
		0.069041,
		0.060049,
		0.050187,
		0.040306,
		0.031105,
		0.023066,
		0.016436,
		0.011254
	};

	for (int i = -10; i < 11; i++)
	{
		float currweight = weight[abs(i)];
		sum += tex2Dlod(tex, float4(coord.xy + axis.xy * (float)i * BUFFER_PIXEL_SIZE * mult, 0, lodlevel)) * currweight;
	}

	return sum;
}
*/

// modified - Craig - Jul 5th, 2020
// !!! re-wrote and re-organized most of it
// !!! see comments in code below
float4 GaussBlur22(float2 coord, sampler tex, float mult, float lodlevel, bool isBlurVert)
{
	const float weight[11] = {
		0.082607,
		0.080977,
		0.076276,
		0.069041,
		0.060049,
		0.050187,
		0.040306,
		0.031105,
		0.023066,
		0.016436,
		0.011254
	};

	float4 sum = 0.0;
	float4 texcoord = float4( coord.xy, 0, lodlevel );

	// !!! loop was doing a lot of wasted calc's mul'ing
	// !!! x or y (the one not changing) by 0 .. so just
	// !!! expanded if/else to only re-calc x or y that
	// !!! is changing. also pre-make texcoord var outside
	// !!! loop so we're not constantly re-creating it inside
	// !!! the loop.
	// !!! lastly, all the func calls to GaussBlur22 use
	// !!! lodlevel = 0, so just do standard tex2D
	// !!! calls and skip the tex2Dlod overhead.
	// !!! going to keep the LOD arg's in just
	// !!! in case someone later on wants to leverage
	// !!! that, but right now it's an unused,
	// !!! over-engineered option.

	if (isBlurVert)
	{
		// vertical axis changing
		float axis = BUFFER_PIXEL_SIZE.y * mult;

		for (int i = -10; i < 11; i++)
		{
			texcoord.y = coord.y + axis * (float)i;
	//		sum += tex2Dlod(tex, texcoord) * weight[abs(i)];
			sum += tex2D(tex, texcoord.xy) * weight[abs(i)];
		}
	}
	else
	{
		// horizontal axis changing
		float axis = BUFFER_PIXEL_SIZE.x * mult;

		for (int i = -10; i < 11; i++)
		{
			texcoord.x = coord.x + axis * (float)i;
	//		sum += tex2Dlod(tex, texcoord) * weight[abs(i)];
			sum += tex2D(tex, texcoord.xy) * weight[abs(i)];
		}

	}

	return sum;
}

/*
// original
float3 GetDnB(sampler tex, float2 coords)
{
	float3 color = max(0, dot(tex2Dlod(tex, float4(coords.xy, 0, 4)).rgb, 0.333) - fChapFlareTreshold) * fChapFlareIntensity;
#if CHAPMAN_DEPTH_CHECK
	if (tex2Dlod(ReShade::DepthBuffer, float4(coords.xy, 0, 3)).x < 0.99999)
		color = 0;
#endif
	return color;
}
*/

// modified - Craig - Jul 7th, 2020
// !!! original was returning a float3, but all calc's
// !!! we're processing a single float value returned
// !!! as float3. The calling methods were using .r,
// !!! .g or .b as if they were different, but they
// !!! were all the same return value. So, we cut down
// !!! on calc's by just processing a float and returning
// !!! it.

float GetDnB(sampler tex, float2 coords)
{

	float color;
	float4 texcoords = 	float4(coords.xy, 0, 0);

#if CHAPMAN_DEPTH_CHECK
	texcoords.w = 3;
	float depth = tex2Dlod(ReShade::DepthBuffer, texcoords).x;

	if (depth < 0.99999)
		color = 0;
	else
#endif
	{
		texcoords.w = 4;
		color = dot(tex2Dlod(tex, texcoords).rgb, 0.333);
		color = max(0, color) - fChapFlareTreshold;
		color *= fChapFlareIntensity;
	}
	return color;
}


float3 GetDistortedTex(sampler tex, float2 sample_center, float2 sample_vector, float3 distortion)
{
	float2 final_vector = sample_center + sample_vector * min(min(distortion.r, distortion.g), distortion.b);

	if (final_vector.x > 1.0 || final_vector.y > 1.0 || final_vector.x < -1.0 || final_vector.y < -1.0)
		return float3(0, 0, 0);
	else
		return float3(
			GetDnB(tex, sample_center + sample_vector * distortion.r).r,
			GetDnB(tex, sample_center + sample_vector * distortion.g).g,
			GetDnB(tex, sample_center + sample_vector * distortion.b).b);
}

float3 GetBrightPass(float2 coords)
{
	float3 c = tex2D(ReShade::BackBuffer, coords).rgb;
	float3 bC = max(c - fFlareLuminance.xxx, 0.0);
	float bright = dot(bC, 1.0);
	bright = smoothstep(0.0f, 0.5, bright);
	float3 result = lerp(0.0, c, bright);
#if FLARE_DEPTH_CHECK
	float checkdepth = tex2D(ReShade::DepthBuffer, coords).x;
	if (checkdepth < 0.99999)
		result = 0;
#endif
	return result;
}
float3 GetAnamorphicSample(int axis, float2 coords, float blur)
{
	coords = 2.0 * coords - 1.0;
	coords.x /= -blur;
	coords = 0.5 * coords + 0.5;
	return GetBrightPass(coords);
}
/*
// original
void BloomPass0(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom = 0.0;

	const float2 offset[4] = {
		float2(1.0, 1.0),
		float2(1.0, 1.0),
		float2(-1.0, 1.0),
		float2(-1.0, -1.0)
	};

	for (int i = 0; i < 4; i++)
	{
		float2 bloomuv = offset[i] * BUFFER_PIXEL_SIZE * 2;
		bloomuv += texcoord;
		float4 tempbloom = tex2Dlod(ReShade::BackBuffer, float4(bloomuv.xy, 0, 0));
		tempbloom.w = max(0, dot(tempbloom.xyz, 0.333) - fAnamFlareThreshold);
		tempbloom.xyz = max(0, tempbloom.xyz - fBloomThreshold); 
		bloom += tempbloom;
	}

	bloom *= 0.25;
}
*/

// modified - Craig - Jul 5th, 2020
void BloomPass0(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom = 0.0;

	const float2 offset[4] = {
		float2(1.0, 1.0),
		float2(1.0, 1.0),
		float2(-1.0, 1.0),
		float2(-1.0, -1.0)
	};

	// !!! pre-mul const to avoid extra mul's in loop
	// !!! Jul 6th, 2020 .. made bps2 a float2, b/c realized BUFFER_PIXEL_SIZE is float2
	float2 bps2 = BUFFER_PIXEL_SIZE * 2;

	for (int i = 0; i < 4; i++)
	{
		float2 bloomuv = offset[i] * bps2;
		bloomuv += texcoord;
		float4 tempbloom = tex2Dlod(ReShade::BackBuffer, float4(bloomuv.xy, 0, 0));
		tempbloom.w = max(0, dot(tempbloom.xyz, 0.333) - fAnamFlareThreshold);
		tempbloom.xyz = max(0, tempbloom.xyz - fBloomThreshold); 
		bloom += tempbloom;
	}

	bloom *= 0.25;
}

/*
// original
void BloomPass1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom = 0.0;

	const float2 offset[8] = {
		float2(1.0, 1.0),
		float2(0.0, -1.0),
		float2(-1.0, 1.0),
		float2(-1.0, -1.0),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};

	for (int i = 0; i < 8; i++)
	{
		float2 bloomuv = offset[i] * BUFFER_PIXEL_SIZE * 4;
		bloomuv += texcoord;
		bloom += tex2Dlod(SamplerBloom1, float4(bloomuv, 0, 0));
	}

	bloom *= 0.125;
}
*/

// modified - Craig - Jul 5th, 2020
void BloomPass1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom = 0.0;

	const float2 offset[8] = {
		float2(1.0, 1.0),
		float2(0.0, -1.0),
		float2(-1.0, 1.0),
		float2(-1.0, -1.0),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};

	// !!! pre-mul const to avoid extra mul's in loop
	// !!! Jul 6th,, 2020 .. made bps4 a float2 after realizing BUFFER_PIXEL_SIZE is float2
	float2 bps4 = BUFFER_PIXEL_SIZE * 4;

	for (int i = 0; i < 8; i++)
	{
		float2 bloomuv = offset[i] * bps4;
		bloomuv += texcoord;
		bloom += tex2Dlod(SamplerBloom1, float4(bloomuv, 0, 0));
	}

	bloom *= 0.125;
}
/*
// original
void BloomPass2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom = 0.0;

	const float2 offset[8] = {
		float2(0.707, 0.707),
		float2(0.707, -0.707),
		float2(-0.707, 0.707),
		float2(-0.707, -0.707),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};

	for (int i = 0; i < 8; i++)
	{
		float2 bloomuv = offset[i] * BUFFER_PIXEL_SIZE * 8;
		bloomuv += texcoord;
		bloom += tex2Dlod(SamplerBloom2, float4(bloomuv, 0, 0));
	}

	bloom *= 0.5; // brighten up the sample, it will lose brightness in H/V Gaussian blur
}
*/

// modified - Craig - Jul 5th, 2020
void BloomPass2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom = 0.0;

	const float2 offset[8] = {
		float2(0.707, 0.707),
		float2(0.707, -0.707),
		float2(-0.707, 0.707),
		float2(-0.707, -0.707),
		float2(0.0, 1.0),
		float2(0.0, -1.0),
		float2(1.0, 0.0),
		float2(-1.0, 0.0)
	};

	// !!! pre-mul const to avoid extra mul's in loop
	// !!! Jul 6th,, 2020 .. made bps8 a float2 after realizing BUFFER_PIXEL_SIZE is float2
	float2 bps8 = BUFFER_PIXEL_SIZE * 8;

	for (int i = 0; i < 8; i++)
	{
		float2 bloomuv = offset[i] * bps8;
		bloomuv += texcoord;
		bloom += tex2Dlod(SamplerBloom2, float4(bloomuv, 0, 0));
	}

	bloom *= 0.5; // brighten up the sample, it will lose brightness in H/V Gaussian blur
}

void BloomPass3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom = GaussBlur22(texcoord.xy, SamplerBloom3, 16, 0, 0);
	bloom.w *= fAnamFlareAmount;
	bloom.xyz *= fBloomAmount;
}
void BloomPass4(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 bloom : SV_Target)
{
	bloom.xyz = GaussBlur22(texcoord, SamplerBloom4, 16, 0, 1).xyz * 2.5;	
	bloom.w = GaussBlur22(texcoord, SamplerBloom4, 32 * fAnamFlareWideness, 0, 0).w * 2.5; // to have anamflare texture (bloom.w) avoid vertical blur
}

/*
// original
void LensFlarePass0(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 lens : SV_Target)
{
	lens = 0;

	// Lenz
	if (bLenzEnable)
	{
		const float3 lfoffset[19] = {
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
		const float3 lffactors[19] = {
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

		float2 lfcoord = 0;
		float3 lenstemp = 0;
		float2 distfact = texcoord.xy - 0.5;
		distfact.x *= BUFFER_ASPECT_RATIO;

		for (int i = 0; i < 19; i++)
		{
			lfcoord.xy = lfoffset[i].x * distfact;
			lfcoord.xy *= pow(2.0 * length(distfact), lfoffset[i].y * 3.5);
			lfcoord.xy *= lfoffset[i].z;
			lfcoord.xy = 0.5 - lfcoord.xy;
			float2 tempfact = (lfcoord.xy - 0.5) * 2;
			float templensmult = clamp(1.0 - dot(tempfact, tempfact), 0, 1);
			float3 lenstemp1 = dot(tex2Dlod(ReShade::BackBuffer, float4(lfcoord.xy, 0, 1)).rgb, 0.333);

#if LENZ_DEPTH_CHECK
			float templensdepth = tex2D(ReShade::DepthBuffer, lfcoord.xy).x;
			if (templensdepth < 0.99999)
				lenstemp1 = 0;
#endif

			lenstemp1 = max(0, lenstemp1.xyz - fLenzThreshold);
			lenstemp1 *= lffactors[i] * templensmult;

			lenstemp += lenstemp1;
		}

		lens.rgb += lenstemp * fLenzIntensity;
	}

	// Chapman Lens
	if (bChapFlareEnable)
	{
		float2 sample_vector = (float2(0.5, 0.5) - texcoord.xy) * fChapFlareDispersal;
		float2 halo_vector = normalize(sample_vector) * fChapFlareSize;

		float3 chaplens = GetDistortedTex(ReShade::BackBuffer, texcoord.xy + halo_vector, halo_vector, fChapFlareCA * 2.5f).rgb;

		for (int j = 0; j < iChapFlareCount; ++j)
		{
			float2 foffset = sample_vector * float(j);
			chaplens += GetDistortedTex(ReShade::BackBuffer, texcoord.xy + foffset, foffset, fChapFlareCA).rgb;
		}

		chaplens *= 1.0 / iChapFlareCount;
		lens.xyz += chaplens;
	}

	// Godrays
	if (bGodrayEnable)
	{
		const float2 ScreenLightPos = float2(0.5, 0.5);
		float2 texcoord2 = texcoord;
		float2 deltaTexCoord = (texcoord2 - ScreenLightPos);
		deltaTexCoord *= 1.0 / (float)iGodraySamples * fGodrayDensity;

		float illuminationDecay = 1.0;

		for (int g = 0; g < iGodraySamples; g++)
		{
			texcoord2 -= deltaTexCoord;;
			float4 sample2 = tex2Dlod(ReShade::BackBuffer, float4(texcoord2, 0, 0));
			float sampledepth = tex2Dlod(ReShade::DepthBuffer, float4(texcoord2, 0, 0)).x;
			sample2.w = saturate(dot(sample2.xyz, 0.3333) - fGodrayThreshold);
			sample2.r *= 1.00;
			sample2.g *= 0.95;
			sample2.b *= 0.85;
			sample2 *= illuminationDecay * fGodrayWeight;
#if GODRAY_DEPTH_CHECK == 1
			if (sampledepth > 0.99999)
				lens.rgb += sample2.xyz * sample2.w;
#else
			lens.rgb += sample2.xyz * sample2.w;
#endif
			illuminationDecay *= fGodrayDecay;
		}
	}

	// Anamorphic flare
	if (bAnamFlareEnable)
	{
		float3 anamFlare = 0;
		const float gaussweight[5] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };

		for (int z = -4; z < 5; z++)
		{
			anamFlare += GetAnamorphicSample(0, texcoord.xy + float2(0, z * BUFFER_RCP_HEIGHT * 2), fFlareBlur) * fFlareTint * gaussweight[abs(z)];
		}

		lens.xyz += anamFlare * fFlareIntensity;
	}
}
*/

// modified - Craig - Jul 5th, 2020
void LensFlarePass0(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 lens : SV_Target)
{
	lens = 0;

	// Lenz
	if (bLenzEnable)
	{
		const float3 lfoffset[19] = {
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
		const float3 lffactors[19] = {
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

		float2 lfcoord = 0;
		float3 lenstemp = 0;
		float2 distfact = texcoord.xy - 0.5;
		distfact.x *= BUFFER_ASPECT_RATIO;

		// !!! pre-calc this to avoid doing length() over and over in loop
		float distfactlen = 2.0 * length(distfact);

		for (int i = 0; i < 19; i++)
		{
			lfcoord.xy = lfoffset[i].x * distfact;
			lfcoord.xy *= pow(distfactlen, lfoffset[i].y * 3.5);
			lfcoord.xy *= lfoffset[i].z;
			lfcoord.xy = 0.5 - lfcoord.xy;
			float2 tempfact = (lfcoord.xy - 0.5) * 2;
			float templensmult = clamp(1.0 - dot(tempfact, tempfact), 0, 1);
			float3 lenstemp1 = dot(tex2Dlod(ReShade::BackBuffer, float4(lfcoord.xy, 0, 1)).rgb, 0.333);

#if LENZ_DEPTH_CHECK
			float templensdepth = tex2D(ReShade::DepthBuffer, lfcoord.xy).x;
			if (templensdepth < 0.99999)
				lenstemp1 = 0;
#endif

			lenstemp1 = max(0, lenstemp1.xyz - fLenzThreshold);
			lenstemp1 *= lffactors[i] * templensmult;

			lenstemp += lenstemp1;
		}

		lens.rgb += lenstemp * fLenzIntensity;
	}

	// Chapman Lens
	if (bChapFlareEnable)
	{
		float2 sample_vector = (float2(0.5, 0.5) - texcoord.xy) * fChapFlareDispersal;
		float2 halo_vector = normalize(sample_vector) * fChapFlareSize;

		float3 chaplens = GetDistortedTex(ReShade::BackBuffer, texcoord.xy + halo_vector, halo_vector, fChapFlareCA * 2.5f).rgb;

		for (int j = 0; j < iChapFlareCount; ++j)
		{
			float2 foffset = sample_vector * float(j);
			chaplens += GetDistortedTex(ReShade::BackBuffer, texcoord.xy + foffset, foffset, fChapFlareCA).rgb;
		}

		// !!! chaplens mul by 1 = chaplens, so skip mul'ing by 1 and just divide by iChapFlareCount
		chaplens /= iChapFlareCount;
//		chaplens *= 1.0 / iChapFlareCount;
		lens.xyz += chaplens;
	}

	// Godrays
	if (bGodrayEnable)
	{
		const float2 ScreenLightPos = float2(0.5, 0.5);
		float2 texcoord2 = texcoord;
		float2 deltaTexCoord = (texcoord2 - ScreenLightPos);

		// !!! mul'ing by 1 can get skipped.. just divide
		deltaTexCoord /= (float)iGodraySamples * fGodrayDensity;
//		deltaTexCoord *= 1.0 / (float)iGodraySamples * fGodrayDensity;

		// !!! this can get moved out of loop below,
		// !!! b/c not impacted by g++ iterator
		texcoord2 -= deltaTexCoord;
		float4 texcoord2lod = float4(texcoord2, 0, 0);
		float4 sample2 = tex2Dlod(ReShade::BackBuffer, texcoord2lod);
		float sampledepth = tex2Dlod(ReShade::DepthBuffer, texcoord2lod).x;
		sample2.w = saturate(dot(sample2.xyz, 0.3333) - fGodrayThreshold);

		// !!! mul'ing sample2.r by 1, skip
//		sample2.r *= 1.00;
		sample2.g *= 0.95;
		sample2.b *= 0.85;

		float illuminationDecay = 1.0;


		for (int g = 0; g < iGodraySamples; g++)
		{
//			texcoord2 -= deltaTexCoord;
//			float4 sample2 = tex2Dlod(ReShade::BackBuffer, texcoord2lod);
//			float sampledepth = tex2Dlod(ReShade::DepthBuffer, texcoord2lod).x;
//			sample2.w = saturate(dot(sample2.xyz, 0.3333) - fGodrayThreshold);

			// !!! mul'ing sample2.r by 1, skip
//			sample2.r *= 1.00;
//			sample2.g *= 0.95;
//			sample2.b *= 0.85;
//			sample2 *= illuminationDecay * fGodrayWeight;

			// !!! keep sample2 as-is for reference, just modify copy of it
			float4 sample2copy = sample2 * illuminationDecay * fGodrayWeight;
			
#if GODRAY_DEPTH_CHECK == 1
			if (sampledepth > 0.99999)
				lens.rgb += sample2copy.xyz * sample2copy.w;
#else
			lens.rgb += sample2copy.xyz * sample2copy.w;
#endif
			illuminationDecay *= fGodrayDecay;
		}
	}

	// Anamorphic flare
	if (bAnamFlareEnable)
	{
		float3 anamFlare = 0;
		const float gaussweight[5] = { 0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 };

		// !!! can pre-calc this outside loop
		float brh2 = BUFFER_RCP_HEIGHT * 2;

		for (int z = -4; z < 5; z++)
		{
			anamFlare += GetAnamorphicSample(0, texcoord.xy + float2(0, z * brh2), fFlareBlur) * fFlareTint * gaussweight[abs(z)];
		}

		lens.xyz += anamFlare * fFlareIntensity;
	}
}

void LensFlarePass1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 lens : SV_Target)
{
	lens = GaussBlur22(texcoord, SamplerLensFlare1, 2, 0, 1);
}
void LensFlarePass2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 lens : SV_Target)
{
	lens = GaussBlur22(texcoord, SamplerLensFlare2, 2, 0, 0);
}

/*
// original
void LightingCombine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	color = tex2D(ReShade::BackBuffer, texcoord);

	// Bloom
	float3 colorbloom = 0;
	colorbloom += tex2D(SamplerBloom3, texcoord).rgb * 1.0;
	colorbloom += tex2D(SamplerBloom5, texcoord).rgb * 9.0;
	colorbloom *= 0.1;
	colorbloom = saturate(colorbloom);
	float colorbloomgray = dot(colorbloom, 0.333);
	colorbloom = lerp(colorbloomgray, colorbloom, fBloomSaturation);
	colorbloom *= fBloomTint;

	if (iBloomMixmode == 0)
		color.rgb += colorbloom;
	else if (iBloomMixmode == 1)
		color.rgb = 1 - (1 - color.rgb) * (1 - colorbloom);
	else if (iBloomMixmode == 2)
		color.rgb = max(0.0f, max(color.rgb, lerp(color.rgb, (1 - (1 - saturate(colorbloom)) * (1 - saturate(colorbloom))), 1.0)));
	else if (iBloomMixmode == 3)
		color.rgb = max(color.rgb, colorbloom);

	// Anamorphic flare
	if (bAnamFlareEnable)
	{
		float3 anamflare = tex2D(SamplerBloom5, texcoord.xy).w * 2 * fAnamFlareColor;
		anamflare = max(anamflare, 0.0);
		color.rgb += pow(anamflare, 1.0 / fAnamFlareCurve);
	}

	// Lens dirt
	if (bLensdirtEnable)
	{
		float lensdirtmult = dot(tex2D(SamplerBloom5, texcoord).rgb, 0.333);
		float3 dirttex = tex2D(SamplerDirt, texcoord).rgb;
		float3 lensdirt = dirttex * lensdirtmult * fLensdirtIntensity;

		lensdirt = lerp(dot(lensdirt.xyz, 0.333), lensdirt.xyz, fLensdirtSaturation);

		if (iLensdirtMixmode == 0)
			color.rgb += lensdirt;
		else if (iLensdirtMixmode == 1)
			color.rgb = 1 - (1 - color.rgb) * (1 - lensdirt);
		else if (iLensdirtMixmode == 2)
			color.rgb = max(0.0f, max(color.rgb, lerp(color.rgb, (1 - (1 - saturate(lensdirt)) * (1 - saturate(lensdirt))), 1.0)));
		else if (iLensdirtMixmode == 3)
			color.rgb = max(color.rgb, lensdirt);
	}

	// Lens flares
	if (bAnamFlareEnable || bLenzEnable || bGodrayEnable || bChapFlareEnable)
	{
		float3 lensflareSample = tex2D(SamplerLensFlare1, texcoord.xy).rgb, lensflareMask;
		lensflareMask  = tex2D(SamplerSprite, texcoord + float2( 0.5,  0.5) * BUFFER_PIXEL_SIZE).rgb;
		lensflareMask += tex2D(SamplerSprite, texcoord + float2(-0.5,  0.5) * BUFFER_PIXEL_SIZE).rgb;
		lensflareMask += tex2D(SamplerSprite, texcoord + float2( 0.5, -0.5) * BUFFER_PIXEL_SIZE).rgb;
		lensflareMask += tex2D(SamplerSprite, texcoord + float2(-0.5, -0.5) * BUFFER_PIXEL_SIZE).rgb;

		color.rgb += lensflareMask * 0.25 * lensflareSample;
	}
}
*/

// modified - Craig - Jul 5th, 2020
void LightingCombine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	color = tex2D(ReShade::BackBuffer, texcoord);

	// Bloom
	float3 colorbloom = 0;
	
	// !!! mul'ing by 1 can get skipped
	colorbloom += tex2D(SamplerBloom3, texcoord).rgb;// * 1.0;
	colorbloom += tex2D(SamplerBloom5, texcoord).rgb * 9.0;
	colorbloom *= 0.1;
	colorbloom = saturate(colorbloom);
	float colorbloomgray = dot(colorbloom, 0.333);
	colorbloom = lerp(colorbloomgray, colorbloom, fBloomSaturation);
	colorbloom *= fBloomTint;

	if (iBloomMixmode == 0)
		color.rgb += colorbloom;
	else if (iBloomMixmode == 1)
		color.rgb = 1 - (1 - color.rgb) * (1 - colorbloom);
	else if (iBloomMixmode == 2)
	{
		// !!! get rid of redundant calc's
		colorbloom = 1 - saturate(colorbloom);
		colorbloom = 1 - ( colorbloom * colorbloom );
		// !!! lerp (x, y, 1) returns y w/o any x interpolated in it, so we can skip the lerp
		color.rgb = max(0.0f, max(color.rgb, colorbloom.rgb));
//		color.rgb = max(0.0f, max(color.rgb, lerp(color.rgb, colorbloom.rgb, 1.0)));
	}
	else if (iBloomMixmode == 3)
		color.rgb = max(color.rgb, colorbloom.rgb);

	// Anamorphic flare
	if (bAnamFlareEnable)
	{
		// !!! force floats to mul first before mul'ing with float3
		float3 anamflare = (tex2D(SamplerBloom5, texcoord.xy).w * 2) * fAnamFlareColor;
		anamflare = max(anamflare, 0.0);
		color.rgb += pow(anamflare, 1.0 / fAnamFlareCurve);
	}

	// Lens dirt
	if (bLensdirtEnable)
	{
		float lensdirtmult = dot(tex2D(SamplerBloom5, texcoord).rgb, 0.333);
		float3 dirttex = tex2D(SamplerDirt, texcoord).rgb;

		// !!! force floats to mul first before mul'ing with float3
		float3 lensdirt = dirttex * (lensdirtmult * fLensdirtIntensity);

		lensdirt = lerp(dot(lensdirt.xyz, 0.333), lensdirt.xyz, fLensdirtSaturation);

		if (iLensdirtMixmode == 0)
			color.rgb += lensdirt;
		else if (iLensdirtMixmode == 1)
			color.rgb = 1 - (1 - color.rgb) * (1 - lensdirt);
		else if (iLensdirtMixmode == 2)
		{
			// !!! pre-calc redundant calculations
			lensdirt = 1 - saturate(lensdirt);
			lensdirt = 1 - ( lensdirt * lensdirt );
			// !!! lerp(x, y, 1) returns all of y and no x interpolated in, so skip the lerp and just use y
			color.rgb = max(0.0f, max(color.rgb, lensdirt));
//			color.rgb = max(0.0f, max(color.rgb, lerp(color.rgb, (1 - (1 - saturate(lensdirt)) * (1 - saturate(lensdirt))), 1.0)));
		}
		else if (iLensdirtMixmode == 3)
			color.rgb = max(color.rgb, lensdirt);
	}

	// Lens flares
	if (bAnamFlareEnable || bLenzEnable || bGodrayEnable || bChapFlareEnable)
	{
		float3 lensflareSample = tex2D(SamplerLensFlare1, texcoord.xy).rgb, lensflareMask;

		/*
		// original
		lensflareMask  = tex2D(SamplerSprite, texcoord + float2( 0.5,  0.5) * BUFFER_PIXEL_SIZE).rgb;
		lensflareMask += tex2D(SamplerSprite, texcoord + float2(-0.5,  0.5) * BUFFER_PIXEL_SIZE).rgb;
		lensflareMask += tex2D(SamplerSprite, texcoord + float2( 0.5, -0.5) * BUFFER_PIXEL_SIZE).rgb;
		lensflareMask += tex2D(SamplerSprite, texcoord + float2(-0.5, -0.5) * BUFFER_PIXEL_SIZE).rgb;
		*/

		// !!! pre-calc the texcoord stuff once
		// !!! and get rid of redundant math.
		// !!! Jul 7th 2020 .. modified changes
		// !!! after realizing BUFFER_PIXEL_SIZE is float2
		// !!! (P)ositive, (N)egative
		float2 bpsPP = BUFFER_PIXEL_SIZE * 0.5;
		float2 bpsNN = -bpsPP; // can just invert this
		
		// !!! now we can add texcoord to the pos & neg's
		bpsPP += texcoord;
		bpsNN += texcoord;

		// !!! then just generate the NP & PN with the
		// !!! pre-calc'ed values from PP & NN
		float2 bpsPN = float2( bpsPP.x, bpsNN.y );
		float2 bpsNP = float2( bpsNN.x, bpsPP.y );
		
		lensflareMask  = tex2D(SamplerSprite, bpsPP).rgb;
		lensflareMask += tex2D(SamplerSprite, bpsNP).rgb;
		lensflareMask += tex2D(SamplerSprite, bpsPN).rgb;
		lensflareMask += tex2D(SamplerSprite, bpsNN).rgb;

		color.rgb += lensflareMask * 0.25 * lensflareSample;
	}
}

technique BloomAndLensFlares
{
	pass BloomPass0
	{
		VertexShader = PostProcessVS;
		PixelShader = BloomPass0;
		RenderTarget = texBloom1;
	}
	pass BloomPass1
	{
		VertexShader = PostProcessVS;
		PixelShader = BloomPass1;
		RenderTarget = texBloom2;
	}
	pass BloomPass2
	{
		VertexShader = PostProcessVS;
		PixelShader = BloomPass2;
		RenderTarget = texBloom3;
	}
	pass BloomPass3
	{
		VertexShader = PostProcessVS;
		PixelShader = BloomPass3;
		RenderTarget = texBloom4;
	}
	pass BloomPass4
	{
		VertexShader = PostProcessVS;
		PixelShader = BloomPass4;
		RenderTarget = texBloom5;
	}

	pass LensFlarePass0
	{
		VertexShader = PostProcessVS;
		PixelShader = LensFlarePass0;
		RenderTarget = texLensFlare1;
	}
	pass LensFlarePass1
	{
		VertexShader = PostProcessVS;
		PixelShader = LensFlarePass1;
		RenderTarget = texLensFlare2;
	}
	pass LensFlarePass2
	{
		VertexShader = PostProcessVS;
		PixelShader = LensFlarePass2;
		RenderTarget = texLensFlare1;
	}

	pass LightingCombine
	{
		VertexShader = PostProcessVS;
		PixelShader = LightingCombine;
	}
}
