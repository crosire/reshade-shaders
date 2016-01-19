  /*-----------------------------------------------------------.
 /                          Border                            /
'-----------------------------------------------------------*/

/*
Version 1.0 by Oomek
- Fixes light, one ReShade::PixelSize thick border in some games when forcing MSAA like i.e. Dishonored

Version 1.1 by CeeJay.dk
- Optimized the shader. It still does the same but now it runs faster.

Version 1.2 by CeeJay.dk
- Added border_width and border_color features

Version 1.3 by CeeJay.dk
- Optimized the performance further

Version 1.4 by CeeJay.dk
- Added the border_ratio feature
*/


#ifndef border_width
  #define border_width float2(1.0,0.0)
#endif

#ifndef border_color
  #define border_color float3(0.0, 0.0, 0.0)
#endif

#define screen_ratio (ReShade::ScreenSize.x / ReShade::ScreenSize.y)

float4 BorderPass( float4 colorInput, float2 tex )
{
  float3 border_color_float = border_color / 255.0;

  float2 border_width_variable = border_width;

  // -- calculate the right border_width for a given border_ratio --
  //if (!any(border_width)) //if border_width is not used
  if (border_width.x == -border_width.y) //if border_width is not used
    if (screen_ratio < border_ratio)
      border_width_variable = float2(0.0, (ReShade::ScreenSize.y - (ReShade::ScreenSize.x / border_ratio)) * 0.5);
    else
      border_width_variable = float2((ReShade::ScreenSize.x - (ReShade::ScreenSize.y * border_ratio)) * 0.5, 0.0);

  float2 border = (ReShade::PixelSize * border_width_variable); //Translate integer ReShade::PixelSize width to floating point

  float2 within_border = saturate((-tex * tex + tex) - (-border * border + border)); //becomes positive when inside the border and 0 when outside

  colorInput.rgb = all(within_border) ?  colorInput.rgb : border_color_float ; //if the ReShade::PixelSize is within the border use the original color, if not use the border_color
  //colorInput.rgb = (within_border.x * within_border.y) ?  colorInput.rgb : border_color_float ; //if the ReShade::PixelSize is within the border use the original color, if not use the border_color

  return colorInput; //return the ReShade::PixelSize
}