/* 
Black and White shader by prod80 for ReShade
Version 1.2
*/

/* Additional credits:
 *
 * Deband shader by haasn
 * https://github.com/haasn/gentoo-conf/blob/xor/home/nand/.mpv/shaders/deband-pre.glsl
 *
 * Copyright (c) 2015 Niklas Haas
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Modified and optimized for ReShade by JPulowski
 * https://reshade.me/forum/shader-presentation/768-deband
 *
 * Do not distribute without giving credit to the original author(s).
 */

/*
 * Additional credits:
 *
 * Noise/Grain code adopted, modified, and adjusted from Martins H.
 * This work is licensed under a Creative Commons Attribution 3.0 Unported License.
 * http://devlog-martinsh.blogspot.com/2013/05/image-imperfections-and-film-grain-post.html
 */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

namespace pd80_blackandwhite
{

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    // Level Controls
    uniform float3 inWhite <
        ui_type = "color";
        ui_label = "IN White Point Adjustment";
        ui_category = "Black & White (general)";
        > = float3(1.0, 1.0, 1.0);
    uniform float3 inBlack <
        ui_type = "color";
        ui_label = "IN Black Point Adjustment";
        ui_category = "Black & White (general)";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 White <
        ui_type = "color";
        ui_label = "OUT White Point Adjustment";
        ui_category = "Black & White (general)";
        > = float3(0.922, 0.922, 0.922);
    uniform float3 Black <
        ui_type = "color";
        ui_label = "OUT Black Point Adjustment";
        ui_category = "Black & White (general)";
        > = float3(0.078, 0.078, 0.078);
    uniform float Gamma <
        ui_type = "slider";
        ui_label = "Gamma Adjustment";
        ui_category = "Black & White (general)";
        ui_min = 0.0f;
        ui_max = 5.0f;
        > = 1.3;
    // B&W Techniques
    uniform float3 luminosity <
        ui_type = "color";
        ui_label = "Select Color to Convert B&W";
        ui_category = "Black & White Techniques";
        > = float3(0.6, 1.0, 0.4);
    // Gaussian Blur
    uniform float BlurSigma <
        ui_type = "slider";
        ui_label = "Blur Width";
        ui_category = "Black & White Blend Mode (Blur)";
        ui_min = 0.001f;
        ui_max = 30.0f;
        > = 4.0;
    uniform int BlendModeB < __UNIFORM_COMBO_INT1
        ui_label = "Blend Mode";
        ui_category = "Black & White Blend Mode (Blur)";
        ui_items = "Normal\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0";
        > = 10;
    uniform float opacityB <
        ui_type = "slider";
        ui_label = "Opacity";
        ui_category = "Black & White Blend Mode (Blur)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.333;
    uniform bool use_unblur <
        ui_label = "Use Unblurred Image as Blend";
        ui_category = "Black & White Blend Mode (Gradient or Unblur)";
        > = false;
    uniform bool use_gradient <
        ui_label = "Use Gradient Image as Blend";
        ui_category = "Black & White Blend Mode (Gradient or Unblur)";
        > = false;
    uniform float3 LightColor <
        ui_type = "color";
        ui_label = "Highlight Color Gradient";
        ui_category = "Black & White Blend Mode (Gradient or Unblur)";
        > = float3(1.0, 0.5, 0.0);
    uniform float3 DarkColor <
        ui_type = "color";
        ui_label = "Shadow Color Gradient";
        ui_category = "Black & White Blend Mode (Gradient or Unblur)";
        > = float3(0.0, 0.5, 1.0);
    uniform int BlendMode < __UNIFORM_COMBO_INT1
        ui_label = "Blend Mode";
        ui_category = "Black & White Blend Mode (Gradient or Unblur)";
        ui_items = "Normal\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0";
        > = 5;
    uniform float opacity <
        ui_type = "slider";
        ui_label = "Opacity";
        ui_category = "Black & White Blend Mode (Gradient or Unblur)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform bool blendOrig <
        ui_label = "Blend Black & White with Original";
        ui_category = "Black & White Blend Mode (Blend Original)";
        > = false;
    uniform bool flipColorBlend <
        ui_label = "Flip Blend Layers";
        ui_category = "Black & White Blend Mode (Blend Original)";
        > = false;
    uniform int BlendModeO < __UNIFORM_COMBO_INT1
        ui_label = "Blend Mode";
        ui_category = "Black & White Blend Mode (Blend Original)";
        ui_items = "Normal\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0";
        > = 0;
    uniform float opacityO <
        ui_type = "slider";
        ui_label = "Opacity";
        ui_category = "Black & White Blend Mode (Blend Original)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Final adjustments
    uniform float contrast <
        ui_type = "slider";
        ui_label = "Contrast";
        ui_category = "Black & White Final Adjustments";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float brightness <
        ui_type = "slider";
        ui_label = "Brightness";
        ui_category = "Black & White Final Adjustments";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform bool use_ca <
        ui_label = "Enable Chromatic Aberration";
        ui_category = "Chromatic Aberration";
        > = true;
    uniform bool use_ca_edges <
        ui_label = "Chromatic Aberration Only Edges.\nUse Rotation = 225 for best effect.";
        ui_category = "Chromatic Aberration";
        > = true;
    uniform int degrees <
        ui_type = "slider";
        ui_label = "Chromatic Aberration Rotation";
        ui_category = "Chromatic Aberration";
        ui_min = 0;
        ui_max = 360;
        ui_step = 1;
        > = 225;
    uniform float CA <
        ui_type = "slider";
        ui_label = "Chromatic Aberration Width";
        ui_category = "Chromatic Aberration";
        ui_min = 0.0f;
        ui_max = 100.0f;
        > = 5.0;
    uniform float CA_strength <
        ui_type = "slider";
        ui_label = "Chromatic Aberration Strength";
        ui_category = "Chromatic Aberration";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.5;
    uniform bool use_grain <
        ui_label = "Enable Film Grain";
        ui_category = "Film Grain (perlin)";
        > = false;
    uniform float grainColor <
        ui_type = "slider";
        ui_label = "Grain Color Amount";
        ui_category = "Film Grain (perlin)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float grainAmount <
        ui_type = "slider";
        ui_label = "Grain Amount";
        ui_category = "Film Grain (perlin)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.05;
    uniform float grainIntensity <
        ui_type = "slider";
        ui_label = "Grain Intensity Global";
        ui_category = "Film Grain (perlin)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.2;
    uniform float grainIntHigh <
        ui_type = "slider";
        ui_label = "Grain Intensity Highlights";
        ui_category = "Film Grain (perlin)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.7;
    uniform float grainIntLow <
        ui_type = "slider";
        ui_label = "Grain Intensity Shadows";
        ui_category = "Film Grain (perlin)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texColorNew { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; }; 
    texture texBlurH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; }; 
    texture texBlur { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    texture texBlurDeband { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    texture texBlended { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    texture texAfterFX1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerColorNew { Texture = texColorNew; };
    sampler samplerBlurH { Texture = texBlurH; };
    sampler samplerBlur { Texture = texBlur; };
    sampler samplerBlurDeband { Texture = texBlurDeband; };
    sampler samplerBlended { Texture = texBlended; };
    sampler samplerAfterFX1 { Texture = texAfterFX1; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define Pi          3.141592f
    #define Loops       150
    #define Quality     0.985f
    #define px          1.0f / BUFFER_WIDTH
    #define py          1.0f / BUFFER_HEIGHT
    //// BUFFERS ////////////////////////////////////////////////////////////////////
    // Not supported in ReShade (?)

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    uniform int drandom < source = "random"; min = 0; max = 32767; >;
    uniform float Timer < source = "timer"; >;
    #define timer float( Timer % 1000.0 )
    //#define timer float( 1.0 )

    void analyze_pixels(float3 ori, sampler2D tex, float2 texcoord, float2 _range, float2 dir, out float3 ref_avg, out float3 ref_avg_diff, out float3 ref_max_diff, out float3 ref_mid_diff1, out float3 ref_mid_diff2)
    {
        // South-east
        float3 ref        = tex2Dlod( tex, float4( texcoord + _range * dir, 0.0f, 0.0f )).rgb;
        float3 diff       = abs( ori - ref );
        ref_max_diff      = diff;
        ref_avg           = ref;
        ref_mid_diff1     = ref;
        // North-west
        ref               = tex2Dlod( tex, float4( texcoord + _range * -dir, 0.0f, 0.0f )).rgb;
        diff              = abs( ori - ref );
        ref_max_diff      = max( ref_max_diff, diff );
        ref_avg           += ref;
        ref_mid_diff1     = abs((( ref_mid_diff1 + ref ) * 0.5f ) - ori );
        // North-east
        ref               = tex2Dlod( tex, float4( texcoord + _range * float2( -dir.y, dir.x ), 0.0f, 0.0f )).rgb;
        diff              = abs( ori - ref );
        ref_max_diff      = max( ref_max_diff, diff );
        ref_avg           += ref;
        ref_mid_diff2     = ref;
        // South-west
        ref               = tex2Dlod( tex, float4( texcoord + _range * float2( dir.y, -dir.x ), 0.0f, 0.0f )).rgb;
        diff              = abs( ori - ref );
        ref_max_diff      = max( ref_max_diff, diff );
        ref_avg           += ref;
        ref_mid_diff2     = abs((( ref_mid_diff2 + ref ) * 0.5f ) - ori );
        // Normalize avg
        ref_avg           *= 0.25f;
        ref_avg_diff      = abs( ori - ref_avg );
    }

    float permute( in float x )
    {
        return ((34.0f * x + 1.0f) * x) % 289.0f;
    }

    float rand( in float x )
    {
        return frac(x / 41.0f);
    }

    float3 darken(float3 c, float3 b) 		{ return min(b, c);}
    float3 multiply(float3 c, float3 b) 	{ return c*b;}
    float3 linearburn(float3 c, float3 b) 	{ return max(c+b-1.0f, 0.0f);}
    float3 colorburn(float3 c, float3 b) 	{ return b==0.0f ? b:max((1.0f-((1.0f-c)/b)), 0.0f);}
    float3 lighten(float3 c, float3 b) 		{ return max(b, c);}
    float3 screen(float3 c, float3 b) 		{ return 1.0f-(1.0f-c)*(1.0f-b);}
    float3 colordodge(float3 c, float3 b) 	{ return b==1.0f ? b:min(c/(1.0f-b), 1.0f);}
    float3 lineardodge(float3 c, float3 b) 	{ return min(c+b, 1.0f);}
    float3 overlay(float3 c, float3 b) 		{ return c<0.5f ? 2.0f*c*b:(1.0f-2.0f*(1.0f-c)*(1.0f-b));}
    float3 softlight(float3 c, float3 b) 	{ return b<0.5f ? (2.0f*c*b+c*c*(1.0f-2.0f*b)):(sqrt(c)*(2.0f*b-1.0f)+2.0f*c*(1.0f-b));}
    float3 vividlight(float3 c, float3 b) 	{ return b<0.5f ? colorburn(c, (2.0f*b)):colordodge(c, (2.0f*(b-0.5f)));}
    float3 linearlight(float3 c, float3 b) 	{ return b<0.5f ? linearburn(c, (2.0f*b)):lineardodge(c, (2.0f*(b-0.5f)));}
    float3 pinlight(float3 c, float3 b) 	{ return b<0.5f ? darken(c, (2.0f*b)):lighten(c, (2.0f*(b-0.5f)));}

    float4 rnm( float2 tc ) 
    {
        float noise       = sin( dot( tc + float2( timer, timer ),float2( 12.9898, 78.233 ))) * 43758.5453;
        float noiseR      = frac( noise ) * 2.0 - 1.0;
        float noiseG      = frac( noise * 1.2154 ) * 2.0 - 1.0; 
        float noiseB      = frac( noise * 1.3453 ) * 2.0 - 1.0;
        float noiseA      = frac( noise * 1.3647 ) * 2.0 - 1.0;
        return float4( noiseR, noiseG, noiseB, noiseA );
    }

    float fade( float t )
    {
        return t * t * t * ( t * ( t * 6.0 - 15.0 ) + 10.0 );
    }

    float pnoise3D( float3 p, float2 pos )
    {   
        float3 pf         = frac( p );
        // Noise contributions from (x=0, y=0), z=0 and z=1
        float perm00      = rnm( pos.xy ).a;
        float3 grad000    = rnm( float2( perm00, pos.y )).rgb * 4.0 - 1.0;
        float n000        = dot( grad000, pf );
        float3 grad001    = rnm( float2( perm00, pos.y + py )).rgb * 4.0 - 1.0;
        float n001        = dot( grad001, pf - float3( 0.0, 0.0, 1.0 ));
        // Noise contributions from (x=0, y=1), z=0 and z=1
        float perm01      = rnm( pos.xy + float2( 0.0, py )).a ;
        float3  grad010   = rnm( float2( perm01, pos.y )).rgb * 4.0 - 1.0;
        float n010        = dot( grad010, pf - float3( 0.0, 1.0, 0.0 ));
        float3  grad011   = rnm( float2(perm01, pos.y + py)).rgb * 4.0 - 1.0;
        float n011        = dot( grad011, pf - float3( 0.0, 1.0, 1.0 ));
        // Noise contributions from (x=1, y=0), z=0 and z=1
        float perm10      = rnm( pos.xy + float2( BUFFER_RCP_WIDTH, 0.0 )).a ;
        float3  grad100   = rnm( float2( perm10, pos.y )).rgb * 4.0 - 1.0;
        float n100        = dot( grad100, pf - float3( 1.0, 0.0, 0.0 ));
        float3  grad101   = rnm( float2( perm10, pos.y + py )).rgb * 4.0 - 1.0;
        float n101        = dot( grad101, pf - float3( 1.0, 0.0, 1.0 ));
        // Noise contributions from (x=1, y=1), z=0 and z=1
        float perm11      = rnm( pos.xy + float2( px, py )).a ;
        float3  grad110   = rnm( float2( perm11, pos.y )).rgb * 4.0 - 1.0;
        float n110        = dot( grad110, pf - float3( 1.0, 1.0, 0.0 ));
        float3  grad111   = rnm( float2( perm11, pos.y + py )).rgb * 4.0 - 1.0;
        float n111        = dot( grad111, pf - float3( 1.0, 1.0, 1.0 ));
        // Blend contributions along x
        float4 n_x        = lerp( float4( n000, n001, n010, n011 ), float4( n100, n101, n110, n111 ), fade( pf.x ));
        // Blend contributions along y
        float2 n_xy       = lerp( n_x.xy, n_x.zw, fade( pf.y ));
        // Blend contributions along z
        float n_xyz       = lerp( n_xy.x, n_xy.y, fade( pf.z ));
        // We're done, return the final noise value
        return n_xyz;
    }

    //2d coordinate orientation thing
    float2 coordRot( float2 tc, float angle )
    {
        float aspect      = BUFFER_WIDTH / BUFFER_HEIGHT;
        float rotX        = (( tc.x * 2.0 - 1.0 ) * aspect * cos( angle )) - (( tc.y * 2.0 - 1.0 ) * sin( angle ));
        float rotY        = (( tc.y * 2.0 - 1.0 ) * cos( angle )) + (( tc.x * 2.0 - 1.0 ) * aspect * sin( angle ));
        rotX              = (( rotX / aspect ) * 0.5 + 0.5 );
        rotY              = rotY * 0.5 + 0.5;
        return float2( rotX, rotY );
    }

    //// COMPUTE SHADERS ////////////////////////////////////////////////////////////
    // Not supported in ReShade (?)

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_BlackandWhite(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        // Levels
        color.xyz         = max( color.xyz - inBlack.xyz, 0.0f )/max( inWhite.xyz - inBlack.xyz, 0.000001f );
        color.xyz         = pow( color.xyz, Gamma );
        color.xyz         = color.xyz * max( White.xyz - Black.xyz, 0.000001f ) + Black.xyz;
        color.xyz         = max( color.xyz, 0.0f );
        // B & W conversion options
        // Technique 1: Selection of any RGB to create the B&W image
        float gsMult      = dot( luminosity.xyz, 1.0f );
        float3 greyscale  = luminosity.xyz / gsMult;
        color.xyz         = dot( color.xyz, greyscale.xyz );
        // Technique 2: Use multiplification of R G B or Luma channel to create B&W image
        // TODO

        return float4( color.xyz, 1.0f ); // Writes to texColorNew
    }
    
    float4 PS_GaussianH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColorNew, texcoord );
        float SigmaSum    = 0.0f;
        float pxlOffset   = 1.0f;
        float3 Sigma;
        Sigma.x           = 1.0f / ( sqrt( 2.0f * Pi ) * BlurSigma );
        Sigma.y           = exp( -0.5f / ( BlurSigma * BlurSigma ));
        Sigma.z           = Sigma.y * Sigma.y;
        color.xyz         *= Sigma.x;
        SigmaSum          += Sigma.x;
        Sigma.xy          *= Sigma.yz;
        for( int i = 0; i < Loops && SigmaSum <= Quality; ++i )
        {
            color         += tex2D( samplerColorNew, texcoord.xy + float2( pxlOffset*px, 0.0f )) * Sigma.x;
            color         += tex2D( samplerColorNew, texcoord.xy - float2( pxlOffset*px, 0.0f )) * Sigma.x;
            SigmaSum      += ( 2.0f * Sigma.x );
            pxlOffset     += 1.0f;
            Sigma.xy      *= Sigma.yz;
        }
        color.xyz         /= SigmaSum;
        return float4( color.xyz, 1.0f ); // Writes to texBlurH
    }
    
    float4 PS_GaussianV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerBlurH, texcoord );
        float SigmaSum    = 0.0f;
        float pxlOffset   = 1.0f;
        float3 Sigma;
        Sigma.x           = 1.0f / ( sqrt( 2.0f * Pi ) * BlurSigma );
        Sigma.y           = exp( -0.5f / ( BlurSigma * BlurSigma ));
        Sigma.z           = Sigma.y * Sigma.y;
        color.xyz         *= Sigma.x;
        SigmaSum          += Sigma.x;
        Sigma.xy          *= Sigma.yz;
        for( int i = 0; i < Loops && SigmaSum < Quality; ++i )
        {
            color         += tex2D( samplerBlurH, texcoord.xy + float2( 0.0f, pxlOffset*py )) * Sigma.x;
            color         += tex2D( samplerBlurH, texcoord.xy - float2( 0.0f, pxlOffset*py )) * Sigma.x;
            SigmaSum      += ( 2.0f * Sigma.x );
            pxlOffset     += 1.0f;
            Sigma.xy      *= Sigma.yz;
        }
        color.xyz         /= SigmaSum;
        return float4( color.xyz, 1.0f ); // Writes to texBlur
    }

    float4 PS_BloomDeband(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerBlur, texcoord );
        float avgdiff     = 3.4f / 255.0f;
        float maxdiff     = 6.8f / 255.0f;
        float middiff     = 3.3f / 255.0f;
        float h           = permute( permute( permute( texcoord.x ) + texcoord.y ) + drandom / 32767.0f );
        float3 ref_avg;
        float3 ref_avg_diff;
        float3 ref_max_diff;
        float3 ref_mid_diff1;
        float3 ref_mid_diff2;
        float3 ori        = color.xyz;
        float3 res;
        float dir         = rand( permute( h )) * 6.2831853f;
        float2 o          = float2( cos( dir ), sin( dir ));
        for ( int i = 1; i <= 4; ++i )
        {
            float dist    = rand(h) * 24.0f * i;
            float2 pt     = dist * ReShade::PixelSize;
            analyze_pixels(ori, samplerBlur, texcoord, pt, o,
                            ref_avg,
                            ref_avg_diff,
                            ref_max_diff,
                            ref_mid_diff1,
                            ref_mid_diff2);
            float3 ref_avg_diff_threshold = avgdiff * i;
            float3 ref_max_diff_threshold = maxdiff * i;
            float3 ref_mid_diff_threshold = middiff * i;
            float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / ref_avg_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_max_diff  / ref_max_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_mid_diff1 / ref_mid_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_mid_diff2 / ref_mid_diff_threshold)), 0.1);
            res           = lerp(ori, ref_avg, factor);
            h             = permute(h);
        }
        const float dither_bit  = 8.0f;
        float grid_position     = frac(dot(texcoord, (ReShade::ScreenSize * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25));
        float dither_shift      = 0.25 * (1.0 / (pow(2, dither_bit) - 1.0));
        float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift);
        dither_shift_RGB        = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.
        res                     += dither_shift_RGB;
        color.xyz               = res.xyz;
        return float4( color.xyz, 1.0f ); // Writes to texBlurDeband
    }

    float4 PS_BlendImgBlur(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColorNew, texcoord );
        float4 blur       = tex2D( samplerBlurDeband, texcoord );
        float4 orig       = tex2D( samplerColor, texcoord );
        float3 blend      = 0.0f;
        // Blending options (blur)
        if( BlendModeB == 0 ) {
            blend.xyz     = blur.xyz;
        }
        if( BlendModeB == 1 ) {
            blend.xyz     = darken( color.xyz, blur.xyz);
        }
        if( BlendModeB == 2 ) {
            blend.xyz     = multiply( color.xyz, blur.xyz);
        }
        if( BlendModeB == 3 ) {
            blend.xyz     = linearburn( color.xyz, blur.xyz);
        }
        if( BlendModeB == 4 ) {
            blend.xyz     = colorburn( color.xyz, blur.xyz);
        }
        if( BlendModeB == 5 ) {
            blend.xyz     = lighten( color.xyz, blur.xyz);
        }
        if( BlendModeB == 6 ) {
            blend.xyz     = screen( color.xyz, blur.xyz);
        }
        if( BlendModeB == 7 ) {
            blend.xyz     = colordodge( color.xyz, blur.xyz);
        }
        if( BlendModeB == 8 ) {
            blend.xyz     = lineardodge( color.xyz, blur.xyz);
        }
        if( BlendModeB == 9 ) {
            blend.xyz     = overlay( color.xyz, blur.xyz);
        }
        if( BlendModeB == 10 ) {
            blend.xyz     = softlight( color.xyz, blur.xyz);
        }
        if( BlendModeB == 11 ) {
            blend.xyz     = vividlight( color.xyz, blur.xyz);
        }
        if( BlendModeB == 12 ) {
            blend.xyz     = linearlight( color.xyz, blur.xyz);
        }
        if( BlendModeB == 13 ) {
            blend.xyz     = pinlight( color.xyz, blur.xyz);
        }
        color.xyz         = lerp( color.xyz, blend.xyz, opacityB );
        // For color grading options (non blur or gradient)
        if( use_unblur ) {
            blur.xyz      = color.xyz;
        }
        if( use_gradient ) {
            float3 darkC  = DarkColor.xyz;
            float3 lightC = LightColor.xyz;
            float lum     = dot( color.xyz, 0.333333f ); // Image is greyscale, this is average
            float adjDark = max( max( darkC.x, darkC.y ), darkC.z );
            adjDark       = 1.0f / adjDark; // Scalar to always make color adjustment fullt saturated so it can be multiplied
            darkC.xyz     *= adjDark;
            float adjLight= max( max( lightC.x, lightC.y ), lightC.z );
            adjLight      = 1.0f / adjLight; // Same scalar as Dark
            lightC.xyz    *= adjLight;
            blur.xyz      = lerp( darkC.xyz, lightC.xyz, lum ); // Create colored gradient
        }
        // Blending options
        //float2 check      = float2( use_unblur, use_gradient );
        if( use_unblur || use_gradient ) {
            if( BlendMode == 0 ) {
                blend.xyz     = blur.xyz;
            }
            if( BlendMode == 1 ) {
                blend.xyz = darken( color.xyz, blur.xyz);
            }
            if( BlendMode == 2 ) {
                blend.xyz = multiply( color.xyz, blur.xyz);
            }
            if( BlendMode == 3 ) {
                blend.xyz = linearburn( color.xyz, blur.xyz);
            }
            if( BlendMode == 4 ) {
                blend.xyz = colorburn( color.xyz, blur.xyz);
            }
            if( BlendMode == 5 ) {
                blend.xyz = lighten( color.xyz, blur.xyz);
            }
            if( BlendMode == 6 ) {
                blend.xyz = screen( color.xyz, blur.xyz);
            }
            if( BlendMode == 7 ) {
                blend.xyz = colordodge( color.xyz, blur.xyz);
            }
            if( BlendMode == 8 ) {
                blend.xyz = lineardodge( color.xyz, blur.xyz);
            }
            if( BlendMode == 9 ) {
                blend.xyz = overlay( color.xyz, blur.xyz);
            }
            if( BlendMode == 10 ) {
                blend.xyz = softlight( color.xyz, blur.xyz);
            }
            if( BlendMode == 11 ) {
                blend.xyz = vividlight( color.xyz, blur.xyz);
            }
            if( BlendMode == 12 ) {
                blend.xyz = linearlight( color.xyz, blur.xyz);
            }
            if( BlendMode == 13 ) {
                blend.xyz = pinlight( color.xyz, blur.xyz);
            }
            color.xyz     = lerp( color.xyz, blend.xyz, opacity );
        }
        if( blendOrig ) {
            blur.xyz      = orig.xyz;
            if( flipColorBlend ) {
                blur.xyz  = color.xyz;
                color.xyz = orig.xyz;
            }
            if( BlendModeO == 0 ) {
                blend.xyz     = blur.xyz;
            }
            if( BlendModeO == 1 ) {
                blend.xyz = darken( color.xyz, blur.xyz);
            }
            if( BlendModeO == 2 ) {
                blend.xyz = multiply( color.xyz, blur.xyz);
            }
            if( BlendModeO == 3 ) {
                blend.xyz = linearburn( color.xyz, blur.xyz);
            }
            if( BlendModeO == 4 ) {
                blend.xyz = colorburn( color.xyz, blur.xyz);
            }
            if( BlendModeO == 5 ) {
                blend.xyz = lighten( color.xyz, blur.xyz);
            }
            if( BlendModeO == 6 ) {
                blend.xyz = screen( color.xyz, blur.xyz);
            }
            if( BlendModeO == 7 ) {
                blend.xyz = colordodge( color.xyz, blur.xyz);
            }
            if( BlendModeO == 8 ) {
                blend.xyz = lineardodge( color.xyz, blur.xyz);
            }
            if( BlendModeO == 9 ) {
                blend.xyz = overlay( color.xyz, blur.xyz);
            }
            if( BlendModeO == 10 ) {
                blend.xyz = softlight( color.xyz, blur.xyz);
            }
            if( BlendModeO == 11 ) {
                blend.xyz = vividlight( color.xyz, blur.xyz);
            }
            if( BlendModeO == 12 ) {
                blend.xyz = linearlight( color.xyz, blur.xyz);
            }
            if( BlendModeO == 13 ) {
                blend.xyz = pinlight( color.xyz, blur.xyz);
            }
            color.xyz     = lerp( color.xyz, blend.xyz, opacityO );
        }
        // Contrast & Brightness
        color.xyz         = saturate( lerp( color.xyz, softlight( color.xyz, color.xyz ), contrast ));
        color.xyz         = saturate( lerp( color.xyz, screen( color.xyz, color.xyz ), brightness ));
        return float4( color.xyz, 1.0f ); // Final output
    }

    float4 PS_AfterFX_CA(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerBlended, texcoord );
        if( use_ca ) {
            float3 orig   = color.xyz;
            float CAwidth = CA;
            float adj     = 1.0f;
            float2 adjRad = 1.0f;
            if( use_ca_edges ) {
                float2 coords = texcoord.xy;
                coords.xy     -= 0.5f;
                adjRad.xy     = coords.xy * 2.0f;
                coords.xy     = abs( coords.xy );
                adj           = adj * pow( max( coords.x, coords.y ) * 2.0f, 0.5f );
            }
            float cos     = cos( radians( degrees )) * adjRad.x;
            float sin     = sin( radians( degrees )) * adjRad.y;
            color.x       = tex2D( samplerBlended, texcoord + float2( px * cos * CAwidth * adj, py * sin * CAwidth * adj )).x;
            color.z       = tex2D( samplerBlended, texcoord - float2( px * cos * CAwidth * adj, py * sin * CAwidth * adj )).z;
            color.xyz     = lerp( orig.xyz, color.xyz, CA_strength );
        }
        return float4( color.xyz, 1.0f );
    }

    float4 PS_AfterFX_Grain(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerAfterFX1, texcoord );
        if ( use_grain )
        {
            float3 rotOffset  = float3( 1.425f, 3.892f, 5.835f ); // Rotation offset values (RGB)
            float2 rotCoordsR = coordRot( texcoord.xy, timer + rotOffset.x );
            float2 rotCoordsG = coordRot( texcoord.xy, timer + rotOffset.y );
            float2 rotCoordsB = coordRot( texcoord.xy, timer + rotOffset.z );
            float3 noise      = pnoise3D( float3( rotCoordsR.xy * float2( BUFFER_WIDTH * 0.625f, BUFFER_HEIGHT * 0.625f ), 0.0f ), texcoord.xy); // 0.625f arbitrary value which gave good results. Rotation set to 0 degrees
            noise.y           = pnoise3D( float3( rotCoordsG.xy * float2( BUFFER_WIDTH * 0.625f, BUFFER_HEIGHT * 0.625f ), 1.0f / 3.0f ), texcoord.xy); // rotated 120 degrees
            noise.z           = pnoise3D( float3( rotCoordsB.xy * float2( BUFFER_WIDTH * 0.625f, BUFFER_HEIGHT * 0.625f ), 2.0f / 3.0f ), texcoord.xy); // rotated 240 degrees
            noise.xyz         *= grainIntensity;
            noise.xyz         = lerp( dot( noise.xyz, float3( 0.212656, 0.715158, 0.072186 )), noise.xyz, grainColor ); // Grey or color noise
            float lum         = dot( color.xyz, 0.333333f ); // Just using average here
            noise.xyz         = lerp( noise.xyz * grainIntLow, noise.xyz * grainIntHigh, fade( lum )); // Noise adjustments based on luma
            color.xyz         = lerp( color.xyz, color.xyz + noise.xyz, grainAmount );
        }
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_Black_and_White
    {
        pass prod80_BlackandWhite
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BlackandWhite;
            RenderTarget  = texColorNew;
        }
        pass prod80_BlurH
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_GaussianH;
            RenderTarget  = texBlurH;
        }
        pass prod80_Blur
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_GaussianV;
            RenderTarget  = texBlur;
        }
        pass prod80_BlurDeband
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BloomDeband;
            RenderTarget  = texBlurDeband;
        }
        pass prod80_Blend
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BlendImgBlur;
            RenderTarget  = texBlended;
        }
        pass prod80_AfterFX1
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_AfterFX_CA;
            RenderTarget  = texAfterFX1;
        }
        pass prod80_AfterFX2
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_AfterFX_Grain;
        }
    }
}


