/**
 * Curves
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Curves, uses S-curves to increase contrast, without clipping highlights and shadows.
 */

uniform int Curves_mode <
	ui_type = "combo";
	ui_items = "Luma\0Chroma\0Both Luma and Chroma\0";
	ui_tooltip = "Choose what to apply contrast to.";
> = 0;
uniform int Curves_formula <
	ui_type = "combo";
	ui_items = "Sine\0Abs split\0Smoothstep\0Exp formula\0Simplified Catmull-Rom (0,0,1,1)\0Perlins Smootherstep\0Abs add\0Techicolor Cinestyle\0Parabola\0Half-circles\0Polynomial split\0";
	ui_tooltip = "The contrast s-curve you want to use. Note that Technicolor Cinestyle is practically identical to Sine, but runs slower. In fact I think the difference might only be due to rounding errors. I prefer 2 myself, but 3 is a nice alternative with a little more effect (but harsher on the highlight and shadows) and it's the fastest formula.";
> = 4;

uniform float Curves_contrast <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "The amount of contrast you want.";
> = 0.65;

#include "ReShade.fxh"

float4 CurvesPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 colorInput = tex2D(ReShade::BackBuffer, texcoord);
	float3 lumCoeff = float3(0.2126, 0.7152, 0.0722);  //Values to calculate luma with
	float Curves_contrast_blend = Curves_contrast; 
	const float PI = 3.1415927;

	/*-----------------------------------------------------------.
	/               Separation of Luma and Chroma                 /
	'-----------------------------------------------------------*/

	// -- Calculate Luma and Chroma if needed --
	//calculate luma (grey)
	float luma = dot(lumCoeff, colorInput.rgb);
	//calculate chroma
	float3 chroma = colorInput.rgb - luma;

	// -- Which value to put through the contrast formula? --
	// I name it x because makes it easier to copy-paste to Graphtoy or Wolfram Alpha or another graphing program
	float3 x;
	if (Curves_mode == 0)
		x = luma; //if the curve should be applied to Luma
	else if (Curves_mode == 1)
		x = chroma, //if the curve should be applied to Chroma
		x = x * 0.5 + 0.5; //adjust range of Chroma from -1 -> 1 to 0 -> 1
	else
		x = colorInput.rgb; //if the curve should be applied to both Luma and Chroma

	/*-----------------------------------------------------------.
	/                     Contrast formulas                       /
	'-----------------------------------------------------------*/

	// -- Curve 1 --
	if (Curves_formula == 0)
	{
		x = sin(PI * 0.5 * x); // Sin - 721 amd fps, +vign 536 nv
		x *= x;

		//x = 0.5 - 0.5*cos(PI*x);
		//x = 0.5 * -sin(PI * -x + (PI*0.5)) + 0.5;
	}

	// -- Curve 2 --
	if (Curves_formula == 1)
	{
		x = x - 0.5;
		x = (x / (0.5 + abs(x))) + 0.5;

		//x = ( (x - 0.5) / (0.5 + abs(x-0.5)) ) + 0.5;
	}

	// -- Curve 3 --
	if (Curves_formula == 2)
	{
		//x = smoothstep(0.0,1.0,x); //smoothstep
		x = x*x*(3.0 - 2.0*x); //faster smoothstep alternative - 776 amd fps, +vign 536 nv
		//x = x - 2.0 * (x - 1.0) * x* (x- 0.5);  //2.0 is contrast. Range is 0.0 to 2.0
	}

	// -- Curve 4 --
	if (Curves_formula == 3)
	{
		x = (1.0524 * exp(6.0 * x) - 1.05248) / (exp(6.0 * x) + 20.0855); //exp formula
	}

	// -- Curve 5 --
	if (Curves_formula == 4)
	{
		//x = 0.5 * (x + 3.0 * x * x - 2.0 * x * x * x); //a simplified catmull-rom (0,0,1,1) - btw smoothstep can also be expressed as a simplified catmull-rom using (1,0,1,0)
		//x = (0.5 * x) + (1.5 -x) * x*x; //estrin form - faster version
		x = x * (x * (1.5 - x) + 0.5); //horner form - fastest version

		Curves_contrast_blend = Curves_contrast * 2.0; //I multiply by two to give it a strength closer to the other curves.
	}

	// -- Curve 6 --
	if (Curves_formula == 5)
	{
		x = x*x*x*(x*(x*6.0 - 15.0) + 10.0); //Perlins smootherstep
	}

	// -- Curve 7 --
	if (Curves_formula == 6)
	{
		//x = ((x-0.5) / ((0.5/(4.0/3.0)) + abs((x-0.5)*1.25))) + 0.5;
		x = x - 0.5;
		x = x / ((abs(x)*1.25) + 0.375) + 0.5;
		//x = ( (x-0.5) / ((abs(x-0.5)*1.25) + (0.5/(4.0/3.0))) ) + 0.5;
	}

	// -- Curve 8 --
	if (Curves_formula == 7)
	{
		x = (x * (x * (x * (x * (x * (x * (1.6 * x - 7.2) + 10.8) - 4.2) - 3.6) + 2.7) - 1.8) + 2.7) * x * x; //Techicolor Cinestyle - almost identical to curve 1
	}

	// -- Curve 9 --
	if (Curves_formula == 8)
	{
		x = -0.5 * (x*2.0 - 1.0) * (abs(x*2.0 - 1.0) - 2.0) + 0.5; //parabola
	}

	// -- Curve 10 --
	if (Curves_formula == 9)
	{
		float3 xstep = step(x, 0.5); //tenary might be faster here
		float3 xstep_shift = (xstep - 0.5);
		float3 shifted_x = x + xstep_shift;

		x = abs(xstep - sqrt(-shifted_x * shifted_x + shifted_x)) - xstep_shift;

		//x = abs(step(x,0.5)-sqrt(-(x+step(x,0.5)-0.5)*(x+step(x,0.5)-0.5)+(x+step(x,0.5)-0.5)))-(step(x,0.5)-0.5); //single line version of the above

		//x = 0.5 + (sign(x-0.5)) * sqrt(0.25-(x-trunc(x*2))*(x-trunc(x*2))); //worse

		/* // if/else - even worse
		if (x-0.5)
		x = 0.5-sqrt(0.25-x*x);
		else
		x = 0.5+sqrt(0.25-(x-1)*(x-1));
		*/

		//x = (abs(step(0.5,x)-clamp( 1-sqrt(1-abs(step(0.5,x)- frac(x*2%1)) * abs(step(0.5,x)- frac(x*2%1))),0 ,1))+ step(0.5,x) )*0.5; //worst so far

		//TODO: Check if I could use an abs split instead of step. It might be more efficient

		Curves_contrast_blend = Curves_contrast * 0.5; //I divide by two to give it a strength closer to the other curves.
	}
  
	// -- Curve 11 --
	if (Curves_formula == 10)
	{
		float3 a = float3(0.0, 0.0, 0.0);
		float3 b = float3(0.0, 0.0, 0.0);

		a = x * x * 2.0;
		b = (2.0 * -x + 4.0) * x - 1.0;
		x = (x < 0.5) ? a : b;
	}

	/*-----------------------------------------------------------.
	/                 Joining of Luma and Chroma                  /
	'-----------------------------------------------------------*/

	if (Curves_mode == 0) // Only Luma
	{
		x = lerp(luma, x, Curves_contrast_blend); //Blend by Curves_contrast
		colorInput.rgb = x + chroma; //Luma + Chroma
	}
	else if (Curves_mode == 1) // Only Chroma
	{
		x = x * 2.0 - 1.0; //adjust the Chroma range back to -1 -> 1
		float3 color = luma + x; //Luma + Chroma
		colorInput.rgb = lerp(colorInput.rgb, color, Curves_contrast_blend); //Blend by Curves_contrast
	}
	else // Both Luma and Chroma
	{
		float3 color = x;  //if the curve should be applied to both Luma and Chroma
		colorInput.rgb = lerp(colorInput.rgb, color, Curves_contrast_blend); //Blend by Curves_contrast
	}

	return colorInput;
}

technique Curves
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CurvesPass;
	}
}
