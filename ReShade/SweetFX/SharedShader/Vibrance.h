   /*-----------------------------------------------------------.
  /                          Vibrance                           /
  '-----------------------------------------------------------*/
/*
  by Christian Cann Schuldt Jensen ~ CeeJay.dk

  Vibrance intelligently boosts the saturation of pixels
  so pixels that had little color get a larger boost than pixels that had a lot.

  This avoids oversaturation of pixels that were already very saturated.
*/

float4 VibrancePass( float4 colorInput )
{
  #ifndef Vibrance_RGB_balance //for backwards compatibility with setting presets for older version.
    #define Vibrance_RGB_balance float3(1.00, 1.00, 1.00)
  #endif
  
  #define Vibrance_coeff float3(Vibrance_RGB_balance * Vibrance)

	float4 color = colorInput; //original input color
  float3 lumCoeff = float3(0.212656, 0.715158, 0.072186);  //Values to calculate luma with

	float luma = dot(lumCoeff, color.rgb); //calculate luma (grey)


	float max_color = max(colorInput.r, max(colorInput.g,colorInput.b)); //Find the strongest color
	float min_color = min(colorInput.r, min(colorInput.g,colorInput.b)); //Find the weakest color

	float color_saturation = max_color - min_color; //The difference between the two is the saturation

/*
	float3 sort = colorInput.rgb;
	float2 sort1 = (sort.r > sort.g) ? sort.gr : sort.rg;
	float2 sort2 = (sort.g > sort.b) ? sort.bg : sort.gb;

	sort.gb = (sort1.g > sort2.g) ? float2(sort2.g,sort1.g) : float2(sort1.g,sort2.g); //max is now stored in .b
	sort.r = (sort1.r < sort2.r) ? sort1.r : sort2.r; //sorted : min is .r , med is .g and max is .b
	
	float color_saturation = sort.b - sort.r; //The difference between the two is the saturation
*/

/*	
	float3 sort = colorInput.rgb;
	sort.rg = (sort.r > sort.g) ? sort.gr : sort.rg;
	sort.gb = (sort.g > sort.b) ? sort.bg : sort.gb; //max is now stored in .b
	sort.rg = (sort.r > sort.g) ? sort.gr : sort.rg; //sorted : min is .r , med is .g and max is .b
	
	float color_saturation = sort.b - sort.r; //The difference between the two is the saturation
*/


/*
	float4 sort = colorInput;
	sort.rg = (sort.r > sort.g) ? sort.gr : sort.rg;
	sort.gb = (sort.g > sort.b) ? sort.bg : sort.gb; //max is now stored in .b
	
	float color_saturation = sort.b - min(sort.r,sort.g); //The difference between the two is the saturation
*/

  //color.rgb = lerp(luma, color.rgb, (1.0 + (Vibrance * (1.0 - color_saturation)))); //extrapolate between luma and original by 1 + (1-saturation) - simple

  //color.rgb = lerp(luma, color.rgb, (1.0 + (Vibrance * (1.0 - (sign(Vibrance) * color_saturation))))); //extrapolate between luma and original by 1 + (1-saturation) - current
  color.rgb = lerp(luma, color.rgb, (1.0 + (Vibrance_coeff * (1.0 - (sign(Vibrance_coeff) * color_saturation))))); //extrapolate between luma and original by 1 + (1-saturation) - current

  //color.rgb = lerp(luma, color.rgb, 1.0 + (1.0-pow(color_saturation, 1.0 - (1.0-Vibrance))) ); //pow version

	return color; //return the result
	//return color_saturation.xxxx; //Visualize the saturation
}