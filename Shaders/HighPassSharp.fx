
//High Pass Sharpening by Ioxa
//Version 1.4 for ReShade 3.0

//Settings

uniform int HighPassSharpRadius
<
	ui_type = "drag";
	ui_min = 1; ui_max = 3;
	ui_tooltip = "1 = 3x3 mask, 2 = 5x5 mask, 3 = 7x7 mask.";
> = 1;

uniform float HighPassSharpOffset
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Additional adjustment for the blur radius. Values less than 1.00 will reduce the radius limiting the sharpening to finer details.";
	ui_step = 0.20;
> = 1.00;

uniform int HighPassBlendMode
<
	ui_type = "drag";
	ui_min = 1; ui_max = 7;
	ui_tooltip = "1 = Soft Light, 2 = Overlay, 3 = Multiply, 4 = Hard Light, 5 = Vivid Light, 6 = Screen 7 = Linear Light";
	ui_step = 1;
> = 2;

uniform int HighPassBlendIfDark
<
	ui_type = "drag";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "Any pixels below this value will be excluded from the effect. Set to 50 to target mid-tones.";
	ui_step = 5;
> = 50;

uniform int HighPassBlendIfLight
<
	ui_type = "drag";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "Any pixels above this value will be excluded from the effect. Set to 205 to target mid-tones.";
	ui_step = 5;
> = 205;

uniform bool HighPassViewBlendIfMask
<
	ui_tooltip = "Displays the BlendIfMask. Useful when adjusting BlendIf settings.";
> = false;

uniform float HighPassDarkIntensity
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 5.00;
	ui_tooltip = "Adjusts the strength of dark halos.";
	ui_step = 0.50;
> = 1.0;

uniform float HighPassLightIntensity
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 5.00;
	ui_tooltip = "Adjusts the strength of light halos.";
	ui_step = 0.50;
> = 1.0;

uniform float HighPassSharpStrength
<
	ui_type = "drag";
	ui_min = 0.00; ui_max = 2.00;
	ui_tooltip = "Adjusts the strength of the effect";
	ui_step = 0.25;
> = 1.00;


uniform bool HighPassViewSharpMask
<
	ui_tooltip = "Displays the SharpMask. Useful when adjusting settings";
> = false;

#define HighPass_ToggleKey 0x2D //[undef] //-Default is the "Insert" key. Change to RESHADE_TOGGLE_KEY to toggle with the rest of the Framework shaders.   

#include "ReShade.fxh"

float HPDoSmoothererstep(float edge0, float edge1, float x)
{
	x = ((x-edge0)/(edge1-edge0));
	return x*x*x*x*(x*(x*(70-20*x)-84)+35);
}

