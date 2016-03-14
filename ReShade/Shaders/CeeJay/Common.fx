#ifndef INCLUDE_GUARD_CEEJAY_COMMON
#define INCLUDE_GUARD_CEEJAY_COMMON

  /*-----------------------.
  | ::     Textures     :: |
  '-----------------------*/

namespace CeeJay
{

#if (USE_SMAA == 1)

texture edgesTex
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = R8G8B8A8; //R8G8 is also an option  
};

texture blendTex
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = R8G8B8A8;
};

texture areaTex < string source = "ReShade/Shaders/CeeJay/Textures/SMAA_AreaTex.dds"; >
{
	Width = 160;
	Height = 560;
	Format = R8G8;
};

texture searchTex < string source = "ReShade/Shaders/CeeJay/Textures/SMAA_SearchTex.dds"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};

#endif 

}

  /*-----------------------.
  | ::     Samplers     :: |
  '-----------------------*/

namespace CeeJay
{

sampler colorLinearSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = true;
};

sampler BorderSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Border; AddressV = Border;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; //Why Mipfilter linear - shouldn't point be fine?
	SRGBTexture = false;
};

#if (USE_SMAA == 1)
sampler edgesSampler
{
	Texture = edgesTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler blendSampler
{
	Texture = blendTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler areaSampler
{
	Texture = areaTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};

sampler searchSampler
{
	Texture = searchTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
	SRGBTexture = false;
};

#endif

}

#define predicationSampler ReShade::OriginalDepth //Use the depth sampler as our predication sampler

  /*-----------------------.
  | ::     Effects      :: |
  '-----------------------*/

#define px BUFFER_RCP_WIDTH
#define py BUFFER_RCP_HEIGHT

#define s0 ReShade::BackBuffer
#define s1 colorLinearSampler
#define myTex2D tex2D 

  /*-----------------------.
  | ::     Uniforms     :: |
  '-----------------------*/
//uniform float2 pingpong < source = "pingpong"; min = -1; max = 2; step = 2; >;
//uniform int framecount < source = "framecount"; >; // Total amount of frames since the game started.

//included main file to check for shared shaders in use

  /*----------------------.
  | ::   Shared Pass   :: |
  '----------------------*/

#if (USE_LEVELS == 1)
  #include "SharedShader\Levels.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_TECHNICOLOR == 1)
  #include "SharedShader\Technicolor.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_TECHNICOLOR2 == 1)
  #include "SharedShader\Technicolor2.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_DPX == 1)
  #include "SharedShader\DPX.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_MONOCHROME == 1)
  #include "SharedShader\Monochrome.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_COLORMATRIX == 1)
  #include "SharedShader\ColorMatrix.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_LIFTGAMMAGAIN == 1)
  #include "SharedShader\LiftGammaGain.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_TONEMAP == 1)
  #include "SharedShader\Tonemap.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_VIBRANCE == 1)
  #include "SharedShader\Vibrance.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_CURVES == 1)
  #include "SharedShader\Curves.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_SEPIA == 1)
  #include "SharedShader\Sepia.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_FILMICPASS == 1)
  #include "SharedShader\FilmicPass.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_REINHARDLINEAR == 1)
  #include "SharedShader\ReinhardLinear.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_NOSTALGIA == 1)
  #include "SharedShader\Nostalgia.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_VIGNETTE == 1)
  #include "SharedShader\Vignette.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_FILMGRAIN == 1)
  #include "SharedShader\FilmGrain.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_DITHER == 1)
  #include "SharedShader\Dither.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

#if (USE_BORDER == 1)
  #include "SharedShader\Border.h"
  #undef CeeJay_SHARED
  #define CeeJay_SHARED 1
#endif

  /*----------------------------------.
  | :: Begin operation "Piggyback" :: |
  '----------------------------------*/
// Operation "Piggyback" is where we track what pass came before the shared pass,
// so it can piggyback on the previous pass instead of running in it's own -
// thus avoid the overhead of another pass and increasing performance.
// PIGGY_COUNT_PING needs to initially count all shaders that are able to piggyback

#define CeeJay_PIGGY_COUNT_PING (USE_ASCII + USE_CARTOON + USE_EXPLOSION + USE_CA + USE_ADVANCED_CRT + USE_PIXELART_CRT + USE_BLOOM + USE_HDR + USE_LUMASHARPEN + USE_LENS_DISTORTION + USE_SMAA + USE_FXAA - 1)

#if (CeeJay_PIGGY_COUNT_PING == -1)
	#define CeeJay_PIGGY 0
#else
	#define CeeJay_PIGGY -1 //If you dont want to use piggyback, set to 0
#endif

  /*--------------------.
  | ::     SMAA      :: |
  '--------------------*/
  
  //TODO Move SMAA Wrappers to seperate file

#if (USE_SMAA == 1)

  #define SMAA_RT_METRICS float4(ReShade::PixelSize, ReShade::ScreenSize) //let SMAA know the size of a pixel and the screen
  
  //#define SMAA_HLSL_3 1
  #define SMAA_CUSTOM_SL 1 //our own reshade branch
  
  #define SMAA_PIXEL_SIZE pixel
  #define SMAA_PRESET_CUSTOM 1

  #include "SMAA.h"
#endif

  /*--------------------.
  | ::     FXAA      :: |
  '--------------------*/

#if (USE_FXAA == 1)

  #define FXAA_PC 1
  #define FXAA_HLSL_3 1
  #define FXAA_GREEN_AS_LUMA 1 //It's better to calculate luma in the previous pass and pass it, than to use this option.

  #include "Fxaa3_11.h"
#endif

#endif
