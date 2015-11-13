/*
 Deband shader by Paul Groke
 http://forum.kodi.tv/showthread.php?tid=114801&pid=942551#pid942551
 
 Modified and optimized for ReShade by JPulowski
 http://reshade.me/forum/shader-presentation/768-deband
 
 Do not distribute without giving credit to the original author(s).
 
 1.0  - Initial release
*/

NAMESPACE_ENTER(CFX)
#include CFX_SETTINGS_DEF

#if (USE_DEBAND == 1)

float rand(float2 pos)
{
	return frac(sin(dot(pos, float2(12.9898, 78.233))) * 43758.5453);
}

bool is_within_threshold(float3 original, float3 other)
{
	return !any(max(abs(original - other) - DEBAND_THRESHOLD, float3(0.0, 0.0, 0.0))).x;
}

float4 PS_Deband(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 step = RFX_PixelSize * DEBAND_RADIUS;
    float2 halfstep = step * 0.5;

    //Compute additional sample positions
    float2 seed = texcoord + RFX_FrameTime;
	#if (DEBAND_OFFSET_MODE == 1)
		float2 offset = float2(rand(seed), 0.0);
	#elif (DEBAND_OFFSET_MODE == 2)
		float2 offset = float2(rand(seed).xx);
	#elif (DEBAND_OFFSET_MODE == 3)
		float2 offset = float2(rand(seed), rand(seed + float2(0.1, 0.2)));
	#endif

    float2 on[8] = {
        float2( offset.x,  offset.y) * step,
        float2( offset.y, -offset.x) * step,
        float2(-offset.x, -offset.y) * step,
        float2(-offset.y,  offset.x) * step,
        float2( offset.x,  offset.y) * halfstep,
        float2( offset.y, -offset.x) * halfstep,
        float2(-offset.x, -offset.y) * halfstep,
        float2(-offset.y,  offset.x) * halfstep,
        };

    float3 col0 = tex2D(RFX_backbufferColor, texcoord).rgb;
    float4 accu = float4(col0, 1.0);

    for (int i = 0; i < DEBAND_SAMPLE_COUNT; i++)
    {
        float4 cn = float4(tex2D(RFX_backbufferColor, texcoord + on[i]).rgb, 1.0);
		#if (DEBAND_SKIP_THRESHOLD_TEST == 0)
			if (is_within_threshold(col0, cn.rgb))
		#endif
		accu += cn;
    }

    accu.rgb /= accu.a;

    //Boost to make it easier to inspect the effect's output
    if (DEBAND_OUTPUT_OFFSET != 0.0 || DEBAND_OUTPUT_BOOST != 1.0)
	{
		accu.rgb -= DEBAND_OUTPUT_OFFSET;
		accu.rgb *= DEBAND_OUTPUT_BOOST;
	}
	
	//Additional dithering
	#if (DEBAND_DITHERING == 1)
		//Ordered dithering
		float dither_bit  = 8.0;
		float grid_position = frac( dot(texcoord,(RFX_ScreenSize * float2(1.0/16.0,10.0/36.0))) + 0.25 );
		float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0));
		float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift);
		dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position);
		accu.rgb += dither_shift_RGB;
	#elif (DEBAND_DITHERING == 2)
		//Random dithering
		float dither_bit  = 8.0;
		float sine = sin(dot(texcoord, float2(12.9898,78.233)));
		float noise = frac(sine * 43758.5453 + texcoord.x);
		float dither_shift = (1.0 / (pow(2,dither_bit) - 1.0));
		float dither_shift_half = (dither_shift * 0.5);
		dither_shift = dither_shift * noise - dither_shift_half;
		accu.rgb += float3(-dither_shift, dither_shift, -dither_shift);
	#elif (DEBAND_DITHERING == 3)
		//Iestyn's RGB dither (7 asm instructions) from Portal 2 X360, slightly modified for VR
		//float3 vDither = dot(float2(171.0, 231.0), texcoord * RFX_ScreenSize + RFX_Timer).xxx; //Dynamic dither pattern
		float3 vDither = dot(float2(171.0, 231.0), texcoord * RFX_ScreenSize).xxx;
		vDither.rgb = frac( vDither.rgb / float3( 103.0, 71.0, 97.0 ) ) - float3(0.5, 0.5, 0.5);
		accu.rgb += (vDither.rgb / 255.0);
	#endif
	
	return saturate(accu);
}

technique Deband_Tech <bool enabled = RFX_Start_Enabled; int toggle = Deband_ToggleKey; >
{
	pass DebandPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_Deband;
	}
}

#endif

#include CFX_SETTINGS_UNDEF
NAMESPACE_LEAVE()