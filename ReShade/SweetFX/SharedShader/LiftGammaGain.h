   /*-----------------------------------------------------------.   
  /                      Lift Gamma Gain                        /
  '-----------------------------------------------------------*/
/*
  by 3an and CeeJay.dk
  
  Version 1.1
*/

float4 LiftGammaGainPass( float4 colorInput )
{
	// -- Get input --
	float3 color = colorInput.rgb;
	
	// -- Lift --
	//color = color + (RGB_Lift / 2.0 - 0.5) * (1.0 - color); 
	color = color * (1.5-0.5 * RGB_Lift) + 0.5 * RGB_Lift - 0.5;
	color = saturate(color); //isn't strictly necessary, but doesn't cost performance.
	
	// -- Gain --
	color *= RGB_Gain; 
	
	// -- Gamma --
	colorInput.rgb = pow(color, 1.0 / RGB_Gamma); //Gamma
	
	// -- Return output --
	//return (colorInput);
	return saturate(colorInput);
}