float3 SharpBlurFinal(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 orig = color;
	float luma = dot(color.rgb,float3(0.32786885,0.655737705,0.0163934436));
	float3 chroma = orig.rgb/luma;

	switch(HighPassSharpRadius)
	{
		case 1:
			{
				color *= 0.225806;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.150538;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.150538;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(0.0, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.150538;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(0.0, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.150538;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0430108;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0430108;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, -1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0430108;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, -1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0430108;
				
				break;
			}
		case 2:
			{
				color *= 0.1509985387665926499;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.1132489040749444874;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.1132489040749444874;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(0.0, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.1132489040749444874;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(0.0, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.1132489040749444874;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0273989284225933369;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0273989284225933369;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, -1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0273989284225933369;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, -1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0273989284225933369;
				
				color += tex2D(ReShade::BackBuffer, texcoord + float2(2.0 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.0452995616018920668;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(2.0 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.0452995616018920668;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(0.0, 2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0452995616018920668;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(0.0, 2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0452995616018920668;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(2.0 * ReShade::PixelSize.x, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(2.0 * ReShade::PixelSize.x, 1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(2.0 * ReShade::PixelSize.x, -1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(2.0 * ReShade::PixelSize.x, -1.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, 2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, 2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.0 * ReShade::PixelSize.x, -2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.0 * ReShade::PixelSize.x, -2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0109595713409516066;
				
				color += tex2D(ReShade::BackBuffer, texcoord + float2(2.0 * ReShade::PixelSize.x, 2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0043838285270187332;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(2.0 * ReShade::PixelSize.x, 2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0043838285270187332;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(2.0 * ReShade::PixelSize.x, -2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0043838285270187332;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(2.0 * ReShade::PixelSize.x, -2.0 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0043838285270187332;
				
				break;
			}
		case 3:
			{
				color *= 0.0957733978977875942;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.3846153846 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.1333986613666725565;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.3846153846 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.1333986613666725565;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(0.0, 1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.1333986613666725565;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(0.0, 1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.1333986613666725565;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.3846153846 * ReShade::PixelSize.x, 1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0421828199486419528;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.3846153846 * ReShade::PixelSize.x, 1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0421828199486419528;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.3846153846 * ReShade::PixelSize.x, -1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0421828199486419528;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.3846153846 * ReShade::PixelSize.x, -1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0421828199486419528;
				
				color += tex2D(ReShade::BackBuffer, texcoord + float2(3.2307692308 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.0296441469844336464;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(3.2307692308 * ReShade::PixelSize.x, 0.0) * HighPassSharpOffset).rgb * 0.0296441469844336464;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(0.0, 3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0296441469844336464;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(0.0, 3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0296441469844336464;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(3.2307692308 * ReShade::PixelSize.x, 1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(3.2307692308 * ReShade::PixelSize.x, 1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(3.2307692308 * ReShade::PixelSize.x, -1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(3.2307692308 * ReShade::PixelSize.x, -1.3846153846 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.3846153846 * ReShade::PixelSize.x, 3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.3846153846 * ReShade::PixelSize.x, 3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(1.3846153846 * ReShade::PixelSize.x, -3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(1.3846153846 * ReShade::PixelSize.x, -3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0093739599979617454;
				
				color += tex2D(ReShade::BackBuffer, texcoord + float2(3.2307692308 * ReShade::PixelSize.x, 3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0020831022264565991;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(3.2307692308 * ReShade::PixelSize.x, 3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0020831022264565991;
				color += tex2D(ReShade::BackBuffer, texcoord + float2(3.2307692308 * ReShade::PixelSize.x, -3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0020831022264565991;
				color += tex2D(ReShade::BackBuffer, texcoord - float2(3.2307692308 * ReShade::PixelSize.x, -3.2307692308 * ReShade::PixelSize.y) * HighPassSharpOffset).rgb * 0.0020831022264565991;
				
				break;
			}
	}
	
	float sharp = dot(color.rgb,float3(0.32786885,0.655737705,0.0163934436));
	sharp = 1.0 - sharp;
	sharp = (luma+sharp)*0.5;

	float sharpMin = lerp(0,1,HPDoSmoothererstep(0,1,sharp));
	float sharpMax = sharpMin;
	sharpMin = lerp(sharp,sharpMin,HighPassDarkIntensity);
	sharpMax = lerp(sharp,sharpMax,HighPassLightIntensity);
	sharp = lerp(sharpMin,sharpMax,step(0.5,sharp));

	if(HighPassViewSharpMask)
	{
		//View sharp mask
		orig.rgb = sharp;
		luma = sharp;
		chroma = 1.0;
	}
	else 
	{
		switch(HighPassBlendMode)
		{
			case 1:
				{	
					//softlight
					sharp = lerp((2*sharp-1)*(luma-pow(luma,2))+luma, ((2*sharp-1)*(pow(luma,0.5)-luma))+luma, smoothstep(0.40,0.60,luma));
					break;
				}
			case 2:
				{
					//overlay
					sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.5,luma));
					break;
				}
			case 3:
				{
					//Multiply
					sharp = saturate(2.0 * luma * sharp);
					break;
				}
			case 4:
				{
					//Hardlight
					sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.5,sharp));
					break;
				}
			case 5:
				{
					//vivid light
					sharp = lerp(1-(1-luma)/(2*sharp),luma/(2*(1-sharp)),step(0.5,sharp));
					break;
				}
			case 6:
				{
					//Screen
					sharp = 1.0 - (2*(1.0-luma)*(1.0-sharp));
					break;
				}
			case 7:
				{
					//Linear Light
					sharp = lerp(luma+2*sharp-1,luma+2*(sharp-0.5),step(0.5,sharp));
					break;
				}
		}
	}
	
	if( HighPassBlendIfDark > 0 || HighPassBlendIfLight < 255 || HighPassViewBlendIfMask)
	{
		float BlendIfD = (HighPassBlendIfDark/255.0)+0.0001;
		float BlendIfL = (HighPassBlendIfLight/255.0)-0.0001;
		float mix = dot(orig.rgb, 0.333333);
		float mask = 1.0;
		
		if(HighPassBlendIfDark > 0)
		{
			mask = lerp(0.0,1.0,smoothstep(BlendIfD-(BlendIfD*0.2),BlendIfD+(BlendIfD*0.2),mix));
		}
		
		if(HighPassBlendIfLight < 255)
		{
			mask = lerp(mask,0.0,smoothstep(BlendIfL-(BlendIfL*0.2),BlendIfL+(BlendIfL*0.2),mix));
		}
		
		sharp = lerp(luma,sharp,mask);
		if (HighPassViewBlendIfMask)
		{
			sharp = mask;
			luma = mask;
			chroma = 1.0;
		}
	}
	
	luma = lerp(luma, sharp, HighPassSharpStrength);
	orig.rgb = luma*chroma;
	
	return saturate(orig);
}

technique HighPassSharp <bool enabled = true; int toggle = HighPass_ToggleKey; >
{

	pass Sharp
	{
		VertexShader = PostProcessVS;
		PixelShader = SharpBlurFinal;
	}

}
