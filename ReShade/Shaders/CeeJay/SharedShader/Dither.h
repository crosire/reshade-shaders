  /*-------------.
  | :: Dither :: |
  '-------------*/
/*
  Dither version 1.3.1
  by Christian Cann Schuldt Jensen ~ CeeJay.dk

  Does dithering of the greater than 8-bit per channel precision used in shaders.
  Note that the input from the framebuffer is 8-bit and cannot be dithered down to 8-bit.
  Dithering therefore only works on the effects that SweetFX applies afterwards.
*/

#ifndef dither_method
  #define dither_method 1
#endif

float4 DitherPass( float4 colorInput, float2 tex )
{
   float3 color = colorInput.rgb;

   float dither_bit  = 8.0;  //Number of bits per channel. Should be 8 for most monitors.
   
   //color = (tex.x*0.5)+0.50; //draw a gradient for testing.
   //#define dither_method 4 //override method for testing purposes

  /*------------------------.
  | :: Ordered Dithering :: |
  '------------------------*/
/* 
 #if dither_method == 1 // Ordered dithering
     //Calculate grid position
     float grid_position = frac( dot(tex, (RFX_ScreenSize * float2(1.0/16.0,10.0/36.0)  )+(0.25) ) );

     //Calculate how big the shift should be
     float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0));

     //Shift the individual colors differently, thus making it even harder to see the dithering pattern
     float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

     //modify shift acording to grid position.
     dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

     //shift the color by dither_shift
     color.rgb += dither_shift_RGB;
*/

   #if dither_method == 1 // Ordered dithering
     //Calculate grid position
     float grid_position = frac( dot(tex,(RFX_ScreenSize * float2(1.0/16.0,10.0/36.0))) + 0.25 );

     //Calculate how big the shift should be
     float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0));

     //Shift the individual colors differently, thus making it even harder to see the dithering pattern
     float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

     //modify shift acording to grid position.
     dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

     //shift the color by dither_shift
     color.rgb += dither_shift_RGB;

  /*-----------------------.
  | :: Random Dithering :: |
  '-----------------------*/
   #elif dither_method == 2 //Random dithering

     //Pseudo Random Number Generator
     // -- PRNG 1 - Reference --
     float seed = dot(tex, float2(12.9898,78.233)); //I could add more salt here if I wanted to
     float sine = sin(seed); //cos also works well. Sincos too if you want 2D noise.
     float noise = frac(sine * 43758.5453 + tex.x); //tex.x is just some additional salt - it can be taken out.

     //Calculate how big the shift should be
     float dither_shift = (1.0 / (pow(2,dither_bit) - 1.0)); // Using noise to determine shift. Will be 1/255 if set to 8-bit.
     float dither_shift_half = (dither_shift * 0.5); // The noise should vary between +- 0.5
     dither_shift = dither_shift * noise - dither_shift_half; // MAD

     //shift the color by dither_shift
     color.rgb += float3(-dither_shift, dither_shift, -dither_shift); //subpixel dithering

  /*--------------------.
  | :: New Dithering :: |
  '--------------------*/
  //#define dither_method 3
   #elif dither_method == 3 // New Ordered dithering

     //Calculate grid position
     float grid_position = frac(dot(tex,(RFX_ScreenSize) * float2(0.75,0.5) /*+ (0.00025)*/)); //(0.6,0.8) is good too - TODO : experiment with values

     //Calculate how big the shift should be
     float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0)); // 0.25 seems good both when using math and when eyeballing it. So does 0.75 btw.
     dither_shift = lerp(2.0 * dither_shift, -2.0 * dither_shift, grid_position); //shift acording to grid position.

     //shift the color by dither_shift
     color.rgb += float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

  /*-------------------------.
  | :: A Dither Dithering :: |
  '-------------------------*/
  //#define dither_method 4
  #elif dither_method == 4 // New Ordered dithering

  #define dither_pattern 11
  #define dither_levels 32

  float x=tex.x * RFX_ScreenSize.x;// * 1.31;
  float y=tex.y * RFX_ScreenSize.y;// * 1.31;

  //Calculate grid position
  float c = frac(dot(tex,(RFX_ScreenSize) * float2(1.0/4.0,3.0/4.0) + (0.00025) )); //the + (0.00025) part is to avoid errors with the floating point math

  float mask;

  #if dither_pattern == 1
    mask = ((x ^ y * 149) * 1234 & 511)/511.0; //requires bitwise XOR - doesn't work
  #elif dither_pattern == 2
    mask = (((x+c*17) ^ y * 149) * 1234 & 511)/511.0; //requires bitwise XOR - doesn't work
  #elif dither_pattern == 3
    mask = 256.0 * frac(((x + y * 237) * 119)/ 256.0 ) / 255.0 ;//1.00392 * frac(0.464844 * (x + 237.0 * y)); //256.0 * frac(((x + y * 237) * 119)/ 256.0 ) / 255.0
  #elif dither_pattern == 4
    mask = (256.0 * frac((((x+c*67.0) + y * 236.0) * 119.0) / 256.0)) / 255.0; //& 255 = 256 * frac(x / 256)
  #elif dither_pattern == 5
    mask = 0.5;
  #elif dither_pattern == 6
    mask = frac( dot(tex, float2(12.9898,78.233)) * 927.5453 );
  #elif dither_pattern == 7
    mask = frac( dot(tex, (RFX_ScreenSize * float2(1.0/7.0,9.0/17.0))+(0.00025) ) );
  #elif dither_pattern == 8
    mask = frac( dot(tex, (RFX_ScreenSize * float2(5.0/7.0,3.0/17.0))+(0.00025) ) );
  #elif dither_pattern == 9
    mask = frac( dot(tex, (RFX_ScreenSize * float2(1.0/4.0,3.0/5.0))+(0.000025) ) );
  #elif dither_pattern == 10
    mask = frac( dot(tex, (RFX_ScreenSize * float2(1.0/87.0,1.0/289.0))+(0.000025) ) ); //stylish pattern - but bad for dithering
  #elif dither_pattern == 11
    //mask = frac( dot(tex, (RFX_ScreenSize * float2(1.0/(floor(tex.y*10.0)/100.+16.0),87.0/289.0))+(0.000025) ) ); //
	//mask = frac( dot(float4(tex,tex), float4((RFX_ScreenSize * float2(0.666/16.0,6.66/36.)),(RFX_ScreenSize * float2(0.3344/16.0,3.34/36.)) ) ) ); //
      mask = frac( dot(tex, (RFX_ScreenSize * float2(1.0/16.0,10.0/36.0)  )+(0.25) ) ); //
