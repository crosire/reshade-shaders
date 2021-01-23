
//by Pascal Gilcher

/*
    Retro Neon filter, works as follows:

    1) generate faux normal vectors
    2) blur them a bit, to remove unnecessary detail and dampen aliasing
    3) find normal discontinuities - the edges
    4) multipass bloom downscale
    5) combine all bloom layers
    6) apply postfx, currently chromatic aberration and lens distortion

*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/


/*=============================================================================
	UI Uniforms
=============================================================================*/
uniform float GLOW_COLOR <
    ui_type = "drag";
    ui_label = "Glow Color";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.567;

uniform bool USE_PING
<
    ui_label = "Use Radar Ping Effect";
> = true;

uniform float LENS_DISTORT <
    ui_type = "drag";
    ui_label = "Lens Distortion Intensity";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.2;

uniform float CHROMA_SHIFT <
    ui_type = "drag";
    ui_label = "Chromatic Aberration Intensity";
    ui_min = -1.0;
    ui_max = 1.0;
> = 0.5;

uniform float EDGES_AMT <
    ui_type = "drag";
    ui_label = "Edge Amount";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.1;


/*
uniform bool DEBUG_CHEAT_MASK = false;

uniform bool DEBUG_LINE_MODE = false;

uniform float DEBUG_FADE_MULT = 0.0;
*/
bool DEBUG_CHEAT_MASK = false;
bool DEBUG_LINE_MODE = false;
bool DEBUG_FADE_MULT = 0.0;

/*=============================================================================
	Textures, Samplers, Globals
=============================================================================*/

#include "qUINT_common.fxh"
uniform float timer < source = "timer"; >;


texture2D TempTex0 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA16F; };
texture2D TempTex1 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA16F; };

sampler2D sTempTex0	{ Texture = TempTex0;	};
sampler2D sTempTex1	{ Texture = TempTex1;	};

texture2D GlowTex0 	{ Width = BUFFER_WIDTH/2;   Height = BUFFER_HEIGHT/2;   Format = RGBA16F; };
texture2D GlowTex1 	{ Width = BUFFER_WIDTH/4;   Height = BUFFER_HEIGHT/4;   Format = RGBA16F; };
texture2D GlowTex2 	{ Width = BUFFER_WIDTH/8;   Height = BUFFER_HEIGHT/8;   Format = RGBA16F; };
texture2D GlowTex3 	{ Width = BUFFER_WIDTH/16;   Height = BUFFER_HEIGHT/16;   Format = RGBA16F; };
texture2D GlowTex4 	{ Width = BUFFER_WIDTH/32;   Height = BUFFER_HEIGHT/32;   Format = RGBA16F; };

sampler2D sGlowTex0	{ Texture = GlowTex0;	};
sampler2D sGlowTex1	{ Texture = GlowTex1;	};
sampler2D sGlowTex2	{ Texture = GlowTex2;	};
sampler2D sGlowTex3	{ Texture = GlowTex3;	};
sampler2D sGlowTex4	{ Texture = GlowTex4;	};

/*=============================================================================
	Vertex Shader
=============================================================================*/

struct VSOUT
{
	float4                  vpos        : SV_Position;
    float2                  uv          : TEXCOORD0;
    nointerpolation float3  uvtoviewADD : TEXCOORD2;
    nointerpolation float3  uvtoviewMUL : TEXCOORD3;
};

