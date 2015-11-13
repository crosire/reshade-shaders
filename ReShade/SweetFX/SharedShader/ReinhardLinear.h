//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//LICENSE AGREEMENT AND DISTRIBUTION RULES:
//1 Copyrights of the Master Effect exclusively belongs to author - Gilcher Pascal aka Marty McFly.
//2 Master Effect (the SOFTWARE) is DonateWare application, which means you may or may not pay for this software to the author as donation.
//3 If included in ENB presets, credit the author (Gilcher Pascal aka Marty McFly).
//4 Software provided "AS IS", without warranty of any kind, use it on your own risk. 
//5 You may use and distribute software in commercial or non-commercial uses. For commercial use it is required to warn about using this software (in credits, on the box or other places). Commercial distribution of software as part of the games without author permission prohibited.
//6 Author can change license agreement for new versions of the software.
//7 All the rights, not described in this license agreement belongs to author.
//8 Using the Master Effect means that user accept the terms of use, described by this license agreement.
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//For more information about license agreement contact me:
//https://www.facebook.com/MartyMcModding
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Copyright (c) 2009-2015 Gilcher Pascal aka Marty McFly
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Credits :: Ubisoft
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float4 ReinhardLinearToneMapping(float4 colorInput)
{
	float3 x = colorInput.rgb;

    	const float W = ReinhardLinearWhitepoint;	        // Linear White Point Value
    	const float L = ReinhardLinearPoint;           // Linear point
    	const float C = ReinhardLinearSlope;           // Slope of the linear section
    	const float K = (1 - L * C) / C; // Scale (fixed so that the derivatives of the Reinhard and linear functions are the same at x = L)
    	float3 reinhard = L * C + (1 - L * C) * (1 + K * (x - L) / ((W - L) * (W - L))) * (x - L) / (x - L + K);

    	// gamma space or not?
    	colorInput.rgb = (x > L) ? reinhard : C * x;
	return colorInput;
}