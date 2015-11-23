NAMESPACE_ENTER(MFX)

#include MFX_SETTINGS_DEF

#if USE_DEPTHOFFIELD

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
// For more information about license agreement contact me:
// https://www.facebook.com/MartyMcModding
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Advanced Depth of Field 4.2 by Marty McFly 
// Version for release
// Copyright © 2008-2015 Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Credits :: Matso (Matso DOF), PetkaGtA, gp65cj042
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TEXTURES / INTERNAL PARAMETERS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

texture2D texMask    	< string source = "ReShade/McFX/Textures/mcmask.png";  > {Width = iADOF_ShapeTextureSize;Height = iADOF_ShapeTextureSize;Format = R8; };
texture2D texHDR1 	{ Width = BUFFER_WIDTH*DOF_RENDERRESMULT; Height = BUFFER_HEIGHT*DOF_RENDERRESMULT; Format = RGBA8;};
texture2D texHDR2 	{ Width = BUFFER_WIDTH*DOF_RENDERRESMULT; Height = BUFFER_HEIGHT*DOF_RENDERRESMULT; Format = RGBA8;}; 

#if(bADOF_ShapeTextureEnable != 0)
sampler2D SamplerMask  
{
	Texture = texMask;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};
#endif

sampler2D SamplerHDR1
{
	Texture = texHDR1;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

sampler2D SamplerHDR2
{
	Texture = texHDR2;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float GetCoC(float2 coords)
{
	float  scenedepth = tex2D(RFX_depthTexColor,coords.xy).x;
	float  scenefocus = DOF_MANUALFOCUSDEPTH;
	float  scenecoc = 0.0;

#if(DOF_AUTOFOCUS != 0)
	scenefocus = 0.0;

	[loop]
	for(int r=0;r<DOF_FOCUSSAMPLES;r++)
	{ 
 		sincos((6.2831853 / DOF_FOCUSSAMPLES)*r,coords.y,coords.x);
 		coords.y *= RFX_ScreenSizeFull.z; 
 		scenefocus += tex2D(RFX_depthTexColor,coords*DOF_FOCUSRADIUS + DOF_FOCUSPOINT.xy).x; 
  	}
	scenefocus /= DOF_FOCUSSAMPLES; 
#endif
	scenefocus = smoothstep(0.0,DOF_INFINITEFOCUS,scenefocus);
	scenedepth = smoothstep(0.0,DOF_INFINITEFOCUS,scenedepth);

	float farBlurDepth = scenefocus*pow(4.0,DOF_FARBLURCURVE);

	if(scenedepth < scenefocus)
	{
		scenecoc=(scenedepth - scenefocus)/scenefocus;
	}
	else
	{
		scenecoc=(scenedepth - scenefocus)/(farBlurDepth - scenefocus);
		scenecoc=saturate(scenecoc);
	}

	return saturate(scenecoc * 0.5 + 0.5);
}

/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////PIXEL SHADERS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void PS_Focus(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	float4 scenecolor = tex2D(RFX_backbufferColor, texcoord.xy);
	scenecolor.w = GetCoC(texcoord.xy);
	hdr1R = scenecolor;
}

void PS_RingDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 scenecolor = tex2D(SamplerHDR1, texcoord.xy);

	float centerDepth = scenecolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	float2 blurRadius = discRadius * RFX_PixelSize.xy / iRingDOFRings;
	scenecolor.x = tex2Dlod(SamplerHDR1,float4(texcoord.xy + float2(0.0,1.0)    *fRingDOFFringe*discRadius*RFX_PixelSize.xy,0,0)).x;
	scenecolor.y = tex2Dlod(SamplerHDR1,float4(texcoord.xy + float2(-0.866,-0.5)*fRingDOFFringe*discRadius*RFX_PixelSize.xy,0,0)).y;
	scenecolor.z = tex2Dlod(SamplerHDR1,float4(texcoord.xy + float2(0.866,-0.5) *fRingDOFFringe*discRadius*RFX_PixelSize.xy,0,0)).z;

	scenecolor.w = centerDepth;
	hdr2R = scenecolor;
}

