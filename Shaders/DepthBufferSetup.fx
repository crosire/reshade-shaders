#include "Reshade.fxh"

uniform int iUIInfo <
	ui_type = "combo";
	ui_label = "Info";
	ui_tooltip = "Pick the value from 'Depth Input Settings'\n"
				 "that lets the scene look the most natural.\n"
				 "Then put the values from the tooltip\n"
				 "into the settings.\n"
				 "(Settings Tab -> Preprocessor Definitions)";
	ui_items = "Info\0";
> = 0;

uniform int iUIDepthSetup <
	ui_type = "drag";
	ui_label = "Depth Input Settings";
	ui_tooltip = "0: RESHADE_DEPTH_INPUT_IS_REVERSED=0\n"
				 "   RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=0\n\n"
				 "1: RESHADE_DEPTH_INPUT_IS_REVERSED=1\n"
				 "   RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=0\n\n"
				 "2: RESHADE_DEPTH_INPUT_IS_REVERSED=0\n"
				 "   RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=1\n\n"
				 "3: RESHADE_DEPTH_INPUT_IS_REVERSED=1\n"
				 "   RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=1\n\n";
	ui_min = 0; ui_max = 3;
	ui_step = 0.05;
> = 0;

uniform bool bUIUpsideDown <
	ui_label = "Depth Buffer is Upside Down";
	ui_tooltip = "Unchecked: RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=0\n"
				 "Checked:   RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=1";
> = false;

uniform bool bUIShowNormals <
	ui_label = "Show Normals";
> = true;

float GetDepth(float2 texcoord, bool upside_down, int depth_setup) {
	//RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
	if(upside_down)
		texcoord.y = 1.0 - texcoord.y;

	float depth = tex2Dlod(ReShade::DepthBuffer, float4(texcoord, 0, 0)).x;
	//RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
	if(depth_setup & 0x02)
	{
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
	}
	//RESHADE_DEPTH_INPUT_IS_REVERSED
	if(depth_setup & 0x01)
		depth = 1.0 - depth;

	const float N = 1.0;
	return depth /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - depth * (RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - N);
}

float3 NormalVector(float2 texcoord, bool upside_down, int depth_setup)
{
	float3 retVal;
	float3 offset = float3(ReShade::PixelSize.xy, 0.0);
	float2 posCenter = texcoord.xy;
	float2 posNorth = posCenter - offset.zy;
	float2 posEast = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter, GetDepth(posCenter, upside_down, depth_setup));
	float3 vertNorth = float3(posNorth, GetDepth(posNorth, upside_down, depth_setup));
	float3 vertEast = float3(posEast, GetDepth(posEast, upside_down, depth_setup));
	
	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

void PS_DepthBufferSetup(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 depth : SV_Target)
{
	float3 retVal;

	if(bUIShowNormals)
		retVal = NormalVector(texcoord, bUIUpsideDown, iUIDepthSetup);
	else
		retVal = GetDepth(texcoord, bUIUpsideDown, iUIDepthSetup).rrr;
		
	depth = retVal;
}

technique DepthBufferSetup
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DepthBufferSetup;
	}
}
