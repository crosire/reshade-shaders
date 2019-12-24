/* 
 prod80 Shaders : Helper Functions
 Required for PD80 effects
*/

#define LumCoeff float3(0.212656, 0.715158, 0.072186)
#define Q 0.985f //Used for Bloom. High Quality. Other options 1.0 (not recommended), 0.99999f (no compromise), 0.8, or 0.6 (lower is less)
#define PI 3.141592f
#define LOOPCOUNT 150f

uniform float Timer < source = "timer"; >;
uniform int drandom < source = "random"; min = 0; max = 32767; >;
uniform float Frametime < source = "frametime"; >;

float rand( in float x )
{
  return frac(x / 41.0f);
}

float permute( in float x )
{
  return ((34.0f * x + 1.0f) * x) % 289.0f;
}

float getLuminance( in float3 x )
{
  return dot( x, LumCoeff );
}

float getMaxLuminance( in float3 x )
{
  return max( max( x.x, x.y ), x.z );
}

float Luminance( in float3 c )
{
  float fmin       = min( min( c.r, c.g ), c.b );
  float fmax       = max( max( c.r, c.g ), c.b );
  return ( fmax + fmin ) / 2.0f;
}

float3 KelvinToRGB( in float k )
{
  float3 ret;
  float kelvin     = clamp( k, 1000.0f, 40000.0f ) / 100.0f;
  if( kelvin <= 66.0f )
  {
    ret.r          = 1.0f;
    ret.g          = saturate( 0.39008157876901960784f * log( kelvin ) - 0.63184144378862745098f );
  }
  else
  {
    float t        = kelvin - 60.0f;
    ret.r          = saturate( 1.29293618606274509804f * pow( t, -0.1332047592f ));
    ret.g          = saturate( 1.12989086089529411765f * pow( t, -0.0755148492f ));
  }
  if( kelvin >= 66.0f )
    ret.b          = 1.0f;
  else if( kelvin < 19.0f )
    ret.b          = 0.0f;
  else
    ret.b          = saturate( 0.54320678911019607843f * log( kelvin - 10.0f ) - 1.19625408914f );
  return ret;
}

float3 HUEToRGB( in float H )
{
  float R          = abs(H * 6.0f - 3.0f) - 1.0f;
  float G          = 2.0f - abs(H * 6.0f - 2.0f);
  float B          = 2.0f - abs(H * 6.0f - 4.0f);
  return saturate( float3( R,G,B ));
}

float3 RGBToHCV( in float3 RGB )
{
  // Based on work by Sam Hocevar and Emil Persson
  float4 P         = ( RGB.g < RGB.b ) ? float4( RGB.bg, -1.0f, 2.0f/3.0f ) : float4( RGB.gb, 0.0f, -1.0f/3.0f );
  float4 Q1        = ( RGB.r < P.x ) ? float4( P.xyw, RGB.r ) : float4( RGB.r, P.yzx );
  float C          = Q1.x - min( Q1.w, Q1.y );
  float H          = abs(( Q1.w - Q1.y ) / ( 6 * C + 0.000001f ) + Q1.z );
  return float3( H, C, Q1.x );
}

float3 RGBToHSL( in float3 RGB )
{
  RGB.xyz          = max( RGB.xyz, 0.000001f );
  float3 HCV       = RGBToHCV(RGB);
  float L          = HCV.z - HCV.y * 0.5f;
  float S          = HCV.y / ( 1.0f - abs( L * 2.0f - 1.0f ) + 0.000001f);
  return float3( HCV.x, S, L );
}

float3 HSLToRGB( in float3 HSL )
{
  float3 RGB       = HUEToRGB(HSL.x);
  float C          = (1.0f - abs(2.0f * HSL.z - 1)) * HSL.y;
  return ( RGB - 0.5f ) * C + HSL.z;
}

float3 LinearTosRGB( in float3 color )
{
  float3 x         = color * 12.92f;
  float3 y         = 1.055f * pow( saturate( color ), 1.0f / 2.4f ) - 0.055f;
  float3 clr       = color;
  clr.r            = color.r < 0.0031308f ? x.r : y.r;
  clr.g            = color.g < 0.0031308f ? x.g : y.g;
  clr.b            = color.b < 0.0031308f ? x.b : y.b;
  return clr;
}

float3 SRGBToLinear( in float3 color )
{
  float3 x         = color / 12.92f;
  float3 y         = pow( max(( color + 0.055f ) / 1.055f, 0.0f ), 2.4f );
  float3 clr       = color;
  clr.r            = color.r <= 0.04045f ? x.r : y.r;
  clr.g            = color.g <= 0.04045f ? x.g : y.g;
  clr.b            = color.b <= 0.04045f ? x.b : y.b;
  return clr;
}

float Log2Exposure( in float avgLuminance, in float GreyValue )
{
  float exposure   = 0.0f;
  avgLuminance     = max(avgLuminance, 0.000001f);
  // GreyValue should be 0.148 based on https://placeholderart.wordpress.com/2014/11/21/implementing-a-physically-based-camera-manual-exposure/
  // But more success using higher values >= 0.5
  float linExp     = GreyValue / avgLuminance;
  exposure         = log2( linExp );
  return exposure;
}

float3 CalcExposedColor( in float3 color, in float avgLuminance, in float offset, in float GreyValue )
{
  float exposure   = Log2Exposure( avgLuminance, GreyValue );
  exposure         += offset; //offset = exposure
  return exp2( exposure ) * color;
}

float3 Filmic( in float3 Fc, in float FA, in float FB, in float FC, in float FD, in float FE, in float FF, in float FWhite )
{
  float3 num       = (( Fc * ( FA * Fc + FC * FB ) + FD * FE ) / ( Fc * ( FA * Fc + FB ) + FD * FF )) - FE / FF;
  float3 denom     = (( FWhite * ( FA * FWhite + FC * FB ) + FD * FE ) / ( FWhite * ( FA * FWhite + FB ) + FD * FF )) - FE / FF;
  return LinearTosRGB( num / denom );
}

float3 BlendLuma( in float3 base, in float3 blend )
{
  float3 HSLBase   = RGBToHSL( base );
  float3 HSLBlend  = RGBToHSL( blend );
  return HSLToRGB( float3( HSLBase.x, HSLBase.y, HSLBlend.z ));
}

float3 screen( in float3 c, in float3 b )
{ 
  return 1.0f - ( 1.0f - c ) * ( 1.0f - b );
}

float3 softlight( in float3 c, in float3 b )
{
  return b < 0.5f ? ( 2.0f * c * b + c * c * ( 1.0f - 2.0f * b )) : ( sqrt( c ) * ( 2.0f * b - 1.0f ) + 2.0f * c * ( 1.0f - b ));
}

float3 overlay( in float3 c, in float3 b )
{
  return c < 0.5f ? 2.0f * c * b : ( 1.0f - 2.0f * ( 1.0f - c ) * ( 1.0f - b ));
}

float smootherstep( in float edge0, in float edge1, in float x )
{
   x               = clamp(( x - edge0 ) / ( edge1 - edge0 ), 0.0f, 1.0f );
   return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
}
