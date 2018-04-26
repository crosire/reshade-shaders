//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// Eye Adaption by brussell
//
// Credits:
// luluco250 - luminance get/store code from Magic Bloom
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

//effect parameters
uniform float fAdp_Speed <
    ui_label = "AdaptionSpeed";
    ui_tooltip = "Speed of adaption. The higher the faster";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.1;

uniform bool bAdp_BrightenEnable <
    ui_label = "BrightenEnable";
	ui_tooltip = "Enable Brightening";
> = true;

uniform float fAdp_BrightenThreshold <
    ui_label = "BrightenThreshold";
    ui_tooltip = "A lower average screen luminance brightens the image";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.2;

uniform float fAdp_BrightenMax <
    ui_label = "BrightenMax";
    ui_tooltip = "Brightens the image by maximum value";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.1;

uniform float fAdp_BrightenCurve <
    ui_label = "BrightenCurve";
    ui_tooltip = "Brightening increase depending on average screen luminance. 1=linear growth, 0.5=quadratic, 2=sq. root";
    ui_type = "drag";
    ui_min = 0.2;
    ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float fAdp_BrightenDynamic <
    ui_label = "BrightenDynamic";
    ui_tooltip = "Amount of pixel dependent brightening (less brightening of already bright pixels)";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.5;

uniform float fAdp_BrightenBlack <
    ui_label = "BrightenBlack";
    ui_tooltip = "Amount of lows preservation. 1=no black brightening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.5;

uniform float fAdp_BrightenSaturation <
    ui_label = "BrightenSaturation";
    ui_tooltip = "Color saturation change while brightening.";
    ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.0;

uniform bool bAdp_DarkenEnable <
    ui_label = "DarkenEnable";
	ui_tooltip = "Enable Darkening";
> = true;

uniform float fAdp_DarkenThreshold <
    ui_label = "DarkenThreshold";
    ui_tooltip = "A higher average screen luminance darkens the image";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.3;

uniform float fAdp_DarkenMax <
    ui_label = "DarkenMax";
    ui_tooltip = "Darkens the image by maximum value";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.4;

uniform float fAdp_DarkenCurve <
    ui_label = "DarkenCurve";
    ui_tooltip = "Darkening increase depending on average screen luminance. 1=linear growth, 0.5=quadratic, 2=sq. root";
    ui_type = "drag";
    ui_min = 0.2;
    ui_max = 5.0;
    ui_step = 0.001;
> = 0.5;

uniform float fAdp_DarkenDynamic <
    ui_label = "DarkenDynamic";
    ui_tooltip = "Amount of pixel dependent darkening (less darkening of already dark pixels)";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.5;

uniform float fAdp_DarkenWhite <
    ui_label = "DarkenWhite";
    ui_tooltip = "Amount of highs preservation. 1=no white darkening";
    ui_type = "drag";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.5;

uniform float fAdp_DarkenSaturation <
    ui_label = "DarkenSaturation";
    ui_tooltip = "Color saturation change while darkening.";
    ui_type = "drag";
    ui_min = -1.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.0;

//global vars
#define LumCoeff float3(0.212656, 0.715158, 0.072186)
uniform float Frametime < source = "frametime";>;

//textures and samplers
texture2D texLuminance { Width = 256; Height = 256; Format = R8; MipLevels = 7; };
texture2D texAvgLuminance { Format = R16F; };
texture2D texAvgLuminanceLast { Format = R16F; };

sampler SamplerLuminance { Texture = texLuminance; };
sampler SamplerAvgLuminance { Texture = texAvgLuminance; };
sampler SamplerAvgLuminanceLast { Texture = texAvgLuminanceLast; };

//pixel shaders
float PS_Luminance(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
   return dot(tex2D(ReShade::BackBuffer, texcoord.xy).xyz, LumCoeff);
}

float PS_AvgLuminance(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
   float lum = tex2Dlod(SamplerLuminance, float4(0.5.xx, 0, 7)).x;
   float lumlast = tex2D(SamplerAvgLuminanceLast, 0.0).x;
   return lerp(lumlast, lum, fAdp_Speed * 10.0/Frametime);
}

float PS_StoreAvgLuminance(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
   return tex2D(SamplerAvgLuminance, 0.0).x;
}

float4 PS_Adaption(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 color = tex2Dlod(ReShade::BackBuffer, float4 (texcoord.xy, 0, 0));
    static const float avglum = saturate(tex2D(SamplerAvgLuminance, 0.0).x);
    float adpcurve, adpdelta;
    float colorluma = dot(color.xyz, LumCoeff);
    float3 colorchroma = color.xyz - colorluma;

    [branch]
    if(bAdp_BrightenEnable == true && avglum < fAdp_BrightenThreshold) {
        adpcurve = (-fAdp_BrightenMax / pow(fAdp_BrightenThreshold, fAdp_BrightenCurve)) * pow(avglum, fAdp_BrightenCurve) + fAdp_BrightenMax;
        adpdelta = lerp(adpcurve, adpcurve - adpcurve * colorluma, fAdp_BrightenDynamic);
        adpdelta = lerp(adpdelta, min(colorluma, adpdelta), fAdp_BrightenBlack);
        colorluma += adpdelta;
        colorchroma = colorchroma * saturate(1.0 + (adpcurve / fAdp_BrightenMax) * fAdp_BrightenSaturation);
        color.xyz = colorluma + colorchroma;
    }
    [branch]
    if(bAdp_DarkenEnable == true && avglum > fAdp_DarkenThreshold) {
        adpcurve = (fAdp_DarkenMax / pow(1.0 - fAdp_DarkenThreshold, 1.0 / fAdp_DarkenCurve)) * pow(avglum - fAdp_DarkenThreshold, 1.0 / fAdp_DarkenCurve);
        adpdelta = lerp(adpcurve, adpcurve * colorluma, fAdp_DarkenDynamic);
        adpdelta = lerp(adpdelta, min(1.0 - colorluma, adpdelta), fAdp_DarkenWhite);
        colorluma -= adpdelta;
        colorchroma = colorchroma * saturate(1.0 + (adpcurve / fAdp_DarkenMax) * fAdp_DarkenSaturation);
        color.xyz = colorluma + colorchroma;
    }

    return color;
}

//techniques
technique EyeAdaption {

    pass Luminance
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Luminance;
        RenderTarget = texLuminance;
    }

    pass AvgLuminance
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_AvgLuminance;
        RenderTarget = texAvgLuminance;
    }

    pass Adaption
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Adaption;
    }

    pass StoreAvgLuminance
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StoreAvgLuminance;
        RenderTarget = texAvgLuminanceLast;
    }
}