
//Bilateral Blur by Ioxa
//Version 1.0 for ReShade 3.0
//Based on the Bilateral filter by mrharicot at https://www.shadertoy.com/view/4dfGDH

//Settings
#if !defined BilateralIterations
	#define BilateralIterations 1
#endif

uniform int BilateralBlurRadius
<
	ui_type = "drag";
	ui_min = 1; ui_max = 3;
	ui_tooltip = "1 = 3x3 mask, 2 = 5x5 mask, 3 = 7x7 mask.";
> = 1;

uniform float BilateralBlurOffset
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Additional adjustment for the blur radius. Values less than 1.00 will reduce the blur radius.";
> = 1.000;

uniform float BilateralBlurEdge
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 10.000;
	ui_tooltip = "Adjusts the strength of edge detection. Lowwer values will exclude finer edges from blurring";
> = 0.500;

uniform float BilateralBlurStrength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of the effect";
> = 1.00;

#include "ReShade.fxh"

#if BilateralIterations >= 2
	texture BilateralBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	sampler BilateralBlurSampler { Texture = BilateralBlurTex;};
#endif

#if BilateralIterations >= 3
	texture BilateralBlurTex2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	sampler BilateralBlurSampler2 { Texture = BilateralBlurTex2;};
#endif

float normpdfE(in float3 x, in float y)
{
	float v = dot(x,x);
	return saturate(1/pow(1+(pow(v/y,2.0)),0.5));
}

float3 BilateralBlurFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	#if BilateralIterations == 2 
		#define BilateralFinalSampler BilateralBlurSampler
	#elif BilateralIterations == 3
		#define BilateralFinalSampler BilateralBlurSampler2
	#else
		#define BilateralFinalSampler ReShade::BackBuffer
	#endif
	
	float3 color = tex2D(BilateralFinalSampler, texcoord).rgb;
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	
	float3 diff = 0.0;
	float factor = 0.0;
	float Z = 0.0;
	float3 final_color = 0.0;
	float sigma = ((BilateralBlurEdge+0.00001) * 0.1);
	
	if (BilateralBlurRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color = tex2D(BilateralFinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BilateralFinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}
	
	if (BilateralBlurRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(BilateralFinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BilateralFinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}

	if (BilateralBlurRadius == 3)
	{
		static const float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		static const float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(BilateralFinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BilateralFinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}	
	
	color = final_color/Z;

	orig = lerp(orig.rgb, color.rgb, BilateralBlurStrength);
	return saturate(orig);
}

#if BilateralIterations >= 2
float3 BilateralBlur1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 orig = color;
	
	float3 diff = 0.0;
	float factor = 0.0;
	float Z = 0.0;
	float3 final_color = 0.0;
	float sigma = ((BilateralBlurEdge+0.00001) * 0.1);
	
	if (BilateralBlurRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color = tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}
	
	if (BilateralBlurRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}

	if (BilateralBlurRadius == 3)
	{
		static const float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		static const float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}	
	
	color = final_color/Z;
	
	return saturate(color);
}
#endif

#if BilateralIterations >= 3
float3 BilateralBlur2(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(BilateralBlurSampler, texcoord).rgb;
	//float3 orig = color;
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	float3 diff = 0.0;
	float factor = 0.0;
	float Z = 0.0;
	float3 final_color = 0.0;
	float sigma = ((BilateralBlurEdge+0.00001) * 0.1);
	
	if (BilateralBlurRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color = tex2D(BilateralBlurSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BilateralBlurSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}
	
	if (BilateralBlurRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(BilateralBlurSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BilateralBlurSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}

	if (BilateralBlurRadius == 3)
	{
		static const float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		static const float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(BilateralBlurSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BilateralBlurSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BilateralBlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}	
	
	color = final_color/Z;
	
	return saturate(color);
}
#endif

technique BilateralBlur
{
#if BilateralIterations >= 2
	pass Blur1
	{
		VertexShader = PostProcessVS;
		PixelShader = BilateralBlur1;
		RenderTarget = BilateralBlurTex;
	}
#endif 

#if BilateralIterations >= 3
	pass Blur2
	{
		VertexShader = PostProcessVS;
		PixelShader = BilateralBlur2;
		RenderTarget = BilateralBlurTex2;
	}
#endif
	
	pass BlurFinal
	{
		VertexShader = PostProcessVS;
		PixelShader = BilateralBlurFinal;
	}

}
