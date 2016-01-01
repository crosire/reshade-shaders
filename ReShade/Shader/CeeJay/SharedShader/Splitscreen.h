   /*-----------------------------------------------------------.   
  /                       Splitscreen                           /
  '-----------------------------------------------------------*/

float4 SplitscreenPass( float4 colorInput, float2 tex )
{
  // -- Vertical 50/50 split --
  #if splitscreen_mode == 1
	  return (tex.x < 0.5) ? myTex2D(ReShade::OriginalColor, tex) : colorInput;
  #endif

  // -- Vertical 25/50/25 split --
	#if splitscreen_mode == 2
    //Calculate the distance from center
    float distance = abs(tex.x - 0.5);
    
    //Further than 1/4 away from center?
    distance = saturate(distance - 0.25);
    
    return distance ? myTex2D(ReShade::OriginalColor, tex) : colorInput;
	#endif

  // -- Vertical 50/50 angled split --
	#if splitscreen_mode == 3
	  //Calculate the distance from center
    float distance = ((tex.x - 3.0/8.0) + (tex.y * 0.25));
    
    //Further than 1/4 away from center?
    distance = saturate(distance - 0.25);
    
    return distance ? colorInput : myTex2D(ReShade::OriginalColor, tex);
	#endif
  
  // -- Horizontal 50/50 split --
  #if splitscreen_mode == 4
	  return (tex.y < 0.5) ? myTex2D(ReShade::OriginalColor, tex) : colorInput;
  #endif
	
  // -- Horizontal 25/50/25 split --
  #if splitscreen_mode == 5
    //Calculate the distance from center
    float distance = abs(tex.y - 0.5);
    
    //Further than 1/4 away from center?
    distance = saturate(distance - 0.25);
    
    return distance ? myTex2D(ReShade::OriginalColor, tex) : colorInput;
  #endif

  // -- Vertical 50/50 curvy split --
    #if splitscreen_mode == 6
    //Calculate the distance from center
    float distance = (tex.x - 0.25) + (sin(tex.y * 10)*0.10);
    
    //Further than 1/4 away from center?
    distance = saturate(distance - 0.25);
    
    return distance ? colorInput : myTex2D(ReShade::OriginalColor, tex);
    #endif

}