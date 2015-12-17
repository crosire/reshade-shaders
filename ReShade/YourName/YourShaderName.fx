#include "ReShade/YourName.cfg"

#if (USE_CUSTOM == 1)

float4 PS_Custom(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(RFX_backbufferColor, texcoord);
}

technique Custom_Tech <bool enabled = RFX_Start_Enabled; int toggle = Custom_ToggleKey; >
{
	pass CustomPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_Custom;
	}
}

#endif

#include "ReShade/YourName.undef"
