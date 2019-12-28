/* 
 Color Effects, Contrasts, and Brightness by prod80 for ReShade
 Version 5.0
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "PD80 HelperFunctions.fxh"

//// UI ELEMENTS ////////////////////////////////////////////////////////////////
//Kelvin
uniform bool enableKelvin <
  ui_label = "Enable Color Temp (K)";
  ui_category = "Kelvin";
  > = false;

uniform uint Kelvin <
  ui_label = "Color Temp (K)";
  ui_category = "Kelvin";
  ui_min = 1000;
  ui_max = 40000;
  > = 6500;

uniform float LumPreservation <
  ui_label = "Luminance Preservation";
  ui_category = "Kelvin";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 1.0;

uniform float kMix <
  ui_label = "Mix with Original";
  ui_category = "Kelvin";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 1.0;

//Levels
uniform bool enableLevels <
  ui_label = "Enable Levels";
  ui_category = "Levels";
  > = true;

uniform float3 inBlackRGB <
  ui_type = "color";
  ui_label = "Black IN";
  ui_category = "Levels";
  > = float3(0.0, 0.0, 0.0);

uniform float3 inWhiteRGB <
  ui_type = "color";
  ui_label = "White IN";
  ui_category = "Levels";
  > = float3(1.0, 1.0, 1.0);

uniform bool enableLumaOutBlack <
  ui_label = "Allow average scene luminosity to influence Black OUT.\nWhen NOT selected Black OUT minimum is ignored.";
  ui_category = "Levels";
  > = true;

uniform float3 outBlackRGBmin <
  ui_type = "color";
  ui_label = "Black OUT minimum";
  ui_category = "Levels";
  > = float3(0.016, 0.016, 0.016);

uniform float3 outBlackRGBmax <
  ui_type = "color";
  ui_label = "Black OUT maximum";
  ui_category = "Levels";
  > = float3(0.036, 0.036, 0.036);

uniform float3 outWhiteRGB <
  ui_type = "color";
  ui_label = "White OUT";
  ui_category = "Levels";
  > = float3(1.0, 1.0, 1.0);

uniform float inGammaGray <
  ui_label = "Gamma Adjustment";
  ui_category = "Levels";
  ui_type = "slider";
  ui_min = 0.05;
  ui_max = 10.0;
  > = 1.0;

//Color Isolation
uniform bool enableColorIso <
  ui_label = "Enable Color Isolation";
  ui_category = "Color Isolation";
  > = false;

uniform float satLimit <
  ui_label = "Saturation Output";
  ui_category = "Color Isolation";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 1.0;

uniform float hueMid <
  ui_label = "Hue Selection (Middle)";
  ui_category = "Color Isolation";
  ui_tooltip = "0 = Red, 0.167 = Yellow, 0.333 = Green, 0.5 = Cyan, 0.666 = Blue, 0.833 = Magenta";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 0.0;

uniform float hueRangeMin <
  ui_label = "Hue Range Below Middle";
  ui_category = "Color Isolation";
  ui_tooltip = "Hues to process below Hue Selection";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 0.75;
  > = 0.333;

uniform float hueRangeMax <
  ui_label = "Hue Range Above Middle";
  ui_category = "Color Isolation";
  ui_tooltip = "Hues to process above Hue Selection";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 0.75;
  > = 0.333;

uniform float fxcolorMix <
  ui_label = "Mix with Original";
  ui_category = "Color Isolation";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 1.0;

//Gradients
uniform bool enableGradients <
  ui_label = "Enable Gradients";
  ui_category = "Gradients";
  > = false;

uniform float3 midcolor <
  ui_type = "color";
  ui_label = "Mid Tone Color";
  ui_category = "Gradients";
  > = float3(1.0, 0.325, 0.0);

uniform float3 shadowcolor <
  ui_type = "color";
  ui_label = "Shadow Color";
  ui_category = "Gradients";
  > = float3(1.0, 0.0, 0.325);

uniform float midpower <
  ui_label = "Mid Tone Color Distribution Curve";
  ui_category = "Gradients";
  ui_type = "slider";
  ui_min = 0.05;
  ui_max = 5.0;
  > = 2.0;

uniform float shadowpower <
  ui_label = "Shadow Color Distribution Curve";
  ui_category = "Gradients";
  ui_type = "slider";
  ui_min = 0.05;
  ui_max = 5.0;
  > = 3.0;

uniform float CGdesat <
  ui_label = "Desaturate Base Image";
  ui_category = "Gradients";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 0.0;

uniform float finalmix <
  ui_label = "Mix with Original";
  ui_category = "Gradients";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 0.333;

//LumaGradients
uniform bool enableLumaGradients <
  ui_label = "Enable Luma Gradients";
  ui_tooltip = "Changes shadow colors based on average scene luminosity";
  ui_category = "Luma Gradients";
  > = false;

uniform float3 LGShadowcolorL <
  ui_type = "color";
  ui_label = "Luminous Scene Shadow Color";
  ui_category = "Luma Gradients";
  > = float3(0.505, 0.483, 0.431);

uniform float3 LGShadowcolorD <
  ui_type = "color";
  ui_label = "Dark Scene Shadow Color";
  ui_category = "Luma Gradients";
  > = float3(0.431, 0.483, 0.505);

uniform float contrast <
  ui_label = "Contrast";
  ui_category = "Final Adjustments";
  ui_type = "slider";
  ui_min = -1.0;
  ui_max = 2.0;
  > = 0.0;

uniform float brightness <
  ui_label = "Brightness";
  ui_category = "Final Adjustments";
  ui_type = "slider";
  ui_min = -1.0;
  ui_max = 2.0;
  > = 0.0;

uniform float saturation <
  ui_label = "Saturation";
  ui_category = "Final Adjustments";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 2.0;
  > = 1.0;


//// TEXTURES ///////////////////////////////////////////////////////////////////
texture texColorBuffer : COLOR;
texture texDepthBuffer : DEPTH;
texture texCLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
texture texCAvgLuma { Format = R16F; };
texture texCPrevAvgLuma { Format = R16F; };

//// SAMPLERS ///////////////////////////////////////////////////////////////////
sampler samplerColor { Texture = texColorBuffer; };
sampler samplerDepth { Texture = texDepthBuffer; };
sampler samplerCLuma { Texture = texCLuma; };
sampler samplerCAvgLuma { Texture = texCAvgLuma; };
sampler samplerCPrevAvgLuma { Texture = texCPrevAvgLuma; };

//// DEFINES ////////////////////////////////////////////////////////////////////
//See PD80 HelperFunctions.fxh

//// BUFFERS ////////////////////////////////////////////////////////////////////
// Not supported in ReShade (?)

//// FUNCTIONS //////////////////////////////////////////////////////////////////
//See PD80 HelperFunctions.fxh

//// COMPUTE SHADERS ////////////////////////////////////////////////////////////
// Not supported in ReShade (?)

//// PIXEL SHADERS //////////////////////////////////////////////////////////////
float PS_WriteCLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float4 color     = tex2D( samplerColor, texcoord );
  color.xyz        = SRGBToLinear( color.xyz );
  float luma       = getLuminance( color.xyz );
  return log2( max( luma, 0.001f ));
}

float PS_AvgCLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float luma       = tex2Dlod( samplerCLuma, float4(0.5f, 0.5f, 0, 8 )).x;
  float prevluma   = tex2D( samplerCPrevAvgLuma, float2( 0.5f, 0.5f )).x;
  luma             = exp2( luma );
  float fps        = 1000.0f / Frametime;
  fps              *= 0.5f; //approx. 1 second delay to change luma between bright and dark
  float avgLuma    = lerp( prevluma, luma, 1.0f / fps ); 
  return avgLuma;
}

float4 PS_CC(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float4 color     = tex2D( samplerColor, texcoord );
  float avgluma    = tex2D( samplerCAvgLuma, float2( 0.5f, 0.5f )).x;

  if( enableKelvin == TRUE )
  {
    float3 kColor  = KelvinToRGB( Kelvin );
    float3 oLum    = RGBToHCV( color.xyz );
    oLum.x         = oLum.z - oLum.y * 0.5f;
    float3 blended = lerp( color.xyz, color.xyz * kColor.xyz, kMix );
    float3 resHSL  = RGBToHSL( blended.xyz );
    float3 resRGB  = HSLToRGB( float3( resHSL.x, resHSL.y, oLum.x ));
    color.xyz      = lerp( blended.xyz, resRGB.xyz, LumPreservation );
  }
  
  if( enableLevels == TRUE )
  {
    color.xyz      = max( color.xyz - inBlackRGB.xyz, 0.0f )/max( inWhiteRGB.xyz - inBlackRGB.xyz, 0.000001f );
    color.xyz      = pow( color.xyz, inGammaGray );
    float3 outBlack= outBlackRGBmax.xyz;
    if( enableLumaOutBlack == TRUE )
      outBlack.xyz = lerp( outBlackRGBmin.xyz, outBlackRGBmax.xyz, avgluma );
    color.xyz      = color.xyz * max( outWhiteRGB.xyz - outBlack.xyz, 0.000001f ) + outBlack.xyz;
    color.xyz      = max( color.xyz, 0.0f );
  }
 
  if( enableColorIso == TRUE )
  {
    color.xyz      = saturate( color.xyz ); //Can't work with HDR
    float ci_gray  = getLuminance( color.xyz );
    float ci_hue   = RGBToHSL( color.xyz ).x;
    float2 limit   = float2( hueMid - hueRangeMin, hueMid + hueRangeMax );
    float3 new_c   = 0.0f;
    if( limit.y > 1.0f && ci_hue < limit.y - 1.0f )
      ci_hue       += 1;
    if( limit.x < 0.0f && ci_hue > limit.x + 1.0f )
      ci_hue       -= 1;
    if( ci_hue < hueMid )
      new_c.xyz    = lerp( ci_gray, color.xyz, smootherstep( limit.x, hueMid, ci_hue ) * satLimit );
    if( ci_hue >= hueMid )
      new_c.xyz    = lerp( ci_gray, color.xyz, ( 1.0f - smootherstep( hueMid, limit.y, ci_hue )) * satLimit );
    color.xyz      = lerp( color.xyz, new_c.xyz, fxcolorMix );
  }
  
  if( enableGradients == TRUE )
  {
    color.xyz      = saturate( color.xyz );
    float avgcolor = getLuminance( color.xyz );
    float low      = pow( 1.0f - avgcolor, shadowpower );
    float high     = pow( avgcolor, midpower );
    float mid      = saturate( 1.0f - low - high );
    float3 midC    = RGBToHSL( midcolor.xyz );
    float3 shaC    = RGBToHSL( shadowcolor.xyz );
    midC.xyz       = HSLToRGB( float3( midC.xy, avgcolor ));
    shaC.xyz       = HSLToRGB( float3( shaC.xy, avgcolor ));
    float3 CG      = shaC.xyz * low + midC.xyz * mid + high;
    color.xyz      = lerp( lerp( color.xyz, avgcolor, CGdesat ), CG.xyz, finalmix );
  }
 
  if( enableLumaGradients == TRUE )
  {
    color.xyz      = saturate( color.xyz );
    float LGlum    = Luminance( color.xyz );
    float3 LGlum1  = RGBToHCV( color.xyz );
    LGlum1.x       = LGlum1.z - LGlum1.y * 0.5f;
    float3 LGShadowD = overlay( color.xyz, LGShadowcolorD.xyz );
    LGShadowD.xyz  = RGBToHSL( LGShadowD.xyz );
    LGShadowD.xyz  = HSLToRGB( float3( LGShadowD.xy, LGlum1.x ));
    LGShadowD.xyz  = lerp( LGShadowD.xyz, color.xyz, LGlum );
    float3 LGShadowL = overlay( color.xyz, LGShadowcolorL.xyz );
    LGShadowL.xyz  = RGBToHSL( LGShadowL.xyz );
    LGShadowL.xyz  = HSLToRGB( float3( LGShadowL.xy, LGlum1.x ));
    LGShadowL.xyz  = lerp( LGShadowL.xyz, color.xyz, LGlum );
    color.xyz      = lerp( LGShadowD.xyz, LGShadowL.xyz, avgluma );
  }
  
 
  color.xyz        = saturate( lerp( color.xyz, softlight( color.xyz, color.xyz ), contrast ));
  color.xyz        = saturate( lerp( color.xyz, screen( color.xyz, color.xyz ), brightness ));
  float4 sat       = 0.0f;
  sat.xy           = float2( min( min( color.x, color.y ), color.z ), max( max( color.x, color.y ), color.z ));
  sat.z            = sat.y - sat.x;
  sat.w            = getLuminance( color.xyz );
  float3 min_sat   = lerp( sat.w, color.xyz, saturation );
  float3 max_sat   = lerp( sat.w, color.xyz, 1.0f + ( saturation - 1.0f ) * ( 1.0f - sat.z ));
  float3 neg       = min( max_sat.xyz + 1.0f, 1.0f );
  neg.xyz          = saturate( 1.0f - neg.xyz );
  float negsum     = dot( neg.xyz, 1.0f );
  max_sat.xyz      = max( max_sat.xyz, 0.0f );
  max_sat.xyz      = max_sat.xyz + saturate(sign( max_sat.xyz )) * negsum.xxx;
  color.xyz        = saturate( lerp( min_sat.xyz, max_sat.xyz, step( 1.0f, saturation )));
  return float4( color.xyz, 1.0f );
}

float PS_PrevAvgCLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float avgLuma    = tex2D( samplerCAvgLuma, float2( 0.5f, 0.5f )).x;
  return avgLuma;
}

//// TECHNIQUES /////////////////////////////////////////////////////////////////
technique prod80_03_CurvesColors
{
  pass CLuma
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_WriteCLuma;
    RenderTarget   = texCLuma;
  }
  pass AvgCLuma
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_AvgCLuma;
    RenderTarget   = texCAvgLuma;
  }
  pass CurvesAndColors
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_CC;
  }
  pass PreviousCLuma
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_PrevAvgCLuma;
    RenderTarget   = texCPrevAvgLuma;
  }
}
