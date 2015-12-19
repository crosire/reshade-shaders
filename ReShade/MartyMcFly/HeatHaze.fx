#include "Common.fx"
#include "ReShade/Ganossa/Common.fx"

#ifndef RFX_duplicate
#include MartyMcFly_SETTINGS_DEF
#endif

#if USE_HEATHAZE

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

namespace MartyMcFly
{

texture   texHeat   < string source = "ReShade/MartyMcFly/Textures/mcheat.png";   > {Width = 512;Height = 512;Format = RGBA8;};

sampler2D SamplerHeat
{
	Texture = texHeat;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Repeat;
	AddressV = Repeat;
};

float4 PS_HeatHaze(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
	float4 color = 0.0.xxxx;
	float3 heatnormal = tex2Dlod(SamplerHeat, float4(texcoord.xy*fHeatHazeTextureScale+float2(0.0,RFX::Timer.x*0.0001*fHeatHazeSpeed),0,0)).rgb - 0.5;
    	float2 heatoffset = normalize(heatnormal.xy) * pow(length(heatnormal.xy), 0.5);
	float3 heathazecolor = 0;

#include Ganossa_SETTINGS_DEF
#if AL_HeatHazeControle && USE_AMBIENT_LIGHT
	#include "ReShade/Ganossa/BrightDetect.fx"
	#include "ReShade/Ganossa/HeatHazeControle.fx"
#else	
	heathazecolor.y = tex2D(RFX::backbufferColor, texcoord.xy + heatoffset.xy * 0.001 * fHeatHazeOffset).y;
	heathazecolor.x = tex2D(RFX::backbufferColor, texcoord.xy + heatoffset.xy * 0.001 * fHeatHazeOffset * (1.0+fHeatHazeChromaAmount)).x;
	heathazecolor.z = tex2D(RFX::backbufferColor, texcoord.xy + heatoffset.xy * 0.001 * fHeatHazeOffset * (1.0-fHeatHazeChromaAmount)).z;
#endif
#include Ganossa_SETTINGS_UNDEF

	color.xyz = heathazecolor;
 #if(bHeatHazeDebug == 1)
	color.xyz = heatnormal.xyz+0.5;
 #endif
	return color;
}

technique HeatHaze_Tech <bool enabled = 
#if (HeatHaze_TimeOut > 0)
1; int toggle = HeatHaze_ToggleKey; timeout = HeatHaze_TimeOut; >
#else
RFX_Start_Enabled; int toggle = HeatHaze_ToggleKey; >
#endif
{
	pass HeatHaze
	{
		VertexShader = RFX::VS_PostProcess;
		PixelShader = PS_HeatHaze;
	}
}

}

#endif

#ifndef RFX_duplicate
#include MartyMcFly_SETTINGS_UNDEF
#endif
