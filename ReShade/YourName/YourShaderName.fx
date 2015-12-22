#include "ReShade/YourName.cfg"

#if (USE_YourShaderName == 1)

float4 PS_YourShaderName(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(ReShade::BackBuffer, texcoord);
}

technique YourShaderName_Tech <bool enabled = RFX_Start_Enabled; int toggle = YourShaderName_ToggleKey; >
{
	pass YourShaderNamePass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_YourShaderName;
	}
}

#endif

#include "ReShade/YourName.undef"
