#include "ReShade.fxh"

uniform int iCRTMask_Type <
	ui_type = "combo";
	ui_items = "X Only\0Y Only\0X and Y";
	ui_label = "Mask Type[CRTMask]";
> = 0;

uniform float fCRTMask_Brightness <
	ui_type = "drag";
	ui_min = "0.0";
	ui_max = "20.0";
	ui_label = "Brightness [CRTMask]";
> = 1.25;

uniform bool bCRTMask_useRes <
	ui_type = "combo";
	ui_label = "Use Custom Res[CRTMask]";
> = false;

uniform int iCRTMask_resX <
	ui_type = "drag";
	ui_min = "0.0";
	ui_max = "BUFFER_WIDTH";
	ui_label = "Width [CRTMask]";
> = 320;

uniform int iCRTMask_resY <
	ui_type = "drag";
	ui_min = "0.0";
	ui_max = "BUFFER_HEIGHT";
	ui_label = "Height [CRTMask]";
> = 240;

// Will return a value of 1 if the 'x' is < 'value'
float Less(float x, float value)
{
	return 1.0 - step(value, x);
}

// Will return a value of 1 if the 'x' is >= 'lower' && < 'upper'
float Between(float x, float  lower, float upper)
{
    return step(lower, x) * (1.0 - step(upper, x));
}

//	Will return a value of 1 if 'x' is >= value
float GEqual(float x, float value)
{
    return step(value, x);
}

float mod(float x, float y)
{
	return x - y * floor (x/y);
}

float3 CRTMask(float4 pos : SV_Position, float2 uv : TEXCOORD0) : SV_Target {
    //uv.y = -uv.y;
    //uv = uv * 1.0;
    
    float2 uvStep;
    uvStep.x = uv.x / (1.0 / ReShade::ScreenSize.x);
	if (bCRTMask_useRes){
	uvStep.x = uv.x / (1.0 / iCRTMask_resX);
	}
    uvStep.x = mod(uvStep.x, 3.0);
	uvStep.y = uv.y / (1.0 / ReShade::ScreenSize.y);
	if (bCRTMask_useRes){
	uvStep.y = uv.y / (1.0 / iCRTMask_resY);
	}
    uvStep.y = mod(uvStep.y, 3.0);
    
    float4 newColour = tex2D(ReShade::BackBuffer, uv);
    
if (iCRTMask_Type == 0){
    newColour.r = newColour.r * Less(uvStep.x, 1.0);
    newColour.g = newColour.g * Between(uvStep.x, 1.0, 2.0);
    newColour.b = newColour.b * GEqual(uvStep.x, 2.0);
	}

else if (iCRTMask_Type == 1){
    newColour.r = newColour.r * Less(uvStep.y, 1.0);
    newColour.g = newColour.g * Between(uvStep.y, 1.0, 2.0);
    newColour.b = newColour.b * GEqual(uvStep.y, 2.0);
}

else if (iCRTMask_Type == 2){
    newColour.r = newColour.r * step(1.0, (Less(uvStep.x, 1.0) + Less(uvStep.y, 1.0)));
    newColour.g = newColour.g * step(1.0, (Between(uvStep.x, 1.0, 2.0) + Between(uvStep.y, 1.0, 2.0)));
    newColour.b = newColour.b * step(1.0, (GEqual(uvStep.x, 2.0) + GEqual(uvStep.y, 2.0)));
}
    
	return newColour * fCRTMask_Brightness;
}

technique CRTMask
{
	pass CRT2
	{
		VertexShader = PostProcessVS;
		PixelShader = CRTMask;
	}
}