   /*-----------------------------------------------------------.   
  /                          Levels                             /
  '------------------------------------------------------------/

by Christian Cann Schuldt Jensen ~ CeeJay.dk

Allows you to set a new black and a white level.
This increases contrast, but clips any colors outside the new range to either black or white
and so some details in the shadows or highlights can be lost.

The shader is very useful for expanding the 16-235 TV range to 0-255 PC range.
You might need it if you're playing a game meant to display on a TV with an emulator that does not do this.
But it's also a quick and easy way to uniformly increase the contrast of an image.

-- Version 1.0 --
First release
-- Version 1.1 --
Optimized to only use 1 instruction (down from 2 - a 100% performance increase :) )
-- Version 1.2 --
Added the ability to highlight clipping regions of the image with #define Levels_highlight_clipping 1

*/

#define black_point_float ( Levels_black_point / 255.0 )

#if (Levels_white_point == Levels_black_point) //avoid division by zero if the white and black point are the same
  #define white_point_float ( 255.0 / 0.00025)
#else
  #define white_point_float ( 255.0 / (Levels_white_point - Levels_black_point))
#endif

float4 LevelsPass( float4 colorInput )
{
  colorInput.rgb = colorInput.rgb * white_point_float - (black_point_float *  white_point_float);

  #if (Levels_highlight_clipping == 1)

    float3 clipped_colors = any(colorInput.rgb > saturate(colorInput.rgb)) //any colors whiter than white?
                    ? float3(1.0, 0.0, 0.0)
                    : colorInput.rgb;
                    
    clipped_colors = all(colorInput.rgb > saturate(colorInput.rgb)) //all colors whiter than white?
                    ? float3(1.0, 1.0, 0.0)
                    : clipped_colors;
                    
    clipped_colors = any(colorInput.rgb < saturate(colorInput.rgb)) //any colors blacker than black?
                    ? float3(0.0, 0.0, 1.0)
                    : clipped_colors;
                    
    clipped_colors = all(colorInput.rgb < saturate(colorInput.rgb)) //all colors blacker than black?
                    ? float3(0.0, 1.0, 1.0)
                    : clipped_colors;                    
                    
    colorInput.rgb = clipped_colors;
    
  #endif

  return colorInput;
}