float4 PS_RingDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 blurcolor = tex2D(SamplerHDR2, texcoord.xy);
	float4 noblurcolor = tex2D(RFX_backbufferColor, texcoord.xy);

	float centerDepth = GetCoC(texcoord.xy);

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	if(discRadius < 1.2) return float4(noblurcolor.xyz,centerDepth);

	blurcolor.w = 1.0;

	float s = 1.0;
	int ringsamples;

	[loop]
	for (int g = 1; g <= iRingDOFRings; g += 1)
	{
		ringsamples = g * iRingDOFSamples;
		[loop]
		for (int j = 0 ; j < ringsamples ; j += 1)
		{
			float step = 6.283 / ringsamples;
			float2 sampleoffset = 0.0;
			sincos(j*step,sampleoffset.y,sampleoffset.x);
			float4 tap = tex2Dlod(SamplerHDR2, float4(texcoord.xy + sampleoffset * RFX_PixelSize.xy * discRadius * g / iRingDOFRings,0,0)); 

			float tapluma = dot(tap.xyz,0.333);
			float tapthresh = max((tapluma-fRingDOFThreshold)*fRingDOFGain, 0.0);
			tap.xyz *= 1.0 + tapthresh * blurAmount;

			tap.w = (tap.w >= centerDepth*0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0),4.0); 
			tap.w *= lerp(1.0,g/iRingDOFRings,fRingDOFBias); 
			blurcolor.xyz += tap.xyz * tap.w;  
			blurcolor.w += tap.w;
		}
	}
	blurcolor.xyz /= blurcolor.w; 
	blurcolor.xyz = lerp(noblurcolor.xyz,blurcolor.xyz,smoothstep(1.2,2.0,discRadius)); //smooth transition between full res color and lower res blur
	blurcolor.w = centerDepth;   
	return blurcolor;
}

void PS_MagicDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)	
{
	float4 blurcolor = tex2D(SamplerHDR1, texcoord.xy);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	if(discRadius < 1.2) hdr2R = float4(blurcolor.xyz,centerDepth);
	else {
		blurcolor = 0.0;

		[loop]
		for (int i = -iMagicDOFBlurQuality; i <= iMagicDOFBlurQuality; ++i) 
		{
			float2 tapoffset = float2(1.0,0)*i;
			float4 tap = tex2Dlod(SamplerHDR1, float4(texcoord.xy+tapoffset*discRadius*RFX_PixelSize.x/iMagicDOFBlurQuality,0,0));
			tap.w = (tap.w >= centerDepth*0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0),4.0); 
			blurcolor.xyz += tap.xyz*tap.w;
			blurcolor.w += tap.w;
		}

		blurcolor.xyz /= blurcolor.w;
		blurcolor.w = centerDepth;
		hdr2R = blurcolor;
	}
}

float4 PS_MagicDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target	
{
	float4 blurcolor = 0.0;
	float4 noblurcolor = tex2D(RFX_backbufferColor, texcoord.xy);

	float centerDepth = GetCoC(texcoord.xy); //use fullres CoC data
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	if(discRadius < 1.2) return float4(noblurcolor.xyz,centerDepth);

	[loop]
	for (int i = -iMagicDOFBlurQuality; i <= iMagicDOFBlurQuality; ++i) 
	{
		float2 tapoffset1 = float2(0.5,0.866)*i;
		float2 tapoffset2 = float2(-tapoffset1.x,tapoffset1.y);

		float4 tap1 = tex2Dlod(SamplerHDR2, float4(texcoord.xy+tapoffset1*discRadius*RFX_PixelSize.xy/iMagicDOFBlurQuality,0,0));
		float4 tap2 = tex2Dlod(SamplerHDR2, float4(texcoord.xy+tapoffset2*discRadius*RFX_PixelSize.xy/iMagicDOFBlurQuality,0,0));

		blurcolor.xyz += pow(min(tap1.xyz,tap2.xyz),fMagicDOFColorCurve); 
		blurcolor.w += 1.0; 
		}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = pow(saturate(blurcolor.xyz), 1.0/fMagicDOFColorCurve);
	blurcolor.xyz = lerp(noblurcolor.xyz,blurcolor.xyz,smoothstep(1.2,2.0,discRadius));
	return blurcolor;
}


