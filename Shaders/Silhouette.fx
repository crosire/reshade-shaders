// Made by Marot Satil for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
// Follow @GPOSERS_FFXIV on Twitter and join us on Discord (https://discord.gg/39WpvU2)
// for the latest GShade package updates!
//
// A bit of an accidental discovery when playing with StageDepth.fx, this
// shader allows you to do a depth-based silhouette with any two images or solid colors.
//
// PNG transparency is fully supported just like with StageDepth.fx!
//
// Shader & Code Copyright (c) 2019, Marot Satil
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#include "Reshade.fxh"

#define TEXFORMAT RGBA8

uniform bool SEnable_Foreground_Color <
    ui_label = "Enable Foreground Color";
    ui_tooltip = "Enable this to use a color instead of a texture for the foreground!";   
> = false;

uniform int3 SForeground_Color <
    ui_label = "Foreground Color (If Enabled)";
    ui_tooltip = "If you enabled foreground color, use this to select the color.";
    ui_min = 0;
    ui_max = 255;
> = int3(0, 0, 0);

uniform float SForeground_Stage_Opacity <
    ui_label = "Foreground Opacity";
    ui_tooltip = "Set the transparency of the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform int SForeground_Tex_Select <
    ui_label = "Foreground Texture";
    ui_tooltip = "The image to use in the foreground.";
    ui_type = "combo";
    ui_items = "Silhouette1.png\0Silhouette2.png\0";
> = 0;

uniform bool SEnable_Background_Color <
    ui_label = "Enable Background Color";
    ui_tooltip = "Enable this to use a color instead of a texture for the background!";   
> = false;

uniform int3 SBackground_Color <
    ui_label = "Background Color (If Enabled)";
    ui_tooltip = "If you enabled background color, use this to select the color.";
    ui_min = 0;
    ui_max = 255;
> = int3(255, 255, 255);

uniform float SBackground_Stage_Opacity <
    ui_label = "Background Opacity";
    ui_tooltip = "Set the transparency of the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float SBackground_Stage_depth <
	ui_type = "slider";
	ui_min = 0.001;
	ui_max = 1.0;
	ui_label = "Background Depth";
> = 0.500;

uniform int SBackground_Tex_Select <
    ui_label = "Background Texture";
    ui_tooltip = "The image to use in the background.";
    ui_type = "combo";
    ui_items = "Silhouette1.png\0Silhouette2.png\0";
> = 1;

texture sSilhouette_one_texture <source="Silhouette1.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler sSilhouette_one_sampler { Texture = sSilhouette_one_texture; };

texture sSilhouette_two_texture <source="Silhouette2.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler sSilhouette_two_sampler { Texture = sSilhouette_two_texture; };

void PS_SilhouetteForeground(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
  float4 Silhouette_one_stage = tex2D(sSilhouette_one_sampler, texcoord).rgba;
  float4 Silhouette_two_stage = tex2D(sSilhouette_two_sampler, texcoord).rgba;

	color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float depth = 1.0 - ReShade::GetLinearizedDepth(texcoord).r;

  if (SEnable_Foreground_Color == true)
  {
  color = lerp(color, SForeground_Color.rgb * 0.00392, SForeground_Stage_Opacity);
  }
  else if (SForeground_Tex_Select == 0)
	{
    color = lerp(color, Silhouette_one_stage.rgb, Silhouette_one_stage.a * SForeground_Stage_Opacity);
	}
  else
	{
    color = lerp(color, Silhouette_two_stage.rgb, Silhouette_two_stage.a * SForeground_Stage_Opacity);
	}
}

void PS_SilhouetteBackground(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
  float4 Silhouette_one_stage = tex2D(sSilhouette_one_sampler, texcoord).rgba;
  float4 Silhouette_two_stage = tex2D(sSilhouette_two_sampler, texcoord).rgba;

	color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float depth = 1 - ReShade::GetLinearizedDepth(texcoord).r;

  if ((SEnable_Background_Color == true) && (depth < SBackground_Stage_depth))
  {
  color = lerp(color, SBackground_Color.rgb * 0.00392, SBackground_Stage_Opacity);
  }
	else if ((SBackground_Tex_Select == 0) && (depth < SBackground_Stage_depth))	
	{
    color = lerp(color, Silhouette_one_stage.rgb, Silhouette_one_stage.a * SBackground_Stage_Opacity);
	}
	else if ((SBackground_Tex_Select == 1) && (depth < SBackground_Stage_depth))	
	{
    color = lerp(color, Silhouette_two_stage.rgb, Silhouette_two_stage.a * SBackground_Stage_Opacity);
	}
}

technique Silhouette
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_SilhouetteForeground;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_SilhouetteBackground;
	}	
}