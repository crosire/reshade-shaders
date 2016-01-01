/*------------------------------------------------------------------------------
						SEPIA
------------------------------------------------------------------------------*/

float4 SepiaPass( float4 colorInput )
{
	float3 sepia = colorInput.rgb;
	
	// calculating amounts of input, grey and sepia colors to blend and combine
	float grey = dot(sepia, float3(0.2126, 0.7152, 0.0722));
	
	sepia *= ColorTone;
	
	float3 blend2 = (grey * GreyPower) + (colorInput.rgb / (GreyPower + 1));

	colorInput.rgb = lerp(blend2, sepia, SepiaPower);
	
	// returning the final color
	return colorInput;
}

    //TODO: do speed comparisons of these on nvidia hardware
    /*
    float3 blend2 = (grey * GreyPower) + (colorInput.rgb / (GreyPower + 1)); //379fps AMD

    float3 blend2 = (GreyPower * (grey * GreyPower + grey) + colorInput.rgb) / (GreyPower + 1); //379fps AMD

    float3 blend2 = (grey * GreyPower * (GreyPower+1) + colorInput.rgb) / (GreyPower + 1); //379fps AMD

    float3 blend2 = (grey * GreyPower + grey * GreyPower * GreyPower + colorInput.rgb) / (GreyPower + 1); //379fps AMD
    */
