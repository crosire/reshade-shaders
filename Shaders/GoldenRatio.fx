///////////////////////////////////////////////////////////////////
// This effects shows an overlay with fibonacci spirals to quickly
// see where the golden ratios are in the image. For screenshotters mainly. 
///////////////////////////////////////////////////////////////////
// By Otis / Infuse Project
///////////////////////////////////////////////////////////////////

#include "Reshade.fxh"

// Constants
#define GOR_ToggleKey RESHADE_TOGGLE_KEY //[undef] //-Key to toggle the overlay on or off.

// Variables
uniform float Opacity < ui_type="drag"; ui_min=0.0; ui_max=1.0; ui_tooltip="Opacity of overlay. 0 is invisible, 1 is opaque lines."> = 0.30;
uniform int ResizeMode < ui_type="int"; ui_min=0; ui_max=1; ui_tooltip="Resize mode: 0 is clamp to screen (so resizing of overlay, no golden ratio by definition), 1: resize to either full with or full height while keeping aspect ratio: golden ratio by definition in lined area"> = 1;

// Code
texture2D	GOR_texSpirals < string source= "GoldenSpirals.png"; > { Width = 1748; Height = 1080; MipLevels = 1; Format = RGBA8; };
sampler2D	GOR_samplerSpirals
{
	Texture = GOR_texSpirals;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

void PS_Otis_GOR_RenderSpirals(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
{
	float4 colFragment = tex2D(BackBuffer, texcoord);
	float phiValue = ((1.0 + sqrt(5.0))/2.0);
	float aspectRatio = (float(BUFFER_WIDTH)/float(BUFFER_HEIGHT));
	float idealWidth = float(BUFFER_HEIGHT) * phiValue;
	float idealHeight = float(BUFFER_WIDTH) / phiValue;
	float4 sourceCoordFactor = float4(1.0, 1.0, 1.0, 1.0);

	if(ResizeMode==1)
	{
		if(aspectRatio < phiValue)
		{
			// display spirals at full width, but resize across height
			sourceCoordFactor = float4(1.0, float(BUFFER_HEIGHT)/idealHeight, 1.0, idealHeight/float(BUFFER_HEIGHT));
		}
		else
		{
			// display spirals at full height, but resize across width
			sourceCoordFactor = float4(float(BUFFER_WIDTH)/idealWidth, 1.0, idealWidth/float(BUFFER_WIDTH), 1.0);
		}
	}
	float4 spiralFragment = tex2D(GOR_samplerSpirals, float2((texcoord.x * sourceCoordFactor.x) - ((1.0-sourceCoordFactor.z)/2.0),
														    (texcoord.y * sourceCoordFactor.y) - ((1.0-sourceCoordFactor.w)/2.0)));
	outFragment = saturate(colFragment + (spiralFragment * Opacity));
}

technique Otis_GoldenRatio <bool enabled = false; int toggle = GOR_ToggleKey; >
{
	pass GoldenRatioPass
	{
		VertexShader = VS_PostProcess;
		PixelShader = PS_Otis_GOR_RenderSpirals;
	}
}