//GP65CJ042 DOF
void PS_GPDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	float4 blurcolor = tex2D(SamplerHDR1, texcoord.xy);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = max(0.0,blurAmount-0.1) * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	float3 distortion=float3(-1.0, 0.0, 1.0);
	distortion*=fGPDOFChromaAmount; 

	float4 chroma1=tex2D(SamplerHDR1, texcoord.xy + discRadius*RFX_PixelSize.xy*distortion.x);
	chroma1.w=smoothstep(0.0, centerDepth, chroma1.w);
	blurcolor.x=lerp(blurcolor.x, chroma1.x, chroma1.w);
	
	float4 chroma2=tex2D(SamplerHDR1, texcoord.xy + discRadius*RFX_PixelSize.xy*distortion.z);
	chroma2.w=smoothstep(0.0, centerDepth, chroma2.w);
	blurcolor.z=lerp(blurcolor.z, chroma2.z, chroma2.w);

	blurcolor.w = centerDepth;
	hdr2R = blurcolor;
}

float4 PS_GPDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 blurcolor = tex2D(SamplerHDR2, texcoord.xy);
	float4 noblurcolor = tex2D(RFX_backbufferColor, texcoord.xy);

	float centerDepth = GetCoC(texcoord.xy);

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	if(discRadius < 1.2) return float4(noblurcolor.xyz,centerDepth);

	blurcolor.w=dot(blurcolor.xyz, 0.3333);
	blurcolor.w=max((blurcolor.w - fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
	blurcolor.xyz*=(1.0 + blurcolor.w*blurAmount);
	blurcolor.xyz*=lerp(1.0,0.0,saturate(fGPDOFBias));
	blurcolor.w=1.0;
	
	int sampleCycle=0;
	int sampleCycleCounter=0;
	int sampleCounterInCycle=0;
	
	#if ( bGPDOFPolygonalBokeh == 1)
		float basedAngle=360.0 / iGPDOFPolygonCount;
		float2 currentVertex;
		float2 nextVertex;
	
		int	dofTaps=iGPDOFQuality * (iGPDOFQuality + 1) * iGPDOFPolygonCount / 2.0;
	#else
		int	dofTaps=iGPDOFQuality * (iGPDOFQuality + 1) * 4;
	#endif

	
	for(int i=0; i < dofTaps; i++)
	{

		//dumb step incoming
		bool dothatstep=0;
		if(sampleCounterInCycle==0) dothatstep=1;
		if(sampleCycle!=0) 
		{
		if(sampleCounterInCycle % sampleCycle == 0) dothatstep=1;
		}
		//until here
		//ask yourself why so complicated? if(sampleCounterInCycle % sampleCycle == 0 ) gives warnings when sampleCycle=0
		//but it can only be 0 when sampleCounterInCycle is also 0 so it essentially is no division through 0 even if
		//the compiler believes it, it's 0/0 actually but without disabling shader optimizations this is the only way to workaround that.
		
		if(dothatstep==1)
		{
			sampleCounterInCycle=0;
			sampleCycleCounter++;
		
			#if ( bGPDOFPolygonalBokeh == 1)
				sampleCycle+=iGPDOFPolygonCount;
				currentVertex.xy=float2(1.0 , 0.0);
				sincos(basedAngle* 0.017453292, nextVertex.y, nextVertex.x);	
			#else	
				sampleCycle+=8;
			#endif
		}

		sampleCounterInCycle++;
		
		#if (bGPDOFPolygonalBokeh==1)
			float sampleAngle=basedAngle / float(sampleCycleCounter) * sampleCounterInCycle;
			float remainAngle=frac(sampleAngle / basedAngle) * basedAngle;
		
			if(remainAngle < 0.000001)
			{
				currentVertex=nextVertex;
				sincos((sampleAngle +  basedAngle) * 0.017453292, nextVertex.y, nextVertex.x);
			}

			float2 sampleOffset=lerp(currentVertex.xy, nextVertex.xy, remainAngle / basedAngle);
		#else
			float sampleAngle=0.78539816 / float(sampleCycleCounter) * sampleCounterInCycle;
			float2 sampleOffset;
			sincos(sampleAngle, sampleOffset.y, sampleOffset.x);
		#endif
		
		sampleOffset*=sampleCycleCounter;

		float4 tap=tex2Dlod(SamplerHDR2, float4(texcoord.xy+sampleOffset.xy*discRadius*RFX_PixelSize.xy/iGPDOFQuality,0,0));

		float brightMultipiler=max((dot(tap.xyz, 0.333)- fGPDOFBrightnessThreshold) * fGPDOFBrightnessMultiplier, 0.0);
		tap.xyz*=1.0 + brightMultipiler*abs(tap.w*2.0 - 1.0);

		tap.w = (tap.w >= centerDepth*0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0),4.0);
		float BiasCurve = 1.0 + fGPDOFBias * pow((float)sampleCycleCounter/iGPDOFQuality, fGPDOFBiasCurve);
		
		blurcolor.xyz += tap.xyz*tap.w*BiasCurve;
		blurcolor.w += tap.w*BiasCurve;

	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.xyz = lerp(noblurcolor.xyz,blurcolor.xyz,smoothstep(1.2,2.0,discRadius));
	return blurcolor;
}


//MATSO DOF
float4 GetMatsoDOFCA(sampler col, float2 tex, float CoC)
{
	float3 chroma = pow(float3(0.5, 1.0, 1.5), fMatsoDOFChromaPow * CoC);

	float2 tr = ((2.0 * tex - 1.0) * chroma.r) * 0.5 + 0.5;
	float2 tg = ((2.0 * tex - 1.0) * chroma.g) * 0.5 + 0.5;
	float2 tb = ((2.0 * tex - 1.0) * chroma.b) * 0.5 + 0.5;
	
	float3 color = float3(tex2Dlod(col, float4(tr,0,0)).r, tex2Dlod(col, float4(tg,0,0)).g, tex2Dlod(col, float4(tb,0,0)).b) * (1.0 - CoC);
	
	return float4(color, 1.0);
}

float4 GetMatsoDOFBlur(int axis, float2 coord, sampler SamplerHDRX)
{
	float4 blurcolor = tex2D(SamplerHDRX, coord.xy);

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS; //optimization to clean focus areas a bit

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	blurcolor = 0.0;

	float2 tdirs[4] = { float2(-0.306, 0.739), float2(0.306, 0.739), float2(-0.739, 0.306), float2(-0.739, -0.306) };

	for (int i = -iMatsoDOFBokehQuality; i < iMatsoDOFBokehQuality; i++)
	{
		float2 taxis =  tdirs[axis];

		taxis.x = cos(fMatsoDOFBokehAngle*0.0175)*taxis.x-sin(fMatsoDOFBokehAngle*0.0175)*taxis.y;
		taxis.y = sin(fMatsoDOFBokehAngle*0.0175)*taxis.x+cos(fMatsoDOFBokehAngle*0.0175)*taxis.y;
		
		float2 tcoord = coord.xy + (float)i * taxis * discRadius * RFX_PixelSize.xy * 0.5 / iMatsoDOFBokehQuality;

#if(bMatsoDOFChromaEnable == 1)
		float4 ct = GetMatsoDOFCA(SamplerHDRX, tcoord.xy, discRadius * RFX_PixelSize.x * 0.5 / iMatsoDOFBokehQuality);
#else
		float4 ct = tex2Dlod(SamplerHDRX, float4(tcoord.xy,0,0));
#endif

#if (bMatsoDOFBokehEnable == 0)
		float w = 1.0 + abs(offset[i]);	// weight blur for better effect
#else	
	// my own pseudo-bokeh weighting
		float b = dot(ct.rgb,0.333) + length(ct.rgb) + 0.1;
		float w = pow(b, fMatsoDOFBokehCurve) + abs((float)i);
#endif
		blurcolor.xyz += ct.xyz * w;
		blurcolor.w += w;
	}

	blurcolor.xyz /= blurcolor.w;
	blurcolor.w = centerDepth;
	return blurcolor;
}

void PS_MatsoDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(2, texcoord.xy, SamplerHDR1);	
}

