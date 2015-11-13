/*------------------------------------------------------------------------------
						BLOOM
------------------------------------------------------------------------------*/

float4 BloomPass( float4 ColorInput2,float2 Tex  )
{
	float3 BlurColor2 = 0;
	float3 Blurtemp = 0;
	//float MaxDistance = sqrt(8*BloomWidth);
	float MaxDistance = 8*BloomWidth; //removed sqrt
	float CurDistance = 0;
	
	//float Samplecount = 0;
	float Samplecount = 25.0;
	
	float2 blurtempvalue = Tex * pixel * BloomWidth;
	
	//float distancetemp = 1.0 - ((MaxDistance - CurDistance) / MaxDistance);
	
	float2 BloomSample = float2(2.5,-2.5);
	float2 BloomSampleValue;// = BloomSample;
	
	for(BloomSample.x = (2.5); BloomSample.x > -2.0; BloomSample.x = BloomSample.x - 1.0) // runs 5 times
	{
        BloomSampleValue.x = BloomSample.x * blurtempvalue.x;
        float2 distancetemp = BloomSample.x * BloomSample.x * BloomWidth;
        
		for(BloomSample.y = (- 2.5); BloomSample.y < 2.0; BloomSample.y = BloomSample.y + 1.0) // runs 5 ( * 5) times
		{
            distancetemp.y = BloomSample.y * BloomSample.y;
			//CurDistance = sqrt(dot(BloomSample,BloomSample)*BloomWidth); //dot() attempt - same result , same speed. //move x part up ?
			//CurDistance = sqrt( (distancetemp.y * BloomWidth) + distancetemp.x); //dot() attempt - same result , same speed. //move x part up ?
			CurDistance = (distancetemp.y * BloomWidth) + distancetemp.x; //removed sqrt
			
			//Blurtemp.rgb = myTex2D(s0, float2(Tex + (BloomSample*blurtempvalue))); //same result - same speed.
			BloomSampleValue.y = BloomSample.y * blurtempvalue.y;
			Blurtemp.rgb = myTex2D(s0, float2(Tex + BloomSampleValue)).rgb; //same result - same speed.
			
			//BlurColor2.rgb += lerp(Blurtemp.rgb,ColorInput2.rgb, 1 - ((MaxDistance - CurDistance)/MaxDistance)); //convert float4 to float3 and check if it's possible to use a MAD
			//BlurColor2.rgb += lerp(Blurtemp.rgb,ColorInput2.rgb, 1.0 - ((MaxDistance - CurDistance) / MaxDistance)); //convert float4 to float3 and check if it's possible to use a MAD
			BlurColor2.rgb += lerp(Blurtemp.rgb,ColorInput2.rgb, sqrt(CurDistance / MaxDistance)); //reduced number of sqrts needed

			
			//Samplecount = Samplecount + 1; //take out of loop and replace with constant if it helps (check with compiler)
		}
	}
	BlurColor2.rgb = (BlurColor2.rgb / (Samplecount - (BloomPower - BloomThreshold*5))); //check if using MAD
	float Bloomamount = (dot(ColorInput2.rgb,float3(0.299f, 0.587f, 0.114f))) ; //try BT 709
	float3 BlurColor = BlurColor2.rgb * (BloomPower + 4.0); //check if calculated offline and combine with line 24 (the blurcolor2 calculation)

	ColorInput2.rgb = lerp(ColorInput2.rgb,BlurColor.rgb, Bloomamount);	

	return saturate(ColorInput2);
}


float3 BloomWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
  float4 color = myTex2D(s0, texcoord);
  
	color = BloomPass(color,texcoord);

	#ifdef Shared_Piggyback_Bloom
    color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
	#endif
	
	return color.rgb;
}