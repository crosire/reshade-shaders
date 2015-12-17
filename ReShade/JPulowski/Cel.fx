/*
 Depth-buffer based cel shading for ENB by kingeric1992
 http://enbseries.enbdev.com/forum/viewtopic.php?f=7&t=3244#p53168

 Modified and optimized for ReShade by JPulowski
 http://reshade.me/forum/shader-presentation/261-paint-effect-and-depth-buffer-based-cel-shading
 
 Do not distribute without giving credit to the original author(s).
 
 1.0  - Initial release/port
 1.1  - Replaced depth linearization algorithm with another one by Crosire
        Added an option to tweak accuracy
	    Modified the code to make it compatible with SweetFX 2.0 Preview 7 and new Operation Piggyback which should give some performance increase
 1.1a - Framework port 
*/

#include JPulowski_SETTINGS_DEF

#if (USE_CEL == 1)

namespace JPulowski
{
namespace CellShading
{

float linearlizeDepth(float nonlinearDepth)
{
return (CelAccuracy == 0.0) ? 0.0001 / (-999.0 * nonlinearDepth + 1001.0) : CelAccuracy / (-999.0 * nonlinearDepth + 1001.0);
}

float3 normals(float2 texcoord)//get normal vector from depthmap
{
	float	deltax = linearlizeDepth(tex2D(RFX_depthColor, float2((texcoord.x + px), texcoord.y)).x) - linearlizeDepth(tex2D(RFX_depthColor, float2((texcoord.x - px), texcoord.y)).x),
			deltay = linearlizeDepth(tex2D(RFX_depthColor, float2(texcoord.x, (texcoord.y + py))).x) - linearlizeDepth(tex2D(RFX_depthColor, float2(texcoord.x, (texcoord.y - py))).x);	
		
	return normalize(float3( (deltax / 2 / px), (deltay / 2 / py) , 1));
}

float3 CelPass(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = tex2D(RFX_backbufferColor, texcoord).rgb,
	
	Gx[3] =
	{
		float3(-1, 0, 1),
		float3(-2, 0, 2),
		float3(-1, 0, 1)
	},
	
	Gy[3] =
	{
		float3(1, 2, 1),
		float3(0, 0, 0),
		float3(-1, -2, -1)
	},
	
	dotx = 0, doty = 0;
	int i;
	
	for(i = 0; i < 3; i++)
	{
		dotx += Gx[i].x * normals(float2((texcoord.x - px), (texcoord.y + ((-1 + i) * py))));
		dotx += Gx[i].y * normals(float2(texcoord.x, (texcoord.y + ((-1 + i) * py))));
		dotx += Gx[i].z * normals(float2((texcoord.x + px), (texcoord.y + ((-1 + i) * py))));
		
		doty += Gy[i].x * normals(float2((texcoord.x - px), (texcoord.y + ((-1 + i) * py))));
		doty += Gy[i].y * normals(float2(texcoord.x, (texcoord.y + ((-1 + i) * py))));
		doty += Gy[i].z * normals(float2((texcoord.x + px), (texcoord.y + ((-1 + i) * py))));
	}
	
	color -= step(1, sqrt( dot(dotx, dotx) + dot(doty, doty)));
	
	return color;
}

technique Cel_Tech <bool enabled = RFX_Start_Enabled; int toggle = Cel_ToggleKey; >
{
	pass Cel_Pass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = CelPass;
	}
}

}
}

#endif

#include JPulowski_SETTINGS_UNDEF
