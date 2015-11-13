   /*-----------------------------------------------------------.   
  /                        TECHICOLOR                           /
  '-----------------------------------------------------------*/
// Original by DKT70
// Optimized by CeeJay.dk
// - Version 1.1

#define cyanfilter float3(0.0, 1.30, 1.0)
#define magentafilter float3(1.0, 0.0, 1.05) 
#define yellowfilter float3(1.6, 1.6, 0.05)

#define redorangefilter float2(1.05, 0.620) //RG_
#define greenfilter float2(0.30, 1.0)       //RG_
#define magentafilter2 magentafilter.rb     //R_B

float4 TechnicolorPass( float4 colorInput )
{
	float3 tcol = colorInput.rgb;
	
  float2 rednegative_mul   = tcol.rg * (1.0 / (redNegativeAmount * TechniPower));
	float2 greennegative_mul = tcol.rg * (1.0 / (greenNegativeAmount * TechniPower));
	float2 bluenegative_mul  = tcol.rb * (1.0 / (blueNegativeAmount * TechniPower));
	
  float rednegative   = dot( redorangefilter, rednegative_mul );
	float greennegative = dot( greenfilter, greennegative_mul );
	float bluenegative  = dot( magentafilter2, bluenegative_mul );
	
	float3 redoutput   = rednegative.rrr + cyanfilter;
	float3 greenoutput = greennegative.rrr + magentafilter;
	float3 blueoutput  = bluenegative.rrr + yellowfilter;
	
	float3 result = redoutput * greenoutput * blueoutput;
	colorInput.rgb = lerp(tcol, result, TechniAmount);
	return colorInput;
}