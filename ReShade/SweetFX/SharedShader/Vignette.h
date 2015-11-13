   /*-----------------------------------------------------------.
  /                          Vignette                           /
  '-----------------------------------------------------------*/
/*
  Version 1.3

  Darkens the edges of the image to make it look more like it was shot with a camera lens.
  May cause banding artifacts.
*/

//Make sure the VignetteRatio exits to avoid breaking if the user uses a Settings for a previous version that didn't include this
#ifndef VignetteRatio
  #define VignetteRatio 1.0
#endif

#ifndef VignetteType
  #define VignetteType 1
#endif

/*
//Logical XOR - not used right now but it might be useful at a later time
float XOR( float xor_A, float xor_B )
{
  return saturate( dot(float4(-xor_A ,-xor_A ,xor_A , xor_B) , float4(xor_B, xor_B ,1.0 ,1.0 ) ) ); // -2 * A * B + A + B
}
*/

float4 VignettePass( float4 colorInput, float2 tex )
{

	#if VignetteType == 1
		//Set the center
		float2 distance_xy = tex - VignetteCenter;

		//Adjust the ratio
		distance_xy *= float2((RFX_PixelSize.y / RFX_PixelSize.x),VignetteRatio);

		//Calculate the distance
		distance_xy /= VignetteRadius;
		float distance = dot(distance_xy,distance_xy);

		//Apply the vignette
		colorInput.rgb *= (1.0 + pow(distance, VignetteSlope * 0.5) * VignetteAmount); //pow - multiply
	#endif

	#if VignetteType == 2 // New round (-x*x+x) + (-y*y+y) method.
    
        tex = -tex * tex + tex;
		colorInput.rgb = saturate(( (RFX_PixelSize.y / RFX_PixelSize.x)*(RFX_PixelSize.y / RFX_PixelSize.x) * VignetteRatio * tex.x + tex.y) * 4.0) * colorInput.rgb;
  #endif

	#if VignetteType == 3 // New (-x*x+x) * (-y*y+y) TV style method.

        tex = -tex * tex + tex;
		colorInput.rgb = saturate(tex.x * tex.y * 100.0) * colorInput.rgb;
	#endif
		
	#if VignetteType == 4
		tex = abs(tex - 0.5);
		//tex = abs(0.5 - tex); //same result
		float tc = dot(float4(-tex.x ,-tex.x ,tex.x , tex.y) , float4(tex.y, tex.y ,1.0 ,1.0 ) ); //XOR

		tc = saturate(tc -0.495);
		colorInput.rgb *= (pow((1.0 - tc * 200),4)+0.25); //or maybe abs(tc*100-1) (-(tc*100)-1)
  #endif
  
  #if VignetteType == 5
		tex = abs(tex - 0.5);
		//tex = abs(0.5 - tex); //same result
		float tc = dot(float4(-tex.x ,-tex.x ,tex.x , tex.y) , float4(tex.y, tex.y ,1.0 ,1.0 ) ); //XOR

		tc = saturate(tc -0.495)-0.0002;
		colorInput.rgb *= (pow((1.0 - tc * 200),4)+0.0); //or maybe abs(tc*100-1) (-(tc*100)-1)
  #endif

  #if VignetteType == 6 //MAD version of 2
		tex = abs(tex - 0.5);
		//tex = abs(0.5 - tex); //same result
		float tc = tex.x * (-2.0 * tex.y + 1.0) + tex.y; //XOR

		tc = saturate(tc -0.495);
		colorInput.rgb *= (pow((-tc * 200 + 1.0),4)+0.25); //or maybe abs(tc*100-1) (-(tc*100)-1)
		//colorInput.rgb *= (pow(((tc*200.0)-1.0),4)); //or maybe abs(tc*100-1) (-(tc*100)-1)
  #endif

  #if VignetteType == 7 // New round (-x*x+x) * (-y*y+y) method.
    
	    //tex.y /= float2((RFX_PixelSize.y / RFX_PixelSize.x),VignetteRatio);
        float tex_xy = dot( float4(tex,tex) , float4(-tex,1.0,1.0) ); //dot is actually slower
		colorInput.rgb = saturate(tex_xy * 4.0) * colorInput.rgb;
	#endif

	return colorInput;
}