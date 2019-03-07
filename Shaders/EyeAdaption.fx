//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// Eye Adaption by brussell
// v. 2.0
// 
// Credits:
// luluco250 - luminance get/store code from Magic Bloom
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

//effect parameters
uniform float fAdp_Speed <
    ui_label = "AdaptionSpeed";
    ui_tooltip = "How fast the image adapts to brightness changes. 1 = instantanous adaption";
    ui_category = "General settings";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.05;

uniform float fAdp_TriggerRadius <
    ui_label = "AdaptionTriggerRadius";
    ui_tooltip = "Area that is used for calculation of the average image brighness. 1 = only the center of the image is used, 7 = the whole image is used";
    ui_category = "General settings";
    ui_type = "drag";
    ui_min = 1.0;
    ui_max = 7.0;
    ui_step = 1.0;
> = 6.0;

uniform float fAdp_BrightenThreshold <
    ui_label = "BrightenThreshold";
    ui_tooltip = "If the average image brightness is lower than this value, the image gets brightened";
    ui_category = "Brightening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 0.4;
> = 0.1;

uniform float fAdp_BrightenHighlights <
    ui_label = "BrightenHighlights";
    ui_tooltip = "Brightening strength for highlights";
    ui_category = "Brightening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.1;

uniform float fAdp_BrightenMidtones <
    ui_label = "BrightenMidtones";
    ui_tooltip = "Brightening strength for midtones";
    ui_category = "Brightening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.15;

uniform float fAdp_BrightenShadows <
    ui_label = "BrightenShadows";
    ui_tooltip = "Brightening strength for shadows. Set this to 0 to preserve pure black";
    ui_category = "Brightening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.0;

uniform float fAdp_DarkenThreshold <
    ui_label = "DarkenThreshold";
    ui_tooltip = "If the average image brightness is higher than this value, the image gets darkened";
    ui_category = "Darkening";
    ui_type = "drag";
    ui_min = 0.4;
    ui_max = 1.0;

> = 0.5;

uniform float fAdp_DarkenHighlights <
    ui_label = "DarkenHighlights";
    ui_tooltip = "Darkening strength for highlights. Set this to 0 to preserve pure white";
    ui_category = "Darkening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.0;

uniform float fAdp_DarkenMidtones <
    ui_label = "DarkenMidtones";
    ui_tooltip = "Darkening strength for midtones";
    ui_category = "Darkening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.15;

uniform float fAdp_DarkenShadows <
    ui_label = "DarkenShadows";
    ui_tooltip = "Darkening strength for shadows";
    ui_category = "Darkening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.1;


//global vars
#define LumCoeff float3(0.212656, 0.715158, 0.072186)
uniform float Frametime < source = "frametime";>;

//textures and samplers
texture2D TexLuma { Width = 256; Height = 256; Format = R8; MipLevels = 7; };
texture2D TexAvgLuma { Format = R16F; };
texture2D TexAvgLumaLast { Format = R16F; };

sampler SamplerLuma { Texture = TexLuma; };
sampler SamplerAvgLuma { Texture = TexAvgLuma; };
sampler SamplerAvgLumaLast { Texture = TexAvgLumaLast; };

//pixel shaders
float PS_Luma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 color = tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0, 0));
    float luma = dot(color.xyz, LumCoeff);
    return luma;
}

float PS_AvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float avgLumaCurrFrame = tex2Dlod(SamplerLuma, float4(0.5.xx, 0, fAdp_TriggerRadius)).x;
    float avgLumaLastFrame = tex2Dlod(SamplerAvgLumaLast, float4(0.0.xx, 0, 0)).x;
    float avgLuma = lerp(avgLumaLastFrame, avgLumaCurrFrame, min(fAdp_Speed * 10.0 / Frametime, 1.0));
    return avgLuma;
}
    
float PS_StoreAvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
   float avgLuma = tex2Dlod(SamplerAvgLuma, float4(0.0.xx, 0, 0)).x;
   return avgLuma;
}

float AdaptionDelta(float luma, float strengthMidtones, float strengthShadows, float strengthHighlights)
{
    float midtones = (4.0 * strengthMidtones - strengthHighlights - strengthShadows) * luma * (1.0 - luma);
    float shadows = strengthShadows * (1.0 - luma);
    float highlights = strengthHighlights * luma;
    float delta = midtones + shadows + highlights;
    return delta;
}

float4 PS_EyeAdaption(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 color = tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0, 0));
    float avgLuma = tex2Dlod(SamplerAvgLuma, float4(0.0.xx, 0, 0)).x;
    
    color.xyz = pow(color.xyz, 1/2.2);
    float luma = dot(color.xyz, LumCoeff);
    float3 chroma = color.xyz - luma;
    
    float curve; float delta = 0;
    
    [branch]
    if (avgLuma < fAdp_BrightenThreshold) 
    {
        curve = 1.0/fAdp_BrightenThreshold * abs(avgLuma - fAdp_BrightenThreshold);
        delta = curve * AdaptionDelta(luma, fAdp_BrightenMidtones, fAdp_BrightenShadows, fAdp_BrightenHighlights);
    }
    [branch]
    if (avgLuma > fAdp_DarkenThreshold)
    {
        curve = -1.0/(1.0 - fAdp_DarkenThreshold) * abs(avgLuma - fAdp_DarkenThreshold);
        delta = curve * AdaptionDelta(luma, fAdp_DarkenMidtones, fAdp_DarkenShadows, fAdp_DarkenHighlights);
    }
    
    luma = saturate(luma + delta);
    color.xyz = luma + chroma;
    color.xyz = pow(color.xyz, 2.2);
    
    return color;
}

//techniques
technique EyeAdaption {

    pass Luma
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Luma;
        RenderTarget = TexLuma;
    }

    pass AvgLuma
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_AvgLuma;
        RenderTarget = TexAvgLuma;
    }

    pass Adaption
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_EyeAdaption;
    }

    pass StoreAvgLuma
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StoreAvgLuma;
        RenderTarget = TexAvgLumaLast;
    }
}
