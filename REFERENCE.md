ReShade FX shading language
===========================

# Contents

* [Concepts](#concepts)
  * [Macros](#macros)
  * [Textures](#textures)
  * [Samplers](#samplers)
  * [Uniforms](#uniforms)
  * [Structs](#structs)
  * [Namespaces](#namespaces)
  * [Functions](#functions)
  * [Techniques](#techniques)

# Concepts

### Macros

* ``__RESHADE__`` Version of the injector
* ``__VENDOR__`` Vendor id
* ``__DEVICE__`` Device id
* ``__RENDERER__`` Renderer version
* ``__APPLICATION__`` Hash of the application executable name
* ``__DATE_YEAR__`` Current year
* ``__DATE_MONTH__`` Current month
* ``__DATE_DAY__`` Current day in month
* ``BUFFER_WIDTH`` Backbuffer width
* ``BUFFER_HEIGHT`` Backbuffer height
* ``BUFFER_RCP_WIDTH`` Reciprocal backbuffer width
* ``BUFFER_RCP_HEIGHT`` Reciprocal backbuffer height

### Textures

> Textures are multidimensional data containers usually used to store images.

Annotations:

 * ``texture imageTex < source = "path/to/image.bmp"; > { ... };``  
 Opens image from the patch specified, resizes it to the texture size and loads it into the texture.

Semantics on textures are used to request special textures:

 * ``texture texColor : COLOR;``  
 Receives the backbuffer contents (read-only).
 * ``texture texDepth : DEPTH;``  
 Receives the game's depth information (read-only).

Declared textures are created at runtime with the parameters specified in their definition body.

```c++
texture texColorBuffer : COLOR; // or SV_Target
texture texDepthBuffer : DEPTH; // or SV_Depth

texture texTarget
{
	// The texture dimensions (default: 1x1).
	Width = BUFFER_WIDTH / 2;
	Height = BUFFER_HEIGHT / 2;
	
	// The number of mipmaps including the base level (default: 1).
	MipLevels = 1;
	
	// The internal texture format (default: RGBA8).
	// Available formats:
	//   R8, R16F, R32F
	//   RG8, RG16, RG16F, RG32F
	//   RGBA8, RGBA16, RGBA16F, RGBA32F
	// Available compressed formats (read-only):
	//   DXT1 or BC1, DXT3 or BC2, DXT5 or BC3
	//   LATC1 or BC4, LATC2 or BC5
	Format = RGBA8;

	// The default value is used if an option is missing here.
};
```

### Samplers

> Samplers are the bridge between textures and shaders. They define how a texture is sampled. Multiple samplers can refer to the same texture using different options.

```c++
sampler samplerColor
{
	// The texture to be used for sampling.
	Texture = texColorBuffer;

	// The method used for resolving  texture coordinates which  are outside
	// of bounds.
	// Available values: CLAMP, MIRROR, WRAP or REPEAT, BORDER
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;

	// The magnification, minification and mipmap filtering types.
	// Available values: POINT, LINEAR
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	MipFilter = LINEAR;

	// The maximum mipmap levels accessible.
	MinLOD = 0.0f;
	MaxLOD = 1000.0f;

	// An offset applied to the calculated mipmap level (default: 0).
	MipLODBias = 0.0f;

	// Enable or disable converting  to linear colors when sampling from the
	// texture.
	SRGBTexture = false;

	// Missing options are again set to the defaults shown here.
};
sampler samplerDepth
{
	Texture = texDepthBuffer;
};
sampler samplerTarget
{
	Texture = texTarget;
};
```

### Uniforms

> Uniforms are variables which are constant across each iteration of a shader per pass.

Annotations to customize UI appearance:

 * ui_type - Can be `input`, `drag`, `combo` or `color`
 * ui_min - The smallest value allowed in this variable (required when `ui_type = "drag"`)
 * ui_max - The largest value allowed in this variable (required when `ui_type = "drag"`)
 * ui_items - A list of items for the combo box, each item is terminated with a `\0` character (required when `ui_type = "combo"`)
 * ui_label - Display name of the variable in the UI. If this is missing, the variable name is used instead.
 * ui_tooltip - Text that is displayed when the user hovers over the variable in the UI. Use this for a description.
 * ui_category - Groups values together under a common headline. Note that all variables in the same category also have to be declared next to each other for this to be displayed correctly.

Annotations are also used to request special runtime values:

 * ``uniform float frametime < source = "frametime"; >;``  
 Time in milliseconds it took for the last frame to complete.
 * ``uniform int framecount < source = "framecount"; >;``  
 Total amount of frames since the game started.
 * ``uniform float4 date < source = "date"; >;``  
 float4(year, month (1 - 12), day of month (1 - 31), time in seconds)
 * ``uniform float timer < source = "timer"; >;``  
 Timer counting time in milliseconds since game start.
 * ``uniform float2 pingpong < source = "pingpong"; min = 0; max = 9; step = 1; >;``  
 Counter that counts up and down between min and max using step as increase value. The second component is either +1 or -1 depending on the direction it currently goes.
 * ``uniform int random < source = "random"; min = 0; max = 10; >;``  
 Gets a new random value between min and max every pass.
 * ``uniform bool keydown < source = "key"; keycode = 0x20; mode = ""; >;``  
 True if specified keycode (in this case the spacebar) is pressed and false otherwise.
 If mode is set to "press" the value is true only in the frame the key was initially held down.
 If mode is set to "toggle" the value stays true until the key is pressed a second time.
 * ``uniform bool buttondown < source = "mousebutton"; keycode = 0; toggle = false; >;``  
 True if specified mouse button (0 - 4) is pressed and false otherwise. If toggle is true the value stays true until the key is pressed a second time.
 * ``uniform float2 mousepoint < source = "mousepoint"; >;``  
 Gets the position of the mouse cursor in screen coordinates.
 * ``uniform float2 mousedelta < source = "mousedelta"; >;``  
 Gets the movement of the mouse cursor in screen coordinates.

```c++
// Initializers are used for the initial value when providied.
uniform float4 UniformSingleValue = float4(0.0f, 0.0f, 0.0f, 0.0f);

// It is recommended to use constants instead of uniforms if the value is not changing.
static const float4 ConstantSingleValue = float4(0.0f, 0.0f, 0.0f, 0.0f);
```

### Structs

> Structs are user defined data types that can be used for custom variables.

```c++
struct MyStruct
{
	int MyField1, MyField2;
	float MyField3;
};
```

### Namespaces

> Namespaces are used to group functions and variables together. They are especially useful to avoid name clashing.
> The "::" operator is used to resolve variables or functions inside namespaces.

```c++
namespace MyNamespace
{
	namespace MyNestedNamespace
	{
		void DoNothing()
		{
		}
	}

	void DoNothing()
	{
		MyNestedNamespace::DoNothing();
	}
}
```

### Functions

Parameter Qualifiers:

 * ``in`` Declares an input parameter. Default and implicit if none is used. Functions expect these to be filled with a value.
 * ``out`` Declares an output parameter. The value is filled in the function and can be used in the caller again.
 * ``inout`` Declares a parameter that provides input and also expects output.

Intrinsics:

> abs, acos, all, any, asfloat, asin, asint, asuint, atan, atan2, ceil, clamp, cos, cosh, cross, ddx, ddy, degrees, determinant, distance, dot, exp, exp2, faceforward, floor, frac, frexp, fwidth, ldexp, length, lerp, log, log10, log2, mad, max, min, modf, mul, normalize, pow, radians, rcp, reflect, refract, round, rsqrt, saturate, sign, sin, sincos, sinh, smoothstep, sqrt, step, tan, tanh, tex2D, tex2Dgrad, tex2Dlod, tex2Dproj, transpose, trunc

In addition to these standard intrinsics, ReShade FX comes with a few additional ones:

 * ``float4 tex2Dfetch(sampler2D s, int4 coords)``  
 Fetches a value from the texture directly without any sampling.\
   coords.x : [0, texture width)\
   coords.y : [0, texture height)\
   coords.z : ignored\
   coords.w : [0, texture mip levels)
 * ``float4 tex2Dgather(sampler2D s, float2 coords, int comp)``  
 Gathers the specified component of the four neighboring pixels and returns the result.
 * ``float4 tex2Dgatheroffset(sampler2D s, float2 coords, int2 offset, int comp)``
 * ``float4 tex2Dlodoffset(sampler2D s, float4 coords, int2 offset)``
 * ``float4 tex2Doffset(sampler2D s, float2 coords, int2 offset)``  
 Offsets the texture coordinates before sampling.
 * ``int2 tex2Dsize(sampler2D s, int lod)``  
 Gets the texture dimensions.

Statements:

 * ``if ([condition]) { [statement...] } [else { [statement...] }]``  
 Statements after if are only executed  if condition is true, otherwise the ones after else are executed (if it exists).
 * ``switch ([expression]) { [case [constant]/default]: [statement...] }``  
 Selects the case matching the switch expression or default if non does and it exists.
 * ``for ([declaration]; [condition]; [iteration]) { [statement...] }``  
 Runs the statements in the body as long as the condition is true. The iteration expression is executed after each run.
 * ``while ([condition]) { [statement...] }``  
 Runs the statements in the body as long as the condition is true.
 * ``do { [statement...] } while ([condition]);``  
 Similar to a normal while loop with the difference that the statements are executed at least once.
 * ``break;``  
 Breaks out  of the current loop or switch statement and jumps to the statement after.
 * ``continue;``  
 Jumps directly to the next loop iteration ignoring any left code in the current one.
 * ``return [expression];``  
 Jumps out of the current function, optionally providing a value to the caller.
 * ``discard;``  
 Abort rendering of the current pixel and step out of the shader. Can be used in pixel shaders only.

```c++
// Semantics are used to tell the runtime which arguments to connect between shader stages.
// They are ignored on non-entry-point functions (those not used in any pass below).
// Semantics starting with  "SV_" are system value semantics and serve a special meaning.
// The following vertex shader demonstrates how to generate a simple fullscreen triangle with the three vertices provided by ReShade (http://redd.it/2j17wk):
void ExampleVS(uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
}

// The following pixel shader simply returns the color of the games output again without modifying it (via the "color" output parameter):
void ExamplePS0(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_Target)
{
	color = tex2D(samplerColor, texcoord);
}

// The following pixel shader takes the output of the previous pass and adds the depth buffer content to the right screen side.
float4 ExamplePS1(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	// Here color information is sampled with "samplerTarget" and thus from "texTarget" (see sampler declaration above),
	// which was set as render target in the previous pass (see the technique definition below) and now contains its output.
	// In this case it is the game output, but downsampled to half because the texture is only half of the screen size.
	float4 color = tex2D(samplerTarget, texcoord);
	
	// Only execute the following code block when on the right half of the screen.
	if (texcoord.x > 0.5f)
	{
		// Sample from the game depth buffer using the "samplerDepth" sampler declared above.
		float depth = tex2D(samplerDepth, texcoord).r;
		
		// Linearize the depth values to better visualize them.
		depth = 2.0 / (-99.0 * depth + 101.0);
		
		color.rgb = depth.rrr;
	}

	return color;
}
```

### Techniques

> An effect file can have multiple techniques, each representing a full render pipeline, which is executed to apply post-processing effects. ReShade executes all enabled techniques in the order they were defined in the effect file.
> A technique is made up of one or more passes which contain info about which render states to set and what shaders to execute. They are run sequentially starting with the top most declared. A name is optional.
> Each pass can set render states. The default value is used if one is not specified in the pass body.

Annotations:

 * ``technique tech1 < enabled = true; > { ... }``  
 Enable (or disable if false) this technique by default.
 * ``technique tech2 < timeout = 1000; > { ... }``  
 Auto-toggle this technique off 1000 milliseconds after it was enabled.
 * ``technique tech3 < toggle = 0x20; > { ... }``  
 Toggle this technique when the specified key is pressed.
 * ``technique tech3 < toggleTime = 100; > { ... }``  
 Toggle this technique at the specified time (seconds after midnight).

```c++
technique Example < enabled = true; >
{
	pass p0
	{	
		// The following two accept function names declared above which are used as entry points for the shader.
		// Please note that all parameters must have an associated semantic so the runtime can match them between shader stages.
		VertexShader = ExampleVS;
		PixelShader = ExamplePS0;
		
		// RenderTarget0 to RenderTarget7 allow to set one or more render targets for rendering to textures.
		// Set them to a texture name declared above in order to write the color output (SV_Target0 to RenderTarget0, SV_Target1 to RenderTarget1, ...) to this texture in this pass.
		// If multiple render targets are used, the dimensions of them has to match each other.
		// If no render targets are set here, RenderTarget0 points to the backbuffer.
		// Be aware that you can only read **OR** write a texture at the same time, so do not sample from it while it is still bound as render target here.
		// RenderTarget and RenderTarget0 are aliases.
		RenderTarget = texTarget;

		// Clears all bound render targets to zero before rendering when set to true.
		ClearRenderTargets = true;
		
		// A mask applied to the color output before it is written to the render target.
		RenderTargetWriteMask = 0xF; // or ColorWriteEnable
		
		// Enable or disable gamma correction applied to the output.
		SRGBWriteEnable = false;

		// Enable or disable color and alpha blending.
		// Don't forget to also set "ClearRenderTargets" to "false" if you want to blend with existing data in a render target.
		BlendEnable = false;

		// The operator used for color and alpha blending.
		// Available values:
		//   ADD, SUBTRACT, REVSUBTRACT, MIN, MAX
		BlendOp = ADD;
		BlendOpAlpha = ADD;

		// The data source and optional pre-blend operation used for blending.
		// Available values:
		//   ZERO, ONE,
		//   SRCCOLOR, SRCALPHA, INVSRCCOLOR, INVSRCALPHA
		//   DESTCOLOR, DESTALPHA, INVDESTCOLOR, INVDESTALPHA
		SrcBlend = ONE;
		SrcBlendAlpha = ONE;
		DestBlend = ZERO;
		DestBlendAlpha = ZERO;
		
		// Enable or disable the stencil test.
		// The depth and stencil buffers are cleared before rendering each pass in a technique.
		StencilEnable = false;

		// The masks applied before reading from/writing to the stencil.
		// Available values:
		//   0-255
		StencilReadMask = 0xFF; // or StencilMask
		StencilWriteMask = 0xFF;
		
		// The function used for stencil testing.
		// Available values:
		//   NEVER, ALWAYS
		//   EQUAL, NEQUAL or NOTEQUAL
		//   LESS, GREATER, LEQUAL or LESSEQUAL, GEQUAL or GREATEREQUAL
		StencilFunc = ALWAYS;

		// The reference value used with the stencil function.
		StencilRef = 0;
		
		// The operation  to  perform  on  the stencil  buffer when  the
		// stencil  test passed/failed or stencil passed  but depth test
		// failed.
		// Available values:
		//   KEEP, ZERO, REPLACE, INCR, INCRSAT, DECR, DECRSAT, INVERT
		StencilPassOp = KEEP; // or StencilPass
		StencilFailOp = KEEP; // or StencilFail
		StencilDepthFailOp = KEEP; // or StencilZFail
	}
	pass p1
	{
		VertexShader = ExampleVS;
		PixelShader = ExamplePS1;
	}
}
```
