//Stuff all/most of SweetFX shared shaders need
NAMESPACE_ENTER(SFX)
#define SFX_SETTINGS_DEF "ReShade/SweetFX.cfg"
#define SFX_SETTINGS_UNDEF "ReShade/SweetFX.undef" 

#include SFX_SETTINGS_DEF 

  /*-----------------------.
  | ::     Textures     :: |
  '-----------------------*/

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

texture areaTex < string source = "ReShade/SweetFX/Textures/SMAA_AreaTex.dds"; >
{
	Width = 160;
	Height = 560;
	Format = R8G8;
};

texture searchTex < string source = "ReShade/SweetFX/Textures/SMAA_SearchTex.dds"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};
#endif 

  /*-----------------------.
  | ::     Samplers     :: |
  '-----------------------*/

sampler colorLinearSampler
{
	Texture = RFX_backbufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = true;
};

sampler BorderSampler
{
	Texture = RFX_backbufferTex;
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

#define predicationSampler RFX_depthColor //Use the depth sampler as our predication sampler

  /*-----------------------.
  | ::     Effects      :: |
  '-----------------------*/

#define px BUFFER_RCP_WIDTH
#define py BUFFER_RCP_HEIGHT

#define s0 RFX_backbufferColor
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
  #include "ReShade\SweetFX\SharedShader\Levels.h"
  #define SFX_SHARED 1
#endif

#if (USE_TECHNICOLOR == 1)
  #include "ReShade\SweetFX\SharedShader\Technicolor.h"
  #define SFX_SHARED 1
#endif

#if (USE_TECHNICOLOR2 == 1)
  #include "ReShade\SweetFX\SharedShader\Technicolor2.h"
  #define SFX_SHARED 1
#endif

#if (USE_DPX == 1)
  #include "ReShade\SweetFX\SharedShader\DPX.h"
  #define SFX_SHARED 1
#endif

#if (USE_MONOCHROME == 1)
  #include "ReShade\SweetFX\SharedShader\Monochrome.h"
  #define SFX_SHARED 1
#endif

#if (USE_COLORMATRIX == 1)
  #include "ReShade\SweetFX\SharedShader\ColorMatrix.h"
  #define SFX_SHARED 1
#endif

#if (USE_LIFTGAMMAGAIN == 1)
  #include "ReShade\SweetFX\SharedShader\LiftGammaGain.h"
  #define SFX_SHARED 1
#endif

#if (USE_TONEMAP == 1)
  #include "ReShade\SweetFX\SharedShader\Tonemap.h"
  #define SFX_SHARED 1
#endif

#if (USE_VIBRANCE == 1)
  #include "ReShade\SweetFX\SharedShader\Vibrance.h"
  #define SFX_SHARED 1
#endif

#if (USE_CURVES == 1)
  #include "ReShade\SweetFX\SharedShader\Curves.h"
  #define SFX_SHARED 1
#endif

#if (USE_SEPIA == 1)
  #include "ReShade\SweetFX\SharedShader\Sepia.h"
  #define SFX_SHARED 1
#endif

#if (USE_FILMICPASS == 1)
  #include "ReShade\SweetFX\SharedShader\FilmicPass.h"
  #define SFX_SHARED 1
#endif

#if (USE_REINHARDLINEAR == 1)
  #include "ReShade\SweetFX\SharedShader\ReinhardLinear.h"
  #define SFX_SHARED 1
#endif

#if (USE_NOSTALGIA == 1)
  #include "ReShade\SweetFX\SharedShader\Nostalgia.h"
  #define SFX_SHARED 1
#endif

#if (USE_VIGNETTE == 1)
  #include "ReShade\SweetFX\SharedShader\Vignette.h"
  #define SFX_SHARED 1
#endif

#if (USE_FILMGRAIN == 1)
  #include "ReShade\SweetFX\SharedShader\FilmGrain.h"
  #define SFX_SHARED 1
#endif

#if (USE_DITHER == 1)
  #include "ReShade\SweetFX\SharedShader\Dither.h"
  #define SFX_SHARED 1
#endif

#if (USE_BORDER == 1)
  #include "ReShade\SweetFX\SharedShader\Border.h"
  #define SFX_SHARED 1
#endif

#if (USE_SPLITSCREEN == 1)
  #include "ReShade\SweetFX\SharedShader\Splitscreen.h"
  #define SFX_SHARED 1
#endif

  /*----------------------------------.
  | :: Begin operation "Piggyback" :: |
  '----------------------------------*/
// Operation "Piggyback" is where we track what pass came before the shared pass,
// so it can piggyback on the previous pass instead of running in it's own -
// thus avoid the overhead of another pass and increasing performance.
// PIGGY_COUNT_PING needs to initially count all shaders that are able to piggyback

#define SFX_PIGGY_COUNT_PING (USE_ASCII + USE_CARTOON + USE_EXPLOSION + USE_CA + USE_ADVANCED_CRT + USE_PIXELART_CRT + USE_BLOOM + USE_HDR + USE_LUMASHARPEN + USE_LENS_DISTORTION + USE_SMAA + USE_FXAA - 1)

#if (SFX_PIGGY_COUNT_PING == -1)
	#define SFX_PIGGY 0
#else
	#define SFX_PIGGY -1 //If you dont want to use piggyback, set to 0
#endif

  /*--------------------.
  | ::     SMAA      :: |
  '--------------------*/
  
  //TODO Move SMAA Wrappers to seperate file

#if (USE_SMAA == 1)

  #define SMAA_RT_METRICS float4(RFX_PixelSize, RFX_ScreenSize) //let SMAA know the size of a pixel and the screen
  
  //#define SMAA_HLSL_3 1
  #define SMAA_CUSTOM_SL 1 //our own reshade branch
  
  #define SMAA_PIXEL_SIZE pixel
  #define SMAA_PRESET_CUSTOM 1

  #include "ReShade\SweetFX\SMAA.h"
#endif

  /*--------------------.
  | ::     FXAA      :: |
  '--------------------*/

#if (USE_FXAA == 1)

  #define FXAA_PC 1
  #define FXAA_HLSL_3 1
  #define FXAA_GREEN_AS_LUMA 1 //It's better to calculate luma in the previous pass and pass it, than to use this option.

  #include "ReShade\SweetFX\Fxaa3_11.h"
#endif

#include SFX_SETTINGS_UNDEF

NAMESPACE_LEAVE()

#pragma message "SweetFX 2.0 by Ceejay.dk\n"
