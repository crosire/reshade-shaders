   /*-----------------------------------------------------------.   
  /                        TECHNICOLOR2                         /
  '-----------------------------------------------------------*/
// Original by Prod80
// - Version 1.0

//TECHNICOLOR

float4 Technicolor2(float4 colorInput)
{
	float3 Color_Strength = float3(Technicolor2_Red_Strength,Technicolor2_Green_Strength,Technicolor2_Blue_Strength);
	float3 source = saturate(colorInput.rgb);
	float3 temp = 1.0 - source;
	float3 target = temp.grg;
	float3 target2 = temp.bbr;
	float3 temp2 = source.rgb * target.rgb;
	temp2.rgb *= target2.rgb;

	temp.rgb = temp2.rgb * Color_Strength;
	temp2.rgb *= Technicolor2_Brightness;

	target.rgb = temp.grg;
	target2.rgb = temp.bbr;

	temp.rgb = source.rgb - target.rgb;
	temp.rgb += temp2.rgb;
	temp2.rgb = temp.rgb - target2.rgb;

	colorInput.rgb = lerp(source.rgb, temp2.rgb, Technicolor2_Strength);

	colorInput.rgb = lerp(dot(colorInput.rgb, 0.333), colorInput.rgb, Technicolor2_Saturation); 
	
	return colorInput;
}