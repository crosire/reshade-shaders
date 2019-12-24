/* 
  Filmic tonemapper with exposure correction by prod80 for ReShade
  Version 3.0

  Sources/credits
  For the methods : https://placeholderart.wordpress.com/2014/11/21/implementing-a-physically-based-camera-manual-exposure/
  For the methods : https://placeholderart.wordpress.com/2014/12/15/implementing-a-physically-based-camera-automatic-exposure/
  For the logic : https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/Exposure.hlsl
 
  Exposure code from MJP and David Neubelt, copyrighted under MIT License (see EOF)
  And John Hable for the tonemap method from UNCHARTED2
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "PD80 HelperFunctions.fxh"

//// UI ELEMENTS ////////////////////////////////////////////////////////////////
uniform float shoulder <
  ui_label = "A: Adjust Shoulder";
  ui_tooltip = "Highlights";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 5.0;
  > = 0.115;

uniform float linear_str <
  ui_label = "B: Adjust Linear Strength";
  ui_tooltip = "Curve Linearity";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 5.0;
  > = 0.065;

uniform float angle <
  ui_label = "C: Adjust Angle";
  ui_tooltip = "Curve Angle";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 5.0;
  > = 0.43;

uniform float toe <
  ui_label = "D: Adjust Toe";
  ui_tooltip = "Shadows";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 5.0;
  > = 0.65;

uniform float toe_num <
  ui_label = "E: Adjust Toe Numerator";
  ui_tooltip = "Shadow Curve";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 5.0;
  > = 0.07;

uniform float toe_denom <
  ui_label = "F: Adjust Toe Denominator";
  ui_tooltip = "Shadow Curve (must be more than E)";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 5.0;
  > = 0.41;

uniform float white <
  ui_label = "White Level";
  ui_tooltip = "White Limiter";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 20.0;
  > = 1.32;

uniform float exposureMod <
  ui_label = "Exposure";
  ui_tooltip = "Exposure Adjustment";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = -2.0;
  ui_max = 2.0;
  > = 0.0;

uniform float adaptationMin <
  ui_label = "Minimum Exposure Adaptation";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 0.42;

uniform float adaptationMax <
  ui_label = "Maximum Exposure Adaptation";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 0.6;

uniform float setDelay <
  ui_label = "Adaptation Time Delay (sec)";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0.1;
  ui_max = 5.0;
  > = 1.5;

uniform float GreyValue <
  ui_label = "50% Grey Value";
  ui_tooltip = "Target Grey Value used for exposure";
  ui_category = "Tonemapping";
  ui_type = "slider";
  ui_min = 0;
  ui_max = 1;
  > = 0.735;

//// TEXTURES ///////////////////////////////////////////////////////////////////
texture texColorBuffer : COLOR;
texture texDepthBuffer : DEPTH;
texture texLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
texture texAvgLuma { Format = R16F; };
texture texPrevAvgLuma { Format = R16F; };

//// SAMPLERS ///////////////////////////////////////////////////////////////////
sampler samplerColor { Texture = texColorBuffer; };
sampler samplerDepth { Texture = texDepthBuffer; };
sampler samplerLuma { Texture = texLuma; };
sampler samplerAvgLuma { Texture = texAvgLuma; };
sampler samplerPrevAvgLuma { Texture = texPrevAvgLuma; };

//// DEFINES ////////////////////////////////////////////////////////////////////
//See PD80 HelperFunctions.fxh

//// BUFFERS ////////////////////////////////////////////////////////////////////
// Not supported in ReShade (?)

//// FUNCTIONS //////////////////////////////////////////////////////////////////
//See PD80 HelperFunctions.fxh

//// COMPUTE SHADERS ////////////////////////////////////////////////////////////
// Not supported in ReShade (?)

//// PIXEL SHADERS //////////////////////////////////////////////////////////////
float PS_WriteLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float4 color     = tex2D( samplerColor, texcoord );
  float luma       = getMaxLuminance( color.xyz );
  luma             = max( luma, 0.06f ); //hackjob until better solution
  return luma;
}

float PS_AvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float luma       = tex2Dlod( samplerLuma, float4(0.0f, 0.0f, 0, 8 )).x;
  float prevluma   = tex2D( samplerPrevAvgLuma, float2( 0.0f, 0.0f )).x;
  float fps        = 1000.0f / Frametime;
  float delay      = fps * ( setDelay / 2.0f );	
  float avgLuma    = lerp( prevluma, luma, 1.0f / delay );
  return avgLuma;
}

float4 PS_Tonemap(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float4 color     = tex2D( samplerColor, texcoord );
  float lumaMod    = tex2D( samplerAvgLuma, float2( 0.0f, 0.0f )).x;
  lumaMod          = max( lumaMod, adaptationMin );
  lumaMod          = min( lumaMod, adaptationMax );
  color.xyz        = SRGBToLinear( color.xyz );
  color.xyz        = CalcExposedColor( color.xyz, lumaMod, exposureMod, GreyValue );
  color.xyz        = Filmic( color.xyz, shoulder, linear_str, angle, toe, toe_num, toe_denom, white );
  
  return float4( color.xyz, 1.0f );
}

float PS_PrevAvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float avgLuma    = tex2D( samplerAvgLuma, float2( 0.0f, 0.0f )).x;
  return avgLuma;
}

//// TECHNIQUES /////////////////////////////////////////////////////////////////
technique prod80_02_FilmicTonemap
{
  pass Luma
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_WriteLuma;
    RenderTarget   = texLuma;
  }
  pass AvgLuma
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_AvgLuma;
    RenderTarget   = texAvgLuma;
  }
  pass Tonemapping
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_Tonemap;
  }
  pass PreviousLuma
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_PrevAvgLuma;
    RenderTarget   = texPrevAvgLuma;
  }
}

//Exposure code
//=================================================================================================
//
//  Baking Lab
//  by MJP and David Neubelt
//  http://mynameismjp.wordpress.com/
//
//  All code licensed under the MIT license
//
//=================================================================================================