VSOUT VSMain(in uint id : SV_VertexID)
{
    VSOUT o;

    o.uv.x = (id == 2) ? 2.0 : 0.0;
    o.uv.y = (id == 1) ? 2.0 : 0.0;

    o.vpos = float4(o.uv.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

    o.uvtoviewADD = float3(-1.0,-1.0,1.0);
    o.uvtoviewMUL = float3(2.0,2.0,0.0);

    return o;
}

/*=============================================================================
	Functions
=============================================================================*/

float depth_to_distance(in float depth)
{
    return depth * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE + 1;
}

float3 get_position_from_uv(in VSOUT i)
{
    return (i.uv.xyx * i.uvtoviewMUL + i.uvtoviewADD) * depth_to_distance(qUINT::linear_depth(i.uv.xy));
}

float3 get_position_from_uv(in VSOUT i, in float2 uv)
{
    return (uv.xyx * i.uvtoviewMUL + i.uvtoviewADD) * depth_to_distance(qUINT::linear_depth(uv));
}

float4 gaussian_1D(in VSOUT i, in sampler input_tex, int kernel_size, float2 axis)
{
    float4 sum = tex2D(input_tex, i.uv);
    float weightsum = 1;

    for(float j = 1; j <= kernel_size; j++)
    {
        float w = exp(-2 * j * j / (kernel_size * kernel_size));
        sum += tex2Dlod(input_tex, float4(i.uv + qUINT::PIXEL_SIZE * axis * (j * 2 - 0.5), 0, 0)) * w;
        sum += tex2Dlod(input_tex, float4(i.uv - qUINT::PIXEL_SIZE * axis * (j * 2 - 0.5), 0, 0)) * w;
        weightsum += w * 2;
    }
    return sum / weightsum;
}

float4 downsample(sampler2D tex, float2 tex_size, float2 uv)
{
	float4 offset_uv = 0;

	float2 kernel_small_offsets = float2(2.0,2.0) / tex_size;
	float2 kernel_large_offsets = float2(4.0,4.0) / tex_size;

	float4 kernel_center = tex2D(tex, uv);

	float4 kernel_small = 0;

	offset_uv.xy = uv + kernel_small_offsets;
	kernel_small += tex2Dlod(tex, offset_uv); //++
	offset_uv.x = uv.x - kernel_small_offsets.x;
	kernel_small += tex2Dlod(tex, offset_uv); //-+
	offset_uv.y = uv.y - kernel_small_offsets.y;
	kernel_small += tex2Dlod(tex, offset_uv); //--
	offset_uv.x = uv.x + kernel_small_offsets.x;
	kernel_small += tex2Dlod(tex, offset_uv); //+-

	float4 kernel_large_1 = 0;

	offset_uv.xy = uv + kernel_large_offsets;
	kernel_large_1 += tex2Dlod(tex, offset_uv); //++
	offset_uv.x = uv.x - kernel_large_offsets.x;
	kernel_large_1 += tex2Dlod(tex, offset_uv); //-+
	offset_uv.y = uv.y - kernel_large_offsets.y;
	kernel_large_1 += tex2Dlod(tex, offset_uv); //--
	offset_uv.x = uv.x + kernel_large_offsets.x;
	kernel_large_1 += tex2Dlod(tex, offset_uv); //+-

	float4 kernel_large_2 = 0;

	offset_uv.xy = uv;
	offset_uv.x += kernel_large_offsets.x;
	kernel_large_2 += tex2Dlod(tex, offset_uv); //+0
	offset_uv.x -= kernel_large_offsets.x * 2.0;
	kernel_large_2 += tex2Dlod(tex, offset_uv); //-0
	offset_uv.x = uv.x;
	offset_uv.y += kernel_large_offsets.y;
	kernel_large_2 += tex2Dlod(tex, offset_uv); //0+
	offset_uv.y -= kernel_large_offsets.y * 2.0;
	kernel_large_2 += tex2Dlod(tex, offset_uv); //0-

	return kernel_center * 0.5 / 4.0		
	     + kernel_small  * 0.5 / 4.0	
	     + kernel_large_1 * 0.125 / 4.0
	     + kernel_large_2 * 0.25 / 4.0;
}

float3 hue_to_rgb(float hue)
{
    return saturate(float3(abs(hue * 6.0 - 3.0) - 1.0,
                           2.0 - abs(hue * 6.0 - 2.0),
                           2.0 - abs(hue * 6.0 - 4.0)));
}

/*=============================================================================
	Pixel Shaders
=============================================================================*/

void PrepareInput(in VSOUT i, out float4 o : SV_Target0)
{
    float4 A, B, C, D, E, F, G, H, I;

    float3 offsets = float3(1, 0, -1);

    /*
        A B C
        D E F 
        G H I
    */
    
    A.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.zz * qUINT::PIXEL_SIZE).rgb;
    B.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.yz * qUINT::PIXEL_SIZE).rgb;
    C.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.xz * qUINT::PIXEL_SIZE).rgb;
    D.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.zy * qUINT::PIXEL_SIZE).rgb;
    E.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.yy * qUINT::PIXEL_SIZE).rgb;
    F.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.xy * qUINT::PIXEL_SIZE).rgb;
    G.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.zx * qUINT::PIXEL_SIZE).rgb;
    H.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.yx * qUINT::PIXEL_SIZE).rgb;
    I.rgb = tex2D(qUINT::sBackBufferTex, i.uv + offsets.xx * qUINT::PIXEL_SIZE).rgb;

    A.w = qUINT::linear_depth(i.uv + offsets.zz * qUINT::PIXEL_SIZE);
    B.w = qUINT::linear_depth(i.uv + offsets.yz * qUINT::PIXEL_SIZE);
    C.w = qUINT::linear_depth(i.uv + offsets.xz * qUINT::PIXEL_SIZE);
    D.w = qUINT::linear_depth(i.uv + offsets.zy * qUINT::PIXEL_SIZE);
    E.w = qUINT::linear_depth(i.uv + offsets.yy * qUINT::PIXEL_SIZE);
    F.w = qUINT::linear_depth(i.uv + offsets.xy * qUINT::PIXEL_SIZE);
    G.w = qUINT::linear_depth(i.uv + offsets.zx * qUINT::PIXEL_SIZE);
    H.w = qUINT::linear_depth(i.uv + offsets.yx * qUINT::PIXEL_SIZE);
    I.w = qUINT::linear_depth(i.uv + offsets.xx * qUINT::PIXEL_SIZE);

    float3 color_edge;
    {
        float3 corners = (A.rgb + C.rgb) + (G.rgb + I.rgb);
        float3 neighbours = (B.rgb + D.rgb) + (F.rgb + H.rgb);
        float3 center = E.rgb;

        color_edge = corners + 2.0 * neighbours - 12.0 * center;
        //color_edge /= corners + neighbours + center;
    }

    float depth_delta_x1 = D.w - E.w;
    float depth_delta_x2 = E.w - F.w;

    float depth_edge_x = abs(depth_delta_x1) < abs(depth_delta_x2) ? depth_delta_x1 : depth_delta_x2;

    float depth_delta_y1 = B.w - E.w;
    float depth_delta_y2 = E.w - H.w;

    float depth_edge_y = abs(depth_delta_y1) < abs(depth_delta_y2) ? depth_delta_y1 : depth_delta_y2;


    o.xyz = normalize(float3(depth_edge_x, depth_edge_y, 0.000001));
    o.w = smoothstep(0.15, 0.25, sqrt(dot(color_edge, color_edge))); //maybe useful to mask stuff?
}

