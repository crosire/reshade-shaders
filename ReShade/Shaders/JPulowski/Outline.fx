/*
 Depth-buffer based cel shading for ENB by kingeric1992
 http://enbseries.enbdev.com/forum/viewtopic.php?f=7&t=3244#p53168

 Modified and optimized for ReShade by JPulowski
 http://reshade.me/forum/shader-presentation/261
 
 Do not distribute without giving credit to the original author(s).
 
 1.0  - Initial release/port
 1.1  - Replaced depth linearization algorithm with another one by crosire
        Added an option to tweak accuracy
	    Modified the code to make it compatible with SweetFX 2.0 Preview 7 and new Operation Piggyback which should give some performance increase
 1.1a - Framework port
 1.2  - Changed the name to "Outline" since technically this is not Cel shading (See https://en.wikipedia.org/wiki/Cel_shading)
		Added custom outline and background color support
		Added a threshold and opacity modifier
*/

#include EFFECT_CONFIG(JPulowski)
#if (USE_OUTLINE == 1)

namespace JPulowski {

float linearlizeDepth(float nonlinearDepth) {
	return (OutlineAccuracy == 0.0) ? 0.0001 / (-999.0 * nonlinearDepth + 1001.0) : OutlineAccuracy / (-999.0 * nonlinearDepth + 1001.0);
}

float3 normals(float2 texcoord) { // Get normal vector from depthmap
	float	deltax = linearlizeDepth(tex2D(ReShade::OriginalDepth, float2((texcoord.x + BUFFER_RCP_WIDTH), texcoord.y)).x) - linearlizeDepth(tex2D(ReShade::OriginalDepth, float2((texcoord.x - BUFFER_RCP_WIDTH), texcoord.y)).x),
			deltay = linearlizeDepth(tex2D(ReShade::OriginalDepth, float2(texcoord.x, (texcoord.y + BUFFER_RCP_HEIGHT))).x) - linearlizeDepth(tex2D(ReShade::OriginalDepth, float2(texcoord.x, (texcoord.y - BUFFER_RCP_HEIGHT))).x);	
		
	return normalize(float3((deltax / 2.0 / BUFFER_RCP_WIDTH), (deltay / 2.0 / BUFFER_RCP_HEIGHT), 1.0));
}

float3 PS_Outline(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target {
	
	#if (OutlineCustomBackground == 0)
		float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb,
	#else
		float3 color = OutlineBackgroundColor,
	#endif
	
	Gx[3] =
	{
		float3(-1.0, 0.0, 1.0),
		float3(-2.0, 0.0, 2.0),
		float3(-1.0, 0.0, 1.0)
	},
	
	Gy[3] =
	{
		float3( 1.0,  2.0,  1.0),
		float3( 0.0,  0.0,  0.0),
		float3(-1.0, -2.0, -1.0)
	},
	
	dotx = 0.0, doty = 0.0;
	
	for(int i = 0; i < 3; i++) {
		dotx += Gx[i].x * normals(float2((texcoord.x - BUFFER_RCP_WIDTH), (texcoord.y + ((-1 + i) * BUFFER_RCP_HEIGHT))));
		dotx += Gx[i].y * normals(float2(texcoord.x, (texcoord.y + ((-1 + i) * BUFFER_RCP_HEIGHT))));
		dotx += Gx[i].z * normals(float2((texcoord.x + BUFFER_RCP_WIDTH), (texcoord.y + ((-1 + i) * BUFFER_RCP_HEIGHT))));
		
		doty += Gy[i].x * normals(float2((texcoord.x - BUFFER_RCP_WIDTH), (texcoord.y + ((-1 + i) * BUFFER_RCP_HEIGHT))));
		doty += Gy[i].y * normals(float2(texcoord.x, (texcoord.y + ((-1 + i) * BUFFER_RCP_HEIGHT))));
		doty += Gy[i].z * normals(float2((texcoord.x + BUFFER_RCP_WIDTH), (texcoord.y + ((-1 + i) * BUFFER_RCP_HEIGHT))));
	}
	
	color = lerp(color, OutlineColor, step(OutlineThreshold, sqrt(dot(dotx, dotx) + dot(doty, doty)))); // Return custom color when weight over threshold
	
	// Set opacity
	#if (OutlineCustomBackground == 0)
		color = lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, color, OutlineOpacity);
	#else
		color = lerp(OutlineBackgroundColor, color, OutlineOpacity);
	#endif
	
	return color;
}

technique Outline_Tech <bool enabled = RFX_Start_Enabled; int toggle = Outline_ToggleKey; >
{
	pass Outline_Pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Outline;
	}
}

}

#endif
#include "ReShade/Shaders/JPulowski.undef"