void PS_MatsoDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr1R : SV_Target0)
{
	hdr1R = GetMatsoDOFBlur(3, texcoord.xy, SamplerHDR2);	
}

void PS_MatsoDOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	hdr2R = GetMatsoDOFBlur(0, texcoord.xy, SamplerHDR1);	
}

//you need to handle this one separately somehow (I saw how you did it previously), sorry :p XXX
float4 PS_MatsoDOF4(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 noblurcolor = tex2D(RFX_backbufferColor, texcoord.xy);
	float4 blurcolor = GetMatsoDOFBlur(1, texcoord.xy, SamplerHDR2);
	float centerDepth = GetCoC(texcoord.xy); //fullres coc data

	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	//not 1.2 - 2.0 because matso's has a weird bokeh weighting that is almost like a tonemapping and border between blur and no blur appears to harsh
	blurcolor.xyz = lerp(noblurcolor.xyz,blurcolor.xyz,smoothstep(0.2,2.0,discRadius)); 
	return blurcolor;
}

float2 GetDistortedOffsets(float2 intexcoord, float2 sampleoffset)
{
	float2 tocenter = intexcoord.xy-float2(0.5,0.5);
	float3 perp = normalize(float3(tocenter.y, -tocenter.x, 0.0));

	float rotangle = length(tocenter.xy)*2.221*fADOF_ShapeDistortAmount;  
	float3 oldoffset = float3(sampleoffset.xy,0);

	float3 rotatedoffset =  oldoffset * cos(rotangle) + cross(perp, oldoffset) * sin(rotangle) + perp * dot(perp,oldoffset)*(1.0 - cos(rotangle));

	return rotatedoffset.xy;

}

