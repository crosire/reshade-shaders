#include "ReShade/Iddqd.cfg"

#if USE_DALTONIZEFX

namespace Iddqd
{

float4 DaltonizeFX( float4 input, float2 tex )
{
	// RGB to LMS matrix conversion
	float OnizeL = (17.8824f * input.r) + (43.5161f * input.g) + (4.11935f * input.b);
	float OnizeM = (3.45565f * input.r) + (27.1554f * input.g) + (3.86714f * input.b);
	float OnizeS = (0.0299566f * input.r) + (0.184309f * input.g) + (1.46709f * input.b);
    
    // Simulate color blindness

#if ( DaltonizeFX_Type == 1) // Protanopia - reds are greatly reduced (1% men)
    float Daltl = 0.0f * OnizeL + 2.02344f * OnizeM + -2.52581f * OnizeS;
    float Daltm = 0.0f * OnizeL + 1.0f * OnizeM + 0.0f * OnizeS;
    float Dalts = 0.0f * OnizeL + 0.0f * OnizeM + 1.0f * OnizeS;
#elif ( DaltonizeFX_Type == 2) // Deuteranopia - greens are greatly reduced (1% men)
    float Daltl = 1.0f * OnizeL + 0.0f * OnizeM + 0.0f * OnizeS;
    float Daltm = 0.494207f * OnizeL + 0.0f * OnizeM + 1.24827f * OnizeS;
    float Dalts = 0.0f * OnizeL + 0.0f * OnizeM + 1.0f * OnizeS;
#else // Tritanopia - blues are greatly reduced (0.003% population)
    float Daltl = 1.0f * OnizeL + 0.0f * OnizeM + 0.0f * OnizeS;
    float Daltm = 0.0f * OnizeL + 1.0f * OnizeM + 0.0f * OnizeS;
    float Dalts = -0.395913f * OnizeL + 0.801109f * OnizeM + 0.0f * OnizeS;
#endif
    
	// LMS to RGB matrix conversion
	float4 error;
	error.r = (0.0809444479f * Daltl) + (-0.130504409f * Daltm) + (0.116721066f * Dalts);
	error.g = (-0.0102485335f * Daltl) + (0.0540193266f * Daltm) + (-0.113614708f * Dalts);
	error.b = (-0.000365296938f * Daltl) + (-0.00412161469f * Daltm) + (0.693511405f * Dalts);
	error.a = 1;
	
    // Isolate invisible colors to color vision deficiency (calculate error matrix)
	error = (input - error);
	
    // Shift colors towards visible spectrum (apply error modifications)
	float4 correction;
	correction.r = 0; // (error.r * 0.0) + (error.g * 0.0) + (error.b * 0.0);
	correction.g = (error.r * 0.7) + (error.g * 1.0); // + (error.b * 0.0);
	correction.b = (error.r * 0.7) + (error.b * 1.0); // + (error.g * 0.0);
	
    // Add compensation to original values
    correction = input + correction;
    correction.a = input.a;
	
	return correction.rgba;
}

float4 PS_DaltonizeFXmain(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
float4 color = tex2D(RFX_backbufferColor, texcoord);

color = DaltonizeFX(color, texcoord);

return color;
}

technique DaltonizeFX_Tech <bool enabled = RFX_Start_Enabled; int toggle = DaltonizeFX_ToggleKey; >
{
	pass DaltonizePass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_DaltonizeFXmain;
	}
}

}

#endif

#include "ReShade/Iddqd.undef"