void Filter_Input_A(in VSOUT i, out float4 o : SV_Target0)
{
    o = gaussian_1D(i, sTempTex0, 1, float2(0, 1));
}

void Filter_Input_B(in VSOUT i, out float4 o : SV_Target0)
{
    o = gaussian_1D(i, sTempTex1, 1, float2(1, 0));
}

void GenerateEdges(in VSOUT i, out float4 o : SV_Target0)
{
if(DEBUG_LINE_MODE)
{
   float3 blurred = 0;

    for(int x = -2; x<=2; x++)
    for(int y = -2; y<=2; y++)
    {
        blurred += tex2Doffset(sTempTex0, i.uv, int2(x, y)).xyz;
    }

    float3 center = tex2D(sTempTex0, i.uv).xyz;
    o = dot(normalize(blurred), center);
   o = smoothstep(1, 0.7 * EDGES_AMT, o);

}else{

    float3x3 sobel = float3x3(1, 2, 1, 0, 0, 0, -1, -2, -1);

    float3 sobelx = 0, sobely = 0;

    for(int x = 0; x < 3; x++)
    for(int y = 0; y < 3; y++)
    {
        float3 n = tex2Doffset(sTempTex0, i.uv, int2(x - 1, y - 1)).xyz;
        sobelx += n * sobel[x][y];
        sobely += n * sobel[y][x];
    }

    o = pow(EDGES_AMT * 0.2 * (dot(sobelx, sobelx) + dot(sobely, sobely)), 1.5);
}

    o *= smoothstep(0.5,0.48, max(abs(i.uv.x-0.5), abs(i.uv.y-0.5))); // fix screen edges
    o.w = tex2D(sTempTex0, i.uv).w; //preserve color edges
}

void Downsample0(in VSOUT i, out float4 o : SV_Target0)
{
    o = downsample(sTempTex1, qUINT::SCREEN_SIZE, i.uv);

    //fade out before blur because otherwise objects don't glow into e.g. sky - looks super weird
    float depth = qUINT::linear_depth(i.uv);
    o *= saturate(1.0 - depth * 40.0 * DEBUG_FADE_MULT);
}
void Downsample1(in VSOUT i, out float4 o : SV_Target0)
{
    o = downsample(sGlowTex0, qUINT::SCREEN_SIZE/2, i.uv);
}
void Downsample2(in VSOUT i, out float4 o : SV_Target0)
{
    o = downsample(sGlowTex1, qUINT::SCREEN_SIZE/4, i.uv);
}
void Downsample3(in VSOUT i, out float4 o : SV_Target0)
{
    o = downsample(sGlowTex2, qUINT::SCREEN_SIZE/8, i.uv);
}
void Downsample4(in VSOUT i, out float4 o : SV_Target0)
{
    o = downsample(sGlowTex3, qUINT::SCREEN_SIZE/16, i.uv);
}