float4 tex2Dchroma(sampler2D tex, float2 sourcecoord, float2 offsetcoord)
{
	float4 res = 0.0;

	float4 sample1 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy * (1.0 - fADOF_ShapeChromaAmount),0,0));
	float4 sample2 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy				       ,0,0));
	float4 sample3 = tex2Dlod(tex, float4(sourcecoord.xy + offsetcoord.xy * (1.0 + fADOF_ShapeChromaAmount),0,0));

	#if(iADOF_ShapeChromaMode == 1)		
		res.xyz = float3(sample1.x, sample2.y, sample3.z);
	#elif(iADOF_ShapeChromaMode == 2)	
		res.xyz = float3(sample2.x, sample3.y, sample1.z);
	#elif(iADOF_ShapeChromaMode == 3)	
		res.xyz = float3(sample3.x, sample1.y, sample2.z);
	#elif(iADOF_ShapeChromaMode == 4)	
		res.xyz = float3(sample1.x, sample3.y, sample2.z);
	#elif(iADOF_ShapeChromaMode == 5)	
		res.xyz = float3(sample2.x, sample1.y, sample3.z);
	#elif(iADOF_ShapeChromaMode == 6)	
		res.xyz = float3(sample3.x, sample2.y, sample1.z);
	#endif

	res.w = sample2.w;
	return res;
}

#if(bADOF_ShapeTextureEnable != 0)
 	#undef fADOF_ShapeRotation
 	#undef iADOF_ShapeVertices
 	#define fADOF_ShapeRotation 45.0
 	#define iADOF_ShapeVertices 4
#endif

