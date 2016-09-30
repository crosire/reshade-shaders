
//Surface Blur by Ioxa
//Version 1.0 for ReShade 3.0
//Based on the  filter by mrharicot at https://www.shadertoy.com/view/4dfGDH

//Settings
#if !defined SurfaceBlurIterations
	#define SurfaceBlurIterations 1
#endif

uniform int BlurRadius
<
	ui_type = "drag";
	ui_min = 1; ui_max = 3;
	ui_tooltip = "1 = 3x3 mask, 2 = 5x5 mask, 3 = 7x7 mask.";
> = 1;

uniform float BlurOffset
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Additional adjustment for the blur radius. Values less than 1.00 will reduce the blur radius.";
> = 1.000;

uniform float BlurEdge
<
	ui_type = "drag";
	ui_min = 0.000; ui_max = 10.000;
	ui_tooltip = "Adjusts the strength of edge detection. Lowwer values will exclude finer edges from blurring";
> = 0.500;

uniform float BlurStrength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of the effect";
> = 1.00;

#include "ReShade.fxh"

#if SurfaceBlurIterations >= 2
	texture BlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	sampler BlurSampler { Texture = BlurTex;};
#endif

#if SurfaceBlurIterations >= 3
	texture BlurTex2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	sampler BlurSampler2 { Texture = BlurTex2;};
#endif

float normpdfE(in float3 x, in float y)
{
	float v = dot(x,x);
	return saturate(1/pow(1+(pow(v/y,2.0)),0.5));
}

float3 BlurFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	#if SurfaceBlurIterations == 2 
		#define FinalSampler BlurSampler
	#elif SurfaceBlurIterations == 3
		#define FinalSampler BlurSampler2
	#else
		#define FinalSampler ReShade::BackBuffer
	#endif
	
	float3 color = tex2D(FinalSampler, texcoord).rgb;
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	
	float3 diff = 0.0;
	float factor = 0.0;
	float Z = 0.0;
	float3 final_color = 0.0;
	float sigma = ((BlurEdge+0.00001) * 0.1);
	
	if (BlurRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color = tex2D(FinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(FinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}
	
	if (BlurRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(FinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(FinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}

	if (BlurRadius == 3)
	{
		static const float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		static const float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(FinalSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(FinalSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}	
	
	color = final_color/Z;

	orig = lerp(orig.rgb, color.rgb, BlurStrength);
	return saturate(orig);
}

#if SurfaceBlurIterations >= 2
float3 Blur1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 orig = color;
	
	float3 diff = 0.0;
	float factor = 0.0;
	float Z = 0.0;
	float3 final_color = 0.0;
	float sigma = ((BlurEdge+0.00001) * 0.1);
	
	if (BlurRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color = tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}
	
	if (BlurRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}

	if (BlurRadius == 3)
	{
		static const float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		static const float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(ReShade::BackBuffer, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(ReShade::BackBuffer, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
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

#if SurfaceBlurIterations >= 3
float3 Blur2(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(BlurSampler, texcoord).rgb;
	//float3 orig = color;
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	float3 diff = 0.0;
	float factor = 0.0;
	float Z = 0.0;
	float3 final_color = 0.0;
	float sigma = ((BlurEdge+0.00001) * 0.1);
	
	if (BlurRadius == 1)
	{
		int sampleOffsetsX[25] = {  0.0, 	 1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,      1,     2,     2,     3,     0,     3,     3,     1,    -1, 3, 3, 2, 2, 3, 3 };
		int sampleOffsetsY[25] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2,     0,     3,     1,    -1,     3,     3, 2, -2, 3, -3, 3, -3};	
		float sampleWeights[5] = { 0.225806, 0.150538, 0.150538, 0.0430108, 0.0430108 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 5; ++i) {
			color = tex2D(BlurSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BlurSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}
	
	if (BlurRadius == 2)
	{
		int sampleOffsetsX[13] = {  0.0, 	   1, 	  0, 	 1,     1,     2,     0,     2,     2,     1,    1,     2,     2 };
		int sampleOffsetsY[13] = {  0.0,     0, 	  1, 	 1,    -1,     0,     2,     1,    -1,     2,     -2,     2,    -2};
		float sampleWeights[13] = { 0.1509985387665926499, 0.1132489040749444874, 0.1132489040749444874, 0.0273989284225933369, 0.0273989284225933369, 0.0452995616018920668, 0.0452995616018920668, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0109595713409516066, 0.0043838285270187332, 0.0043838285270187332 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(BlurSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BlurSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
		}
	}

	if (BlurRadius == 3)
	{
		static const float sampleOffsetsX[13] = { 				  0.0, 			    1.3846153846, 			 			  0, 	 		  1.3846153846,     	   	 1.3846153846,     		    3.2307692308,     		  			  0,     		 3.2307692308,     		   3.2307692308,     		 1.3846153846,    		   1.3846153846,     		  3.2307692308,     		  3.2307692308 };
		static const float sampleOffsetsY[13] = {  				  0.0,   					   0, 	  		   1.3846153846, 	 		  1.3846153846,     		-1.3846153846,     					   0,     		   3.2307692308,     		 1.3846153846,    		  -1.3846153846,     		 3.2307692308,   		  -3.2307692308,     		  3.2307692308,    		     -3.2307692308 };
		float sampleWeights[13] = { 0.0957733978977875942, 0.1333986613666725565, 0.1333986613666725565, 0.0421828199486419528, 0.0421828199486419528, 0.0296441469844336464, 0.0296441469844336464, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0093739599979617454, 0.0020831022264565991,  0.0020831022264565991 };
		
		color *= sampleWeights[0];
		
		[loop]
		for(int i = 1; i < 13; ++i) {
			color = tex2D(BlurSampler, texcoord + float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
			diff = ((orig)-color);
			factor = normpdfE(diff,sigma)*sampleWeights[i];
			Z += factor;
			final_color += factor*color;
			
			color = tex2D(BlurSampler, texcoord - float2(sampleOffsetsX[i] * ReShade::PixelSize.x, sampleOffsetsY[i] * ReShade::PixelSize.y) * BlurOffset).rgb;
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

technique SurfaceBlur
{
#if SurfaceBlurIterations >= 2
	pass Blur1
	{
		VertexShader = PostProcessVS;
		PixelShader = Blur1;
		RenderTarget = BlurTex;
	}
#endif 

#if SurfaceBlurIterations >= 3
	pass Blur2
	{
		VertexShader = PostProcessVS;
		PixelShader = Blur2;
		RenderTarget = BlurTex2;
	}
#endif
	
	pass BlurFinal
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurFinal;
	}

}
