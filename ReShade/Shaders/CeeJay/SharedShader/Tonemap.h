/*------------------------------------------------------------------------------
						TONEMAP
------------------------------------------------------------------------------*/
// Version 1.1

float4 TonemapPass( float4 colorInput )
{
	float3 color = colorInput.rgb;

	color = saturate(color - Defog * FogColor); // Defog
	
	color *= pow(2.0f, Exposure); // Exposure
	
	color = pow(color, Gamma);    // Gamma -- roll into the first gamma correction in main.h ?

	//#define BlueShift 0.00	//Blueshift
	//float4 d = color * float4(1.05f, 0.97f, 1.27f, color.a);
	//color = lerp(color, d, BlueShift);
	
	float3 lumCoeff = float3(0.2126, 0.7152, 0.0722);
	float lum = dot(lumCoeff, color.rgb);
	
	float3 blend = lum.rrr; //dont use float3
	
	float L = saturate( 10.0 * (lum - 0.45) );
  	
	float3 result1 = 2.0f * color.rgb * blend;
	float3 result2 = 1.0f - 2.0f * (1.0f - blend) * (1.0f - color.rgb);
	
	float3 newColor = lerp(result1, result2, L);
	//float A2 = Bleach * color.rgb; //why use a float for A2 here and then multiply by color.rgb (a float3)?
	float3 A2 = Bleach * color.rgb; //
	float3 mixRGB = A2 * newColor;
	
	color.rgb += ((1.0f - A2) * mixRGB);
	
	//float3 middlegray = float(color.r + color.g + color.b) / 3;
	float3 middlegray = dot(color,(1.0/3.0)); //1fps slower than the original on nvidia, 2 fps faster on AMD
	
	float3 diffcolor = color - middlegray; //float 3 here
	colorInput.rgb = (color + diffcolor * Saturation)/(1+(diffcolor*Saturation)); //saturation
	
	return colorInput;
}