float3 BokehBlur(sampler2D tex, float2 coord, float CoC, float centerDepth)
{
	float4 res 		= float4(tex2Dlod(tex, float4(coord.xy, 0.0, 0.0)).xyz,1.0);
 	int ringCount          	= round(lerp(1.0,(float)iADOF_ShapeQuality,CoC/DOF_BLURRADIUS));
	float rotAngle		= fADOF_ShapeRotation;
	float2 discRadius 	= CoC*RFX_PixelSize.xy;
	float2 edgeVertices[iADOF_ShapeVertices+1];

	#if(bADOF_ShapeWeightEnable != 0)
		res.w = (1.0-fADOF_ShapeWeightAmount);	
	#endif

	res.xyz = pow(res.xyz,fADOF_BokehCurve)*res.w;

	#if(bADOF_ShapeAnamorphEnable != 0)
		discRadius.x *= fADOF_ShapeAnamorphRatio;
	#endif

	#if(bADOF_RotAnimationEnable != 0)
		rotAngle += fADOF_RotAnimationSpeed*RFX_Timer*0.005;
	#endif

	#if(bADOF_ShapeDiffusionEnable != 0)
		float2 Grain = float2(frac(sin(coord.x + coord.y * 543.31) *  493013.0),
				      frac(cos(coord.x - coord.y * 573.31) *  289013.0));
		Grain = (Grain-0.5)*fADOF_ShapeDiffusionAmount+1.0;
	#endif

	[unroll]
	for (int z = 0; z <= iADOF_ShapeVertices; z++)			
	{								
		sincos( (6.2831853 / iADOF_ShapeVertices)*z + radians(rotAngle), edgeVertices[z].y, edgeVertices[z].x);
	}

	[fastopt]
	for(float i = 1; i <= ringCount; i++)
	{
		[fastopt]
		for (int j = 1; j <= iADOF_ShapeVertices; j++) 
		{
		float radiusCoeff = i/ringCount;
		float blursamples = i;

		#if(bADOF_ShapeTextureEnable != 0)
			blursamples *= 2;
		#endif

			[fastopt]
			for (float k = 0; k < blursamples; k++)
			{
				#if(bADOF_ShapeApertureEnable != 0)
					radiusCoeff *= 1.0 + sin(k/blursamples * 6.2831853 - 1.5707963)*fADOF_ShapeApertureAmount; // * 2 pi - 0.5 pi so it's 1x up and down in [0|1] space.
				#endif

				float2 sampleOffset = lerp(edgeVertices[j-1].xy,edgeVertices[j].xy,k/blursamples) * radiusCoeff;

				#if(bADOF_ShapeCurvatureEnable != 0)
					sampleOffset.xy = lerp(sampleOffset.xy, normalize(sampleOffset.xy) * radiusCoeff,  fADOF_ShapeCurvatureAmount); 
				#endif

				#if(bADOF_ShapeDistortEnable != 0)
					sampleOffset.xy = GetDistortedOffsets(coord.xy, sampleOffset.xy);
				#endif

				#if(bADOF_ShapeDiffusionEnable != 0)
					sampleOffset.xy *= Grain;
				#endif

				#if(bADOF_ShapeChromaEnable != 0)
					float4 tap = tex2Dchroma(tex, coord.xy, sampleOffset.xy * discRadius);
				#else
					float4 tap = tex2Dlod(tex, float4(coord.xy + sampleOffset.xy * discRadius, 0, 0));
				#endif

				tap.w = (tap.w >= centerDepth*0.99) ? 1.0 : pow(abs(tap.w * 2.0 - 1.0),4.0); 

				#if(bADOF_ShapeWeightEnable != 0)
					tap.w *= lerp(1.0,pow(length(sampleOffset.xy),fADOF_ShapeWeightCurve),fADOF_ShapeWeightAmount);
				#endif

				#if(bADOF_ShapeTextureEnable != 0)
					tap.w *= tex2Dlod(SamplerMask, float4((sampleOffset.xy + 0.707)*0.707,0,0)).x;
				#endif
	
				res.xyz += pow(tap.xyz,fADOF_BokehCurve)*tap.w;
				res.w += tap.w;
			}
		}
	}	

	res.xyz = max(res.xyz/res.w,0.0);
	return pow(res.xyz,1.0/fADOF_BokehCurve);
}

