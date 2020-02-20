/*------------------.
| :: Description :: |
'-------------------/

    Layer (version 0.3)

    Author: CeeJay.dk
    License: MIT

    About:
    Blends an image with the game.
    The idea is to give users with graphics skills the ability to create effects using a layer just like in an image editor.
    Maybe they could use this to create custom CRT effects, custom vignettes, logos, custom hud elements, toggable help screens and crafting tables or something I haven't thought of.

    Ideas for future improvement:
    * More blend modes
    * Tiling control
    * A default Layer texture with something useful in it

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility

    Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on XY axis

    Version 0.3 by Charles Fettinger
    * Added Min/Max Luminance to remove unwanted colors
*/

#include "ReShade.fxh"

#ifndef LAYER_SOURCE
#define LAYER_SOURCE "PredatorThermalView.gif"
#endif
#ifndef LAYER_SIZE_X
#define LAYER_SIZE_X 480
#endif
#ifndef LAYER_SIZE_Y
#define LAYER_SIZE_Y 284
#endif

#if LAYER_SINGLECHANNEL
    #define TEXFORMAT R8
#else
    #define TEXFORMAT RGBA8
#endif

#include "ReShadeUI.fxh"
   /*-----------------------------------------------------------.
  /                      Developer settings                     /
  '-----------------------------------------------------------*/
#define CoefLuma float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
//#define CoefLuma float3(0.299, 0.587, 0.114)       // BT.601 luma coefficient (SD Television)

uniform float2 Layer_Pos < __UNIFORM_DRAG_FLOAT2
    ui_label = "Layer Position";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = (1.0 / 200.0);
> = float2(0.5, 0.5);

uniform float Layer_Scale < __UNIFORM_DRAG_FLOAT1
    ui_label = "Layer Scale";
    ui_min = (1.0 / 100.0); ui_max = 4.0;
    ui_step = (1.0 / 250.0);
> = 1.0;

uniform float Layer_Blend < __UNIFORM_COLOR_FLOAT1
    ui_label = "Layer Blend";
    ui_tooltip = "How much to blend layer with the original image.";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = (1.0 / 255.0); // for slider and drag
> = 1.0;

uniform float Min_Luma < __UNIFORM_DRAG_FLOAT1
    ui_label = "Minimum Luminance to remove dark colors";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = (1.0 / 250.0);
> = 0.0;

uniform float Min_Luma_Smooth < __UNIFORM_DRAG_FLOAT1
    ui_label = "Minimum Luminance Smooth - make the transparency fade in or out by a distance";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = (1.0 / 250.0);
> = 0.01;

uniform float Max_Luma < __UNIFORM_DRAG_FLOAT1
    ui_label = "Maximum Luminance to remove light colors";
    ui_min = -0.2; ui_max = 1.2;
    ui_step = (1.0 / 250.0);
> = 1.0;

uniform float Max_Luma_Smooth < __UNIFORM_DRAG_FLOAT1
    ui_label = "Minimum Luminance Smooth - make the transparency fade in or out by a distance";
    ui_min = -0.2; ui_max = 1.2;
    ui_step = (1.0 / 250.0);
> = 0.10;

uniform float Speed < __UNIFORM_SLIDER_FLOAT1
	ui_min = -10.00; ui_max = 10.00;
	ui_label = "Speed";
	ui_tooltip = "Speed Layer blinks in and out";
> = 0.000;

texture Layer_Tex <
    source = LAYER_SOURCE;
> {
    Format = TEXFORMAT;
    Width  = LAYER_SIZE_X;
    Height = LAYER_SIZE_Y;
};

sampler Layer_Sampler
{
    Texture  = Layer_Tex;
    AddressU = BORDER;
    AddressV = BORDER;
};

uniform float elapsed_time < source = "timer"; >;

void PS_Layer(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target)
{
    const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);
    const float2 pixelSize = 1.0 / (float2(LAYER_SIZE_X, LAYER_SIZE_Y) * Layer_Scale / BUFFER_SCREEN_SIZE);
    const float4 layer     = tex2D(Layer_Sampler, texCoord * pixelSize + Layer_Pos * (1.0 - pixelSize));

    const float luminance = saturate(dot(CoefLuma, layer));
    float time = (elapsed_time * 0.001 * clamp(Speed, -10.0, 10.0));

    float lumaLo = smoothstep(Min_Luma, Min_Luma + Min_Luma_Smooth, luminance);
	float lumaHi = 1.0 - smoothstep(Max_Luma - Max_Luma_Smooth, Max_Luma, luminance);

	float lumaMask = lumaLo * lumaHi;

    passColor   = lerp(backColor, layer, lumaMask * Layer_Blend * abs(cos(time)));
    passColor.a = backColor.a;
}

technique Layer
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer;
    }
}
