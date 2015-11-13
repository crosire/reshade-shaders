float4 FilmPass(float4 colorInput)
{
	float3 B = colorInput.rgb;	

	float3 G = B;
	float3 H = 0.01;
 
	B = saturate(B);
	B = pow(B, Linearization);
	B = lerp(H, B, Contrast);
 
	float A = dot(B.rgb, LumCoeff);
	float3 D = A;
 
	B = pow(B, 1.0 / BaseGamma);
 
	float a = FRedCurve;
	float b = FGreenCurve;
	float c = FBlueCurve;
	float d = BaseCurve;
 
	float y = 1.0 / (1.0 + exp(a / 2.0));
	float z = 1.0 / (1.0 + exp(b / 2.0));
	float w = 1.0 / (1.0 + exp(c / 2.0));
	float v = 1.0 / (1.0 + exp(d / 2.0));
 
	float3 C = B;
 
	D.r = (1.0 / (1.0 + exp(-a * (D.r - 0.5))) - y) / (1.0 - 2.0 * y);
	D.g = (1.0 / (1.0 + exp(-b * (D.g - 0.5))) - z) / (1.0 - 2.0 * z);
	D.b = (1.0 / (1.0 + exp(-c * (D.b - 0.5))) - w) / (1.0 - 2.0 * w);
 
	D = pow(D, 1.0 / EffectGamma);
 
	float3 Di = 1.0 - D;
 
	D = lerp(D, Di, FBleach);
 
	D.r = pow(abs(D.r), 1.0 / EffectGammaR);
	D.g = pow(abs(D.g), 1.0 / EffectGammaG);
	D.b = pow(abs(D.b), 1.0 / EffectGammaB);
 
	if (D.r < 0.5)
		C.r = (2.0 * D.r - 1.0) * (B.r - B.r * B.r) + B.r;
	else
		C.r = (2.0 * D.r - 1.0) * (sqrt(B.r) - B.r) + B.r;
 
	if (D.g < 0.5)
		C.g = (2.0 * D.g - 1.0) * (B.g - B.g * B.g) + B.g;
	else
		C.g = (2.0 * D.g - 1.0) * (sqrt(B.g) - B.g) + B.g;
 	//if (AgainstAllAutority) 
	if (D.b < 0.5)
		C.b = (2.0 * D.b - 1.0) * (B.b - B.b * B.b) + B.b;
	else
		C.b = (2.0 * D.b - 1.0) * (sqrt(B.b) - B.b) + B.b;
 
	float3 F = lerp(B, C, Strenght);
 
	F = (1.0 / (1.0 + exp(-d * (F - 0.5))) - v) / (1.0 - 2.0 * v);
 
	float r2R = 1.0 - FSaturation;
	float g2R = 0.0 + FSaturation;
	float b2R = 0.0 + FSaturation;
 
	float r2G = 0.0 + FSaturation;
	float g2G = (1.0 - Fade) - FSaturation;
	float b2G = (0.0 + Fade) + FSaturation;
 
	float r2B = 0.0 + FSaturation;
	float g2B = (0.0 + Fade) + FSaturation;
	float b2B = (1.0 - Fade) - FSaturation;
 
	float3 iF = F;
 
	F.r = (iF.r * r2R + iF.g * g2R + iF.b * b2R);
	F.g = (iF.r * r2G + iF.g * g2G + iF.b * b2G);
	F.b = (iF.r * r2B + iF.g * g2B + iF.b * b2B);
 
	float N = dot(F.rgb, LumCoeff);
	float3 Cn = F;
 
	if (N < 0.5)
		Cn = (2.0 * N - 1.0) * (F - F * F) + F;
	else
		Cn = (2.0 * N - 1.0) * (sqrt(F) - F) + F;
 
	Cn = pow(max(Cn,0), 1.0 / Linearization);
 
	float3 Fn = lerp(B, Cn, Strenght);
	
	colorInput.rgb = Fn;
	return colorInput;
}