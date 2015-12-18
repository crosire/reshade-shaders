#include "Common.fx"

#ifndef RFX_duplicate
#include MartyMcFly_SETTINGS_DEF
#endif

#if USE_FISHEYE_CA

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
//Credits :: icelaglace, a.o => (ported from some blog, author unknown)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

namespace MartyMcFly
{

float4 PS_FISHEYE_CA(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
	float4 coord=0.0;
	coord.xy=texcoord.xy;
	coord.w=0.0;

	float4 color = 0.0.xxxx;
	  
	float3 eta = float3(1.0+fFisheyeColorshift*0.9,1.0+fFisheyeColorshift*0.6,1.0+fFisheyeColorshift*0.3);
	float2 center;
	center.x = coord.x-0.5;
	center.y = coord.y-0.5;
	float LensZoom = 1.0/fFisheyeZoom;

	float r2 = (texcoord.x-0.5) * (texcoord.x-0.5) + (texcoord.y-0.5) * (texcoord.y-0.5);     
	float f = 0;

	if( fFisheyeDistortionCubic == 0.0){
		f = 1 + r2 * fFisheyeDistortion;
	}else{
                f = 1 + r2 * (fFisheyeDistortion + fFisheyeDistortionCubic * sqrt(r2));
	};

	float x = f*LensZoom*(coord.x-0.5)+0.5;
	float y = f*LensZoom*(coord.y-0.5)+0.5;
	float2 rCoords = (f*eta.r)*LensZoom*(center.xy*0.5)+0.5;
	float2 gCoords = (f*eta.g)*LensZoom*(center.xy*0.5)+0.5;
	float2 bCoords = (f*eta.b)*LensZoom*(center.xy*0.5)+0.5;
	
	color.x = tex2D(RFX::backbufferColor,rCoords).r;
	color.y = tex2D(RFX::backbufferColor,gCoords).g;
	color.z = tex2D(RFX::backbufferColor,bCoords).b;

	return color;
}

technique FishEye_Tech <bool enabled = 
#if (FishEye_TimeOut > 0)
1; int toggle = FishEye_ToggleKey; timeout = FishEye_TimeOut; >
#else
RFX_Start_Enabled; int toggle = FishEye_ToggleKey; >
#endif
{
	pass FISHEYE_CA
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = PS_FISHEYE_CA;
	}
}

}

#endif

#ifndef RFX_duplicate
#include MartyMcFly_SETTINGS_UNDEF
#endif