void PS_McFlyDOF1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 hdr2R : SV_Target0)
{
	texcoord.xy /= DOF_RENDERRESMULT;

	float4 blurcolor = tex2D(SamplerHDR1, saturate(texcoord.xy));

	float centerDepth = blurcolor.w;
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	if(max(texcoord.x,texcoord.y) > 1.05 || discRadius < 1.2) hdr2R = blurcolor;
	else {
		//doesn't bring that much with intelligent tap calculation
		blurcolor.xyz = (discRadius >= 1.2) ? BokehBlur(SamplerHDR1, texcoord.xy, discRadius, centerDepth) : blurcolor.xyz;
		blurcolor.w = centerDepth;
		hdr2R = blurcolor;
	}
}

float4 PS_McFlyDOF2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{   
	float4 scenecolor = 0.0;
	float4 blurcolor = tex2D(SamplerHDR2, texcoord.xy*DOF_RENDERRESMULT);
	float4 noblurcolor = tex2D(RFX_backbufferColor, texcoord.xy);
	
	float centerDepth = GetCoC(texcoord.xy); 
	float blurAmount = abs(centerDepth * 2.0 - 1.0);
	float discRadius = blurAmount * DOF_BLURRADIUS;

	#if(DOF_AUTOFOCUS != 0)
		discRadius*=(centerDepth < 0.5) ? (1.0 / max(DOF_NEARBLURCURVE * 2.0, 1.0)) : 1.0; 
	#endif

	#if ( bADOF_ImageChromaEnable != 0)
		float2 coord=texcoord.xy*2.0-1.0;
		float centerfact=length(texcoord.xy*2.0-1.0);
		centerfact=pow(centerfact,fADOF_ImageChromaCurve)*fADOF_ImageChromaAmount;

		float chromafact=BUFFER_RCP_WIDTH*centerfact*discRadius;
	
		float3 chromadivisor = 0.0;

		[unroll]
		for (float c=0; c<iADOF_ImageChromaHues; c++)
		{
			float temphue = c/iADOF_ImageChromaHues;
			float3 tempchroma = saturate(float3(abs(temphue * 6.0 - 3.0) - 1.0,2.0 - abs(temphue * 6.0 - 2.0),2.0 - abs(temphue * 6.0 - 4.0)));
			float  tempoffset = (c + 0.5)/iADOF_ImageChromaHues - 0.5; 
			float3 tempsample = tex2Dlod(SamplerHDR2, float4((coord.xy*(1.0+chromafact*tempoffset)*0.5+0.5)*DOF_RENDERRESMULT,0,0)).xyz;
			scenecolor.xyz += tempsample.xyz*tempchroma.xyz;
			chromadivisor += tempchroma;
		}
		scenecolor.xyz /= dot(chromadivisor.xyz, 0.333);
	#else
		scenecolor = blurcolor;
	#endif

	scenecolor.xyz = lerp(scenecolor.xyz, noblurcolor.xyz, smoothstep(2.0,1.2,discRadius));

	scenecolor.w = centerDepth;
	return scenecolor;
}

