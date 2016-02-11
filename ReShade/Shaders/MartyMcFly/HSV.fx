#include "Common.fx"
#include MartyMcFly_SETTINGS_DEF

#if (USE_HSV == 1)

namespace MartyMcFly
{

float ColorEqualizerMod(in float H)	
{
	float SMod = 0.0;
	SMod += fSaturationModRed * ( 1.0 - min( 1.0, abs( H / 0.08333333 ) ) );
	SMod += fSaturationModOrange * ( 1.0 - min( 1.0, abs( ( 0.08333333 - H ) / ( - 0.08333333 ) ) ) );
	SMod += fSaturationModYellow * ( 1.0 - min( 1.0, abs( ( 0.16666667 - H ) / ( - 0.16666667 ) ) ) );
	SMod += fSaturationModGreen * ( 1.0 - min( 1.0, abs( ( 0.33333333 - H ) / 0.16666667 ) ) );
	SMod += fSaturationModCyan * ( 1.0 - min( 1.0, abs( ( 0.5 - H ) / 0.16666667 ) ) );
	SMod += fSaturationModBlue * ( 1.0 - min( 1.0, abs( ( 0.66666667 - H ) / 0.16666667 ) ) );
	SMod += fSaturationModMagenta * ( 1.0 - min( 1.0, abs( ( 0.83333333 - H ) / 0.16666667 ) ) );
	SMod += fSaturationModRed * ( 1.0 - min( 1.0, abs( ( 1.0 - H ) / 0.16666667 ) ) );
	return SMod;
}

float ColorEqualizerMult(in float H)
{
	float SMult = 1.0;
	SMult += fSaturationMultRed * ( 1.0 - min( 1.0, abs( H / 0.08333333 ) ) );
	SMult += fSaturationMultOrange * ( 1.0 - min( 1.0, abs( ( 0.08333333 - H ) / ( - 0.08333333 ) ) ) );
	SMult += fSaturationMultYellow * ( 1.0 - min( 1.0, abs( ( 0.16666667 - H ) / ( - 0.16666667 ) ) ) );
	SMult += fSaturationMultGreen * ( 1.0 - min( 1.0, abs( ( 0.33333333 - H ) / 0.16666667 ) ) );
	SMult += fSaturationMultCyan * ( 1.0 - min( 1.0, abs( ( 0.5 - H ) / 0.16666667 ) ) );
	SMult += fSaturationMultBlue * ( 1.0 - min( 1.0, abs( ( 0.66666667 - H ) / 0.16666667 ) ) );
	SMult += fSaturationMultMagenta * ( 1.0 - min( 1.0, abs( ( 0.83333333 - H ) / 0.16666667 ) ) );
	SMult += fSaturationMultRed * ( 1.0 - min( 1.0, abs( ( 1.0 - H ) / 0.16666667 ) ) );
	return SMult;
}

float ColorEqualizerPow(in float H)	
{
	float SPow = 1.0;
	SPow += fSaturationPowRed * ( 1.0 - min( 1.0, abs( H / 0.08333333 ) ) );
	SPow += fSaturationPowOrange * ( 1.0 - min( 1.0, abs( ( 0.08333333 - H ) / ( - 0.08333333 ) ) ) );
	SPow += fSaturationPowYellow * ( 1.0 - min( 1.0, abs( ( 0.16666667 - H ) / ( - 0.16666667 ) ) ) );
	SPow += fSaturationPowGreen * ( 1.0 - min( 1.0, abs( ( 0.33333333 - H ) / 0.16666667 ) ) );
	SPow += fSaturationPowCyan  * ( 1.0 - min( 1.0, abs( ( 0.5 - H ) / 0.16666667 ) ) );
	SPow += fSaturationPowBlue * ( 1.0 - min( 1.0, abs( ( 0.66666667 - H ) / 0.16666667 ) ) );
	SPow += fSaturationPowMagenta * ( 1.0 - min( 1.0, abs( ( 0.83333333 - H ) / 0.16666667 ) ) );
	SPow += fSaturationPowRed * ( 1.0 - min( 1.0, abs( ( 1.0 - H ) / 0.16666667 ) ) );
	return SPow;
}

float3 HUEtoRGB(in float H)
{
   	float R = abs(H * 6.0 - 3.0) - 1.0;
   	float G = 2.0 - abs(H * 6.0 - 2.0);
   	float B = 2.0 - abs(H * 6.0 - 4.0);
   	return saturate(float3(R,G,B));
}

float RGBCVtoHUE(in float3 RGB, in float C, in float V)
{
     	float3 Delta = (V - RGB) / C;
     	Delta.rgb -= Delta.brg;
     	Delta.rgb += float3(2.0,4.0,6.0);
     	Delta.brg = step(V, RGB) * Delta.brg;
     	float H;
     	H = max(Delta.r, max(Delta.g, Delta.b));
     	return frac(H / 6.0);
}

float3 HSVtoRGB(in float3 HSV)
{
   	float3 RGB = HUEtoRGB(HSV.x);
   	return ((RGB - 1) * HSV.y + 1) * HSV.z;
}
 
float3 RGBtoHSV(in float3 RGB)
{
   	float3 HSV = 0.0;
   	HSV.z = max(RGB.r, max(RGB.g, RGB.b));
   	float M = min(RGB.r, min(RGB.g, RGB.b));
   	float C = HSV.z - M;
   	if (C != 0.0)
   	{
     		HSV.x = RGBCVtoHUE(RGB, C, HSV.z);
     		HSV.y = C / HSV.z;
   	}
   	return HSV;
}

float4 PS_HSV(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);

	float3 hsvcolor = RGBtoHSV( color.xyz );
	//global adjustments
	hsvcolor.x = fColorHueMod + ( fColorHueMult * pow( hsvcolor.x, fColorHuePow ) );
	hsvcolor.y = fColorSaturationMod + ( fColorSaturationMult * pow( hsvcolor.y, fColorSaturationPow ) );
	hsvcolor.z = fColorIntensityMod + ( fColorIntensityMult * pow( hsvcolor.z, fColorIntensityPow ) );
	//hue specific adjustments. Yes, hue. huehuehuehuehue.
	hsvcolor.y = ColorEqualizerMod( hsvcolor.x ) + ( ColorEqualizerMult( hsvcolor.x ) * pow( hsvcolor.y, ColorEqualizerPow( hsvcolor.x ) ) );
	hsvcolor.yz = max( hsvcolor.yz, 0.0 );
	color.xyz = HSVtoRGB( hsvcolor );

	return color;
}

technique HSV_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = HSV_ToggleKey; >
{
	pass HSVPass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_HSV;
	}
}

}

#endif

#include MartyMcFly_SETTINGS_UNDEF
