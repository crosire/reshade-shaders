#include Ganossa_SETTINGS_DEF

#if USE_Border

//Border Shader

namespace Ganossa
{

texture bMaskTex < source = "ReShade/Ganossa/Textures/bMask.png"; > { Width = 1920; Height = 1080; MipLevels = 1; Format = RGBA8; };
sampler bMaskColor { Texture = bMaskTex; };

float4 PS_Border(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return lerp(0.0.xxxx, tex2D(RFX_backbufferColor, texcoord), tex2D(bMaskColor, texcoord).r); 
}

technique Border_Tech <bool enabled = RFX_Start_Enabled; int toggle = Border_ToggleKey; >
{
	pass 
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_Border;
	}
}

}

#endif

#include Ganossa_SETTINGS_UNDEF
