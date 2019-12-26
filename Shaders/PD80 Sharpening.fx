/* 
 Luma Sharpening by prod80 for ReShade
 Version 4.0
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "PD80 HelperFunctions.fxh"

//// UI ELEMENTS ////////////////////////////////////////////////////////////////
uniform bool enableShowEdges <
  ui_label = "Show only Sharpening Texture";
  ui_category = "Sharpening";
  > = false;

uniform float BlurSigma <
  ui_label = "Sharpening Width";
  ui_category = "Sharpening";
  ui_type = "slider";
  ui_min = 0.3;
  ui_max = 2.0;
  > = 0.45;
  
uniform float Sharpening <
  ui_label = "Sharpening Strength";
  ui_category = "Sharpening";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 5.0;
  > = 1.7;
  
uniform float Threshold <
  ui_label = "Sharpening Threshold";
  ui_category = "Sharpening";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 0.0;
  
uniform float limiter <
  ui_label = "Sharpening Highlight Limiter";
  ui_category = "Sharpening";
  ui_type = "slider";
  ui_min = 0.0;
  ui_max = 1.0;
  > = 0.03;

//// TEXTURES ///////////////////////////////////////////////////////////////////
texture texColorBuffer : COLOR;
texture texDepthBuffer : DEPTH;
texture texGaussianH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; }; 
texture texGaussian { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };

//// SAMPLERS ///////////////////////////////////////////////////////////////////
sampler samplerColor { Texture = texColorBuffer; };
sampler samplerDepth { Texture = texDepthBuffer; };
sampler samplerGaussianH { Texture = texGaussianH; };
sampler samplerGaussian { Texture = texGaussian; };

//// DEFINES ////////////////////////////////////////////////////////////////////
//See PD80 HelperFunctions.fxh

//// BUFFERS ////////////////////////////////////////////////////////////////////
// Not supported in ReShade (?)

//// FUNCTIONS //////////////////////////////////////////////////////////////////
//See PD80 HelperFunctions.fxh

//// COMPUTE SHADERS ////////////////////////////////////////////////////////////
// Not supported in ReShade (?)

//// PIXEL SHADERS //////////////////////////////////////////////////////////////

float4 PS_GaussianH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float4 color     = tex2D( samplerColor, texcoord );
  float px         = 1.0f / BUFFER_WIDTH;
  float SigmaSum   = 0.0f;
  float pxlOffset  = 1.0f;
 
  //Gaussian Math
  float3 Sigma;
  Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * BlurSigma );
  Sigma.y          = exp( -0.5f / ( BlurSigma * BlurSigma ));
  Sigma.z          = Sigma.y * Sigma.y;
 
  //Center Weight
  color.xyz        *= Sigma.x;
  //Adding to total sum of distributed weights
  SigmaSum         += Sigma.x;
  //Setup next weight
  Sigma.xy         *= Sigma.yz;
 
  for( int i = 0; i < 7; ++i )
  {
    color          += tex2D( samplerColor, texcoord.xy + float2( pxlOffset*px, 0.0f )) * Sigma.x;
    color          += tex2D( samplerColor, texcoord.xy - float2( pxlOffset*px, 0.0f )) * Sigma.x;
    SigmaSum       += ( 2.0f * Sigma.x );
    pxlOffset      += 1.0f;
    Sigma.xy       *= Sigma.yz;
  }
 
  color.xyz        /= SigmaSum;
  return float4( color.xyz, 1.0f );
}

float4 PS_GaussianV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float4 color     = tex2D( samplerGaussianH, texcoord );
  float py         = 1.0f / BUFFER_HEIGHT;
  float SigmaSum   = 0.0f;
  float pxlOffset  = 1.0f;
 
  //Gaussian Math
  float3 Sigma;
  Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * BlurSigma );
  Sigma.y          = exp( -0.5f / ( BlurSigma * BlurSigma ));
  Sigma.z          = Sigma.y * Sigma.y;
 
  //Center Weight
  color.xyz        *= Sigma.x;
  //Adding to total sum of distributed weights
  SigmaSum         += Sigma.x;
  //Setup next weight
  Sigma.xy         *= Sigma.yz;
 
  for( int i = 0; i < 7; ++i )
  {
    color          += tex2D( samplerGaussianH, texcoord.xy + float2( 0.0f, pxlOffset*py )) * Sigma.x;
    color          += tex2D( samplerGaussianH, texcoord.xy - float2( 0.0f, pxlOffset*py )) * Sigma.x;
    SigmaSum       += ( 2.0f * Sigma.x );
    pxlOffset      += 1.0f;
    Sigma.xy       *= Sigma.yz;
  }
 
  color.xyz        /= SigmaSum;
  return float4( color.xyz, 1.0f );
}

float4 PS_LumaSharpen(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
  float4 orig      = tex2D( samplerColor, texcoord );
  float4 gaussian  = tex2D( samplerGaussian, texcoord );
  float3 edges     = max( saturate( orig.xyz - gaussian.xyz ) - Threshold, 0.0f );
  float3 invGauss  = saturate( 1.0f - gaussian.xyz );
  float3 oInvGauss = saturate( orig.xyz + invGauss.xyz );
  float3 invOGauss = max( saturate( 1.0f - oInvGauss.xyz ) - Threshold, 0.0f );
  edges            = max(( saturate( Sharpening * edges.xyz )) - ( saturate( Sharpening * invOGauss.xyz )), 0.0f );
  float3 blend     = saturate( orig.xyz + min( edges.xyz, limiter ));
  float3 color     = BlendLuma( orig.xyz, blend.xyz ); 
  if( enableShowEdges == TRUE )
    color.xyz      = min( edges.xyz, limiter );
  
  return float4( color.xyz, 1.0f );
}

//// TECHNIQUES /////////////////////////////////////////////////////////////////
technique prod80_04_LumaSharpen
{
  pass GaussianH
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_GaussianH;
    RenderTarget   = texGaussianH;
  }
  pass GaussianV
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_GaussianV;
    RenderTarget   = texGaussian;
  }
  pass LumaSharpen
  {
    VertexShader   = PostProcessVS;
    PixelShader    = PS_LumaSharpen;
  }
}



