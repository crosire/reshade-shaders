  /*-----------------------------------------------------------.
 /                          Palette                           /
'-----------------------------------------------------------*/

/*
Version 0.1 by CeeJay.dk
- 

I need to try different color difference algorithms.
Right now im doing euclidian distance to the RGB values,
but I think it might be better if I tried HSL, HSV , YUV or CIE (most likely CIE)

Then later i'm adding dithering.

After that works I can add more palettes.
*/

float4 Nostalgia( float4 colorInput)
{
  float3 color = colorInput.rgb;

  #if 1  
    float3 palette[16]; //Palette from http://www.c64-wiki.com/index.php/Color
    palette[0] =  float3(  0. ,   0. ,   0. ); //Black
    palette[1] =  float3(255. , 255. , 255. ); //White
    palette[2] =  float3(136. ,   0. ,   0. ); //Red
    palette[3] =  float3(170. , 255. , 238. ); //Cyan
    palette[4] =  float3(204. ,  68. , 204. ); //Violet
    palette[5] =  float3(  0. , 204. ,  85. ); //Green
    palette[6] =  float3(  0. ,   0. , 170. ); //Blue
    palette[7] =  float3(238. , 238. , 119. ); //Yellow
    palette[8] =  float3(221. , 136. ,  85. ); //Orange
    palette[9] =  float3(102. ,  68. ,   0. ); //Brown
    palette[10] = float3(255. , 119. , 119. ); //Yellow
    palette[11] = float3( 51. ,  51. ,  51. ); //Grey 1
    palette[12] = float3(119. , 119. , 119. ); //Grey 2
    palette[13] = float3(170. , 255. , 102. ); //Lightgreen
    palette[14] = float3(  0. , 136. , 255. ); //Lightblue
    palette[15] = float3(187. , 187. , 187. ); //Grey 3
  #endif
  
  #if 0
    float3 palette[16];
    palette[0] =  float3(  0. ,   0. ,   0. ); //Black
    palette[1] =  float3( 62. ,  49. , 162. );
    palette[2] =  float3( 87. ,  66. ,   0. );
    palette[3] =  float3(140. ,  62. ,  52. );
    palette[4] =  float3( 84. ,  84. ,  84. ); //Grey
    palette[5] =  float3(141. ,  71. , 179. );
    palette[6] =  float3(144. ,  95. ,  37. );
    palette[7] =  float3(124. , 112. , 218. );
    palette[8] =  float3(128. , 128. , 129. ); //Grey
    palette[9] =  float3(104. , 169. ,  65. );
    palette[10] = float3(187. , 119. , 109. );
    palette[11] = float3(122. , 191. , 199. );
    palette[12] = float3(171. , 171. , 171. ); //Grey
    palette[13] = float3(208. , 220. , 113. );
    palette[14] = float3(172. , 234. , 136. ); 
    palette[15] = float3(255. , 255. , 255. ); //White
  #endif
  
  float3 diff = color; //difference to float3(0.0,0.0,0.0)
  
  /*  
  float3 square_diff = diff * diff;
  float3 distance_coefs = float3((0.5 * diff.r + 2.0), 4.0, (-0.5 * diff.r + 3.0));

  //float dist = 0.28 * sqrt( dot(square_diff,distance_coefs) );
  float dist = dot(square_diff,distance_coefs);
  */  
  float dist = dot(diff,diff); //squared distance

  float closest_dist = dist;
  float3 closest_color = float3(0.0,0.0,0.0);

  for (int i = 1 ; i <= 15 ; i++) 
    {
    diff = color - (palette[i]/255.0); //difference
    
    /*
    square_diff = diff * diff;
    distance_coefs = float3((0.5 * diff.r + 2.0), 4.0, (-0.5 * diff.r + 3.0));

    //dist = 0.28 * sqrt( dot(square_diff,distance_coefs) );
    dist = dot(square_diff,distance_coefs);
    */
    dist = dot(diff,diff); //squared distance
    
    if (dist < closest_dist) //ternary would also work here
      {
      closest_dist = dist;
      closest_color = palette[i]/255.0;
      }
      
    }

  colorInput.rgb = closest_color; //return the pixel
  return colorInput; //return the pixel
}

/*
      float3 colortarget = float3(0.,255.,0.)/255.0;
      float3 diff = col - colortarget;
      
      float3 square_diff = diff * diff;
      float3 distance_coefs = float3((0.5 * diff.r + 2.0), 4.0, (-0.5 * diff.r + 3.0));

      float colordistance = 0.28 * sqrt( dot(square_diff,distance_coefs) );
    	
    	col = (colordistance > 0.35 ) ? col : float3(0.0); 
    	float luma = dot(col,float3(0.2126, 0.7152, 0.0722));
    	
*/
