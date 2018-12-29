uniform float3 Tint <
	ui_type = "color";
> = float3(0.55, 0.43, 0.42);

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.58;

#include "ReShade.fxh"

float3 TintPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	return lerp(col, col * Tint * 2.55, Strength);
}

technique Tint
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TintPass;
	}
}
