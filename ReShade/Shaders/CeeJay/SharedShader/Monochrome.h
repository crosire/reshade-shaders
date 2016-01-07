   /*-----------------------------------------------------------.   
  /                          Monochrome                         /
  '-----------------------------------------------------------*/
/*
  by Christian Cann Schuldt Jensen ~ CeeJay.dk
  
  Monochrome removes color and makes everything black and white.
*/



#ifndef Monochrome_color_saturation
  #define Monochrome_color_saturation 0.00
#endif

float4 MonochromePass( float4 colorInput )
{
  //calculate monochrome
  float3 grey = dot(Monochrome_conversion_values, colorInput.rgb);
	
  //Add back some of the color?
  colorInput.rgb = lerp(grey, colorInput.rgb, Monochrome_color_saturation); //Adjust the remaining saturation.
	
  //Return the result
  return saturate(colorInput);
}