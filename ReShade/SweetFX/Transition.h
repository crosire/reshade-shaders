#include SFX_SETTINGS_DEF

#if (USE_Transition == 1)

NAMESPACE_ENTER(SFX)

texture transitionTex < string source = "ReShade/SweetFX/Textures/" Transition_texture ; >
{
	Width = Transition_texture_width;
	Height = Transition_texture_height;
};

sampler transitionSampler
{
	Texture = transitionTex;
};

  /*------------------.
  | :: Transitions :: |
  '------------------*/
/*
These effects run when SweetFX is initialized and disable themselves when a counter (RFX_TechniqueTimeLeft) reaches 0
*/

// MMMmnnn Juicy :)
void FadeIn(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{
	color = tex2D(RFX_backbufferColor, texcoord);
	color.rgb *= -RFX_TechniqueTimeLeft * (1.0 / 8000.0) + 1.0;
}
void FadeOut(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{
	color = tex2D(RFX_backbufferColor, texcoord);
	color.rgb *= RFX_TechniqueTimeLeft * (1.0 / 8000.0) - 1.0;
}

void CurtainOpen(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{
		const float curtain_time = 3500.0; //Time it takes for the curtain to slide away. (RFX_TechniqueTimeLeft - curtain_time) will be the time before it starts to slide away.

		float coord = abs(texcoord.x - 0.5);
		float factor = saturate(1.0 - RFX_TechniqueTimeLeft / curtain_time);

		if (coord < factor || RFX_Timer > 10000.0)
			color = tex2D(RFX_backbufferColor, texcoord);
		else
			color = tex2D(transitionSampler, texcoord + float2(texcoord.x < 0.5 ? factor : -factor, 0));
}
void CurtainClose(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{
  float coord = abs(texcoord.x - 0.5);
  float factor = (RFX_TechniqueTimeLeft / 8000.0);
  if (coord < factor)
	  color = tex2D(RFX_backbufferColor, texcoord);
  else
	  color = tex2D(transitionSampler, texcoord + float2(texcoord.x < 0.5 ? factor : -factor, 0));
}

void ImageFadeOut(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
	float3 image = tex2D(transitionSampler, texcoord).rgb;
	color = tex2D(RFX_backbufferColor, texcoord).rgb;
	color = lerp(color,image, saturate(RFX_TechniqueTimeLeft * (1.0 / 1000.0)));
}

technique Transition_Tech < bool enabled = true; int timeout = Transition_time; int toggle = Transition_ToggleKey;> //sets the RFX_TechniqueTimeLeft value. When it reaches 0 the technique is disabled.
{
	pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = Transition_type;
	}
}

NAMESPACE_LEAVE()

#endif

#include SFX_SETTINGS_UNDEF