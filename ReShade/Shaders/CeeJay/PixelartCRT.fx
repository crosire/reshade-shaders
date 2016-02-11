#include "Common.fx"
#include CeeJay_SETTINGS_DEF

#if (USE_PIXELART_CRT == 1)

//
// PUBLIC DOMAIN CRT STYLED SCAN-LINE SHADER
//
//   by Timothy Lottes
//
// This is more along the style of a really good CGA arcade monitor.
// With RGB inputs instead of NTSC.
// The shadow mask example has the mask rotated 90 degrees for less chromatic aberration.
//
// Left it unoptimized to show the theory behind the algorithm.
//
// It is an example what I personally would want as a display option for pixel art games.
// Please take and use, change, or whatever.
//

//Ported to HLSL by CeeJay.dk

namespace CeeJay
{

#if PixelArtCRT_resolution_mode != 1
  #define res PixelArtCRT_fixed_resolution // Fix resolution to set amount.
#else
  #define res (ReShade::ScreenSize * PixelArtCRT_resolution_ratio) // Optimize for resize.
#endif

// Nearest emulated sample given floating point position and texel offset.
// Also zero's off screen.
float3 Fetch(float2 pos,float2 off)
{
  pos=floor(pos*res+off)/res;
  if(max(abs(pos.x-0.5),abs(pos.y-0.5))>0.5) return float3(0.0,0.0,0.0);
	return myTex2D(s1,float2(pos.x,pos.y)).rgb; //s1 is linear
}

// Distance in emulated pixels to nearest texel.
float2 Dist(float2 pos){pos=pos*res;return -((pos-floor(pos))- float2(0.5,0.5));}

// Try different filter kernels.
float Gaus(float pos,float scale)
{
	return exp2(scale*pow(abs(pos),PixelArtCRT_shape));
}

// 3-tap Gaussian filter along horz line.
float3 Horz3(float2 pos,float off)
{
  float3 b=Fetch(pos,float2(-1.0,off));
  float3 c=Fetch(pos,float2( 0.0,off));
  float3 d=Fetch(pos,float2( 1.0,off));
  float dst=Dist(pos).x;
  // Convert distance to weight.
  float scale=PixelArtCRT_hardPix;
  float wb=Gaus(dst-1.0,scale);
  float wc=Gaus(dst+0.0,scale);
  float wd=Gaus(dst+1.0,scale);
  // Return filtered sample.
  return (b*wb+c*wc+d*wd)/(wb+wc+wd);
}

// 5-tap Gaussian filter along horz line.
float3 Horz5(float2 pos,float off)
{
  float3 a=Fetch(pos,float2(-2.0,off));
  float3 b=Fetch(pos,float2(-1.0,off));
  float3 c=Fetch(pos,float2( 0.0,off));
  float3 d=Fetch(pos,float2( 1.0,off));
  float3 e=Fetch(pos,float2( 2.0,off));
  float dst=Dist(pos).x;
  // Convert distance to weight.
  float scale=PixelArtCRT_hardPix;
  float wa=Gaus(dst-2.0,scale);
  float wb=Gaus(dst-1.0,scale);
  float wc=Gaus(dst+0.0,scale);
  float wd=Gaus(dst+1.0,scale);
  float we=Gaus(dst+2.0,scale);
  // Return filtered sample.
  return (a*wa+b*wb+c*wc+d*wd+e*we)/(wa+wb+wc+wd+we);
}

// 7-tap Gaussian filter along horz line.
float3 Horz7(float2 pos,float off){
  float3 a=Fetch(pos,float2(-3.0,off));
  float3 b=Fetch(pos,float2(-2.0,off));
  float3 c=Fetch(pos,float2(-1.0,off));
  float3 d=Fetch(pos,float2( 0.0,off));
  float3 e=Fetch(pos,float2( 1.0,off));
  float3 f=Fetch(pos,float2( 2.0,off));
  float3 g=Fetch(pos,float2( 3.0,off));
  float dst=Dist(pos).x;
  // Convert distance to weight.
  float scale=PixelArtCRT_hardPix;
  float wa=Gaus(dst-3.0,scale);
  float wb=Gaus(dst-2.0,scale);
  float wc=Gaus(dst-1.0,scale);
  float wd=Gaus(dst+0.0,scale);
  float we=Gaus(dst+1.0,scale);
  float wf=Gaus(dst+2.0,scale);
  float wg=Gaus(dst+3.0,scale);
  // Return filtered sample.
  return (a*wa+b*wb+c*wc+d*wd+e*we+f*wf+g*wg)/(wa+wb+wc+wd+we+wf+wg);}

// Return scanline weight.
float Scan(float2 pos,float off){
  float dst=Dist(pos).y;
  return Gaus(dst+off,PixelArtCRT_hardScan);}

// Allow nearest three lines to effect pixel.
float3 Tri(float2 pos){
  float3 a=Horz5(pos,-2.0);
  float3 b=Horz7(pos,-1.0);
  float3 c=Horz7(pos, 0.0);
  float3 d=Horz7(pos, 1.0);
  float3 e=Horz5(pos, 2.0);
  float wa=Scan(pos,-2.0);
  float wb=Scan(pos,-1.0);
  float wc=Scan(pos, 0.0);
  float wd=Scan(pos, 1.0);
  float we=Scan(pos, 2.0);
  return (a*wa+b*wb+c*wc+d*wd+e*we)*PixelArtCRT_overdrive;}

// Distortion of scanlines, and end of screen alpha.
float2 Warp(float2 pos){
  pos=pos*2.0-1.0;    
  pos*=float2(1.0+(pos.y*pos.y)*PixelArtCRT_warp.x,1.0+(pos.x*pos.x)*PixelArtCRT_warp.y);
  return pos*0.5+0.5;}

#if PixelArtCRT_ShadowMask == 1
// Very compressed TV style shadow mask.
float3 Mask(float2 pos){
  float scanline = PixelArtCRT_maskLight; //line is a hlsl keyword - had to rename it
  float odd=0.0;
  if(frac(pos.x/6.0)<0.5)odd=1.0;
  if(frac((pos.y+odd)/2.0)<0.5)scanline=PixelArtCRT_maskDark;  
  pos.x=frac(pos.x/3.0);
  float3 mask=float3(PixelArtCRT_maskDark,PixelArtCRT_maskDark,PixelArtCRT_maskDark);
  if(pos.x<0.333)mask.r=PixelArtCRT_maskLight;
  else if(pos.x<0.666)mask.g=PixelArtCRT_maskLight;
  else mask.b=PixelArtCRT_maskLight;
  mask*=scanline;
  return mask;}        

#elif PixelArtCRT_ShadowMask == 2	
// Aperture-grille.
float3 Mask(float2 pos){
  pos.x=frac(pos.x/3.0);
  float3 mask=float3(PixelArtCRT_maskDark,PixelArtCRT_maskDark,PixelArtCRT_maskDark);
  if(pos.x<0.333)mask.r=PixelArtCRT_maskLight;
  else if(pos.x<0.666)mask.g=PixelArtCRT_maskLight;
  else mask.b=PixelArtCRT_maskLight;
  return mask;}        

#elif PixelArtCRT_ShadowMask == 3	 //has bugs - probably because of the directx half-pixel issue - coords need to be adjusted
// Stretched VGA style shadow mask (same as prior shaders).
float3 Mask(float2 pos){
  pos.x+=pos.y*3.0;
  float3 mask=float3(PixelArtCRT_maskDark,PixelArtCRT_maskDark,PixelArtCRT_maskDark);
  pos.x=frac(pos.x/6.0);
  if(pos.x<0.333)mask.r=PixelArtCRT_maskLight;
  else if(pos.x<0.666)mask.g=PixelArtCRT_maskLight;
  else mask.b=PixelArtCRT_maskLight;
  return mask;}    

// #if PixelArtCRT_ShadowMask == 4	
#else
// VGA style shadow mask.
float3 Mask(float2 pos){
  pos.xy=floor(pos.xy*float2(1.0,0.5));
  pos.x+=pos.y*3.0;
  float3 mask=float3(PixelArtCRT_maskDark,PixelArtCRT_maskDark,PixelArtCRT_maskDark);
  pos.x=frac(pos.x/6.0);
  if(pos.x<0.333)mask.r=PixelArtCRT_maskLight;
  else if(pos.x<0.666)mask.g=PixelArtCRT_maskLight;
  else mask.b=PixelArtCRT_maskLight;
  return mask;}    
#endif

float4 PixelArtCRTPass( float4 colorInput, float2 pos )
{
// Entry.
  //float3 color = myTex2D(s0,float2(pos.x,pos.y)).rgb; //testing
  float3 color = Tri(pos);
  
  color *= Mask(pos*ReShade::ScreenSize); //apply shadow mask

  colorInput.rgb = color;
  return saturate(colorInput);
}

float3 PixelArtCRTWrap(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float4 color = myTex2D(s0, texcoord);

	color = PixelArtCRTPass(color,texcoord);

#if (CeeJay_PIGGY == 1)
	#undef CeeJay_PIGGY
	color.rgb = (color.rgb <= 0.0031308) ? saturate(abs(color.rgb) * 12.92) : 1.055 * saturate(pow(abs(color.rgb), 1.0/2.4 )) - 0.055; // Linear to SRGB

	color.rgb = SharedPass(texcoord, float4(color.rgbb)).rgb;
#endif

	return color.rgb;
}

technique Pixelart_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = PixelArt_ToggleKey; >
{
	pass
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PixelArtCRTWrap;
		
	#if (CeeJay_PIGGY == 1)
		SRGBWriteEnable = false;
	#else
		SRGBWriteEnable = true; //PixelArtCRT uses linear so we must convert to gamma again
	#endif
	}
}

#undef res //variable name used also in other shaders and not covered with namespaces

}

#include "ReShade\Shaders\CeeJay\PiggyCount.h"
#endif

#include CeeJay_SETTINGS_UNDEF