void Combine(in VSOUT i, out float4 o : SV_Target0)
{
    o = 0;

    float depth = qUINT::linear_depth(i.uv);

    float lines = tex2D(sTempTex1, i.uv).x * 0.63;

    float glow = tex2D(sGlowTex0, i.uv).x * 0.07
               + tex2D(sGlowTex1, i.uv).x * 1.08
               + tex2D(sGlowTex2, i.uv).x * 0.92
               + tex2D(sGlowTex3, i.uv).x * 0.95
               + tex2D(sGlowTex4, i.uv).x * 0.5;

    float3 tintcol = hue_to_rgb(GLOW_COLOR);//1-float3(223,116,12)/255.0;

    float3 pos = get_position_from_uv(i);
    float wave = frac(sqrt(length(pos))*0.09 - (timer % 100000)* 0.003*0.1);
    wave = wave*wave*wave*wave*wave*0.8;

    //fade out and merge everything
   // lines *= saturate(1.0 - depth * 40.0 * DEBUG_FADE_MULT);
    //glow *=  saturate(1.0 - depth * 40.0 * DEBUG_FADE_MULT); -> faded out before the bloom blur
    wave *= saturate(1.0 - depth * 50.0 * DEBUG_FADE_MULT);

    if(!USE_PING) wave = 0;

    o.rgb = lines + (lines + glow + wave) * tintcol;

    if(DEBUG_CHEAT_MASK) o.rgb *= tex2D(sGlowTex2, i.uv).w * 2.0;
    o.w = 1;
}

void PostFX(in VSOUT i, out float4 o : SV_Target0)
{
    /*float2 uv = i.uv - 0.5;
    float distort = 1 + dot(uv, uv) * 0 + dot(uv, uv) * dot(uv, uv) * -(LENS_DISTORT * 0.9 + 0.5);
    o.x = tex2D(qUINT::sBackBufferTex, (i.uv.xy-0.5) * (1 - 0.008 * CHROMA_SHIFT) * distort + 0.5).x;
    o.y = tex2D(qUINT::sBackBufferTex, (i.uv.xy-0.5) * (1       )                 * distort + 0.5).y;
    o.z = tex2D(qUINT::sBackBufferTex, (i.uv.xy-0.5) * (1 + 0.008 * CHROMA_SHIFT) * distort + 0.5).z;
    o.w = 1;*/


        o = 0;

    float3 offsets[5] =
    {
        float3(1.5, 0.5,4),
        float3(-1.5, -0.5,4),
        float3(-0.5, 1.5,4),
        float3(0.5, -1.5,4),
        float3(0,0,1)
    };

    for(int j = 0; j < 5; j++)
    {        
        float2 uv = i.uv.xy - 0.5;
        float distort = 1 + dot(uv, uv) * 0 + dot(uv, uv) * dot(uv, uv) * -(LENS_DISTORT * 0.9 + 0.5);
        o.x += tex2D(qUINT::sBackBufferTex, (i.uv.xy-0.5) * (1 - 0.008 * CHROMA_SHIFT) * distort + 0.5 + offsets[j].xy * qUINT::PIXEL_SIZE).x * offsets[j].z;
        o.y += tex2D(qUINT::sBackBufferTex, (i.uv.xy-0.5) * (1       )  * distort + 0.5 + offsets[j].xy * qUINT::PIXEL_SIZE).y * offsets[j].z;
        o.z += tex2D(qUINT::sBackBufferTex, (i.uv.xy-0.5) * (1 + 0.008 * CHROMA_SHIFT) * distort + 0.5 + offsets[j].xy * qUINT::PIXEL_SIZE).z * offsets[j].z;
        o.w += offsets[j].z;
    }

    o /= o.w;
}

/*=============================================================================
	Techniques
=============================================================================*/

technique TRON
{
    pass
	{
		VertexShader = VSMain;
		PixelShader  = PrepareInput;
        RenderTarget = TempTex0;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Filter_Input_A;
        RenderTarget = TempTex1;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Filter_Input_B;
        RenderTarget = TempTex0;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = GenerateEdges;
        RenderTarget = TempTex1;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Downsample0;
        RenderTarget = GlowTex0;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Downsample1;
        RenderTarget = GlowTex1;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Downsample2;
        RenderTarget = GlowTex2;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Downsample3;
        RenderTarget = GlowTex3;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Downsample4;
        RenderTarget = GlowTex4;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = Combine;
	}
    pass
	{
		VertexShader = VSMain;
		PixelShader  = PostFX;
	}
}