float4 PS_McFlyDOF3(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 scenecolor = tex2D(RFX_backbufferColor, texcoord.xy);
	float4 blurcolor = 0.0001;
	float outOfFocus = abs(scenecolor.w * 2.0 - 1.0);

	//move all math out of loop if possible
	float2 blurmult = smoothstep(0.3,0.8,outOfFocus) * RFX_PixelSize.xy * fADOF_SmootheningAmount;

	float weights[3] = {1.0,0.75,0.5};
	//Why not seperable? For the glory of Satan, of course!
	for(float x = -2; x <= 2; x++)
	for(float y = -2; y <= 2; y++)	
	{
		float2 offset = float2(x,y);
		float offsetweight = weights[abs(x)]*weights[abs(y)];
		blurcolor.xyz += tex2Dlod(RFX_backbufferColor,float4(texcoord.xy + offset.xy * blurmult,0,0)).xyz * offsetweight;
		blurcolor.w += offsetweight;
	}

	scenecolor.xyz = blurcolor.xyz / blurcolor.w;

	#if(bADOF_ImageGrainEnable != 0)
		float ImageGrain = frac(sin(texcoord.x + texcoord.y * 543.31) *  893013.0 + RFX_Timer * 0.001);

		float3 AnimGrain = 0.5;
		float2 GrainRFX_PixelSize = RFX_PixelSize/fADOF_ImageGrainScale;
		//My emboss noise
		AnimGrain += lerp(tex2D(SamplerNoise, texcoord.xy*fADOF_ImageGrainScale + float2(GrainRFX_PixelSize.x,0)).xyz,tex2D(SamplerNoise, texcoord.xy*fADOF_ImageGrainScale + 0.5 + float2(GrainRFX_PixelSize.x,0)).xyz,ImageGrain.x) * 0.1;
		AnimGrain -= lerp(tex2D(SamplerNoise, texcoord.xy*fADOF_ImageGrainScale + float2(0,GrainRFX_PixelSize.y)).xyz,tex2D(SamplerNoise, texcoord.xy*fADOF_ImageGrainScale + 0.5 + float2(0,GrainRFX_PixelSize.y)).xyz,ImageGrain.x) * 0.1;
		AnimGrain = dot(AnimGrain.xyz,0.333);

		//Photoshop overlay mix mode
		float3 graincolor = (scenecolor.xyz < 0.5 ? (2.0 * scenecolor.xyz * AnimGrain.xxx) : (1.0 - 2.0 * (1.0 - scenecolor.xyz) * (1.0 - AnimGrain.xxx)));
		scenecolor.xyz = lerp(scenecolor.xyz, graincolor.xyz, pow(outOfFocus,fADOF_ImageGrainCurve)*fADOF_ImageGrainAmount);
	#endif

	//focus preview disabled!

	return scenecolor;
}

/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////TECHNIQUES/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

technique DepthOfField_Tech < bool enabled = RFX_Start_Enabled; int toggle = DOF_ToggleKey; >
{
	pass Focus	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_Focus;		RenderTarget = texHDR1;		}
#if(DOF_METHOD == 1)
	pass RingDOF1	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_RingDOF1;		RenderTarget = texHDR2;		}
	pass RingDOF2	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_RingDOF2;		/* renders to backbuffer*/	}
#endif
#if(DOF_METHOD == 2)
	pass MagicDOF1	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_MagicDOF1;		RenderTarget = texHDR2;		}
	pass MagicDOF2	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_MagicDOF2;		/* renders to backbuffer*/	}
#endif
#if(DOF_METHOD == 3)
	pass GPDOF1	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_GPDOF1;		RenderTarget = texHDR2;		}
	pass GPDOF2	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_GPDOF2;		/* renders to backbuffer*/	}
#endif
#if(DOF_METHOD == 4)
	pass MatsoDOF1	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_MatsoDOF1;		RenderTarget = texHDR2;		}
	pass MatsoDOF2	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_MatsoDOF2;		RenderTarget = texHDR1;		}
	pass MatsoDOF3	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_MatsoDOF3;		RenderTarget = texHDR2;		}
	pass MatsoDOF4	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_MatsoDOF4;		/* renders to backbuffer*/	}
#endif
#if(DOF_METHOD == 5)
	pass McFlyDOF1	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_McFlyDOF1;		RenderTarget = texHDR2;		}
	pass McFlyDOF2	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_McFlyDOF2;		/* renders to backbuffer*/	}
	pass McFlyDOF3	{	VertexShader = RFX_VS_PostProcess;	PixelShader  = PS_McFlyDOF3;		/* renders to backbuffer*/	}
#endif
}

#endif

#include MFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()






