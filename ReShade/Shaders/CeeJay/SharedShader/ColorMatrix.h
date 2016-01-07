   /*-----------------------------------------------------------.
  /                          ColorMatrix                        /
  '-----------------------------------------------------------*/
/*
ColorMatrix allow the user to transform the colors using a color matrix

Version 1.0 by CeeJay.dk
- Initial version
*/

static const float3x3 ColorMatrix = float3x3( ColorMatrix_Red , ColorMatrix_Green , ColorMatrix_Blue );

float4 ColorMatrixPass(float4 colorInput)
{
  float3 color = mul(ColorMatrix, colorInput.rgb);
  
  colorInput.rgb = lerp(colorInput.rgb, color, ColorMatrix_strength); //Adjust the strength of the effect

  return saturate(colorInput);
}