//(floor(tex.y*10.0)/100.0 + 3.0)
  #else
    //return input;
  #endif

  color.rgb = floor(dither_levels * color.rgb + mask) / dither_levels;
  color.rgb = mask.xxx;

  /*---------------------------------------.
  | :: New Dithering - grid experiments :: |
  '---------------------------------------*/
  //#define dither_method 5
   #elif dither_method == 5 // New Ordered dithering

     //Calculate grid position
     float grid_position = frac(dot(tex,floor(RFX_ScreenSize * float2(-0.5,-0.9) ) /*- (0.00025)*/ )); //(0.6,0.8) is good too - TODO : experiment with values

     //Calculate grid position
     grid_position = frac(dot(tex,floor(RFX_ScreenSize * float2(0.4,0.70)) /*+ grid_position*/ /*+ (0.00025)*/ )); //

     //Calculate how big the shift should be
     float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0)); // 0.25 seems good both when using math and when eyeballing it. So does 0.75 btw.
     dither_shift = lerp(2.0 * dither_shift, -2.0 * dither_shift, grid_position); //shift acording to grid position.

     //dither_shift = (2.0 * dither_shift) * grid_position + (2.0 * dither_shift) * grid_position;
     //dither_shift = 4.0 * dither_shift * grid_position;

     //shift the color by dither_shift
     //color.rgb += lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

     color.rgb += float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

  /*-------------------.
  | :: Checkerboard :: |
  '-------------------*/
   #elif dither_method == 6 // Checkerboard Ordered dithering
     //Calculate grid position
     float grid_position = frac(dot(tex, RFX_ScreenSize * 0.5) + 0.25); //returns 0.25 and 0.75

     //Calculate how big the shift should be
     float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0)); // 0.25 seems good both when using math and when eyeballing it. So does 0.75 btw.

     //Shift the individual colors differently, thus making it even harder to see the dithering pattern
     float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

     //modify shift acording to grid position.
     dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

     //shift the color by dither_shift
     //color.rgb += lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.
     color.rgb += dither_shift_RGB;

   #endif

  /*-------------------------.
  | :: Debugging features :: |
  '-------------------------*/
   //color.rgb = (dither_shift_RGB * 2.0 * (pow(2,dither_bit) - 1.0) ) + 0.5; //visualize the RGB shift
   //color.rgb = grid_position; //visualize the grid
   //color.rgb = noise; //visualize the noise
   //color.rgb = c;

  /*---------------------------.
  | :: Returning the output :: |
  '---------------------------*/

   //color = (tex.x / 2.0); //draw a undithered gradient for testing.
   
   //#define dither_levels 32
   //color.rgb = floor(dither_levels * (color.rgb + dither_shift_RGB)) / dither_levels;
   
   //color.rgb = floor( color.rgb * 255.0 ) / (255.0 / 16.0);

   colorInput.rgb = color.rgb;

   return colorInput;
}