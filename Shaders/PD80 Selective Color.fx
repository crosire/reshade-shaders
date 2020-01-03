/* 
Selective Coloring shader for ReShade by prod80
Based on the mathematical analysis on http://blog.pkh.me/p/22-understanding-selective-coloring-in-adobe-photoshop.html
Version 1.3
*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

namespace pd80_selectivecolor
{

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int corr_method < __UNIFORM_COMBO_INT1
        ui_label = "Correction Method";
        ui_category = "Selective Color";
        ui_items = "Absolute\0Relative\0"; //Do not change order; 0=Absolute, 1=Relative
        > = 1;
    // Reds
    uniform float r_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Yellows
    uniform float y_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Greens
    uniform float g_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Cyans
    uniform float c_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Blues
    uniform float b_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Magentas
    uniform float m_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Whites
    uniform float w_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Neutrals
    uniform float n_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    // Blacks
    uniform float bk_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// BUFFERS ////////////////////////////////////////////////////////////////////
    // Not supported in ReShade (?)

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float mid( float3 c )
    {
        /*
        Return the middle value, standard comparison math
        x > y, z > y, z > x, mid=x, else mid=z
        else 
        y > z, z > x, mid=z, else mid=x
        both false, mid=y
        */
        if( c.x > c.y ) {
            if( c.z > c.y ) {
                if( c.z > c.x ) c.y = c.x;
                else            c.y = c.z;
            }
        } else {
            if( c.y > c.z ) {
                if( c.z > c.x ) c.y = c.z;
                else            c.y = c.x;
            }
        }
        return c.y;
    }

    float adjustcolor( float scale, float colorvalue, float adjust, float bk, int method )
    {
        /* 
        y(value, adjustment) = clamp((( -1 - adjustment ) * bk - adjustment ) * method, -value, 1 - value ) * scale
        absolute: method = 1.0f - colorvalue * 0
        relative: method = 1.0f - colorvalue * 1
        */
        return clamp((( -1.0f - adjust ) * bk - adjust ) * ( 1.0f - colorvalue * method ), -colorvalue, 1.0f - colorvalue) * scale;
    }

    //// COMPUTE SHADERS ////////////////////////////////////////////////////////////
    // Not supported in ReShade (?)

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_SelectiveColor(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        
        // Clamp 0..1
        color.xyz         = saturate( color.xyz );

        // Need these a lot
        float min_value   = min( min( color.x, color.y ), color.z );
        float max_value   = max( max( color.x, color.y ), color.z );
        
        // Used for determining which pixels to adjust regardless of prior changes to color
        float3 orig       = color.xyz;

        // Scales
        float sRGB        = max_value - mid( color.xyz );
        float sCMY        = mid( color.xyz ) - min_value;
        float sNeutrals   = 1.0f - ( abs( max_value - 0.5f ) + abs( min_value - 0.5f ));
        float sWhites     = ( min_value - 0.5f ) * 2.0f;
        float sBlacks     = ( 0.5f - max_value ) * 2.0f;

        // Selective Color
        if( any( float4( r_adj_cya, r_adj_mag, r_adj_yel, r_adj_bla )))
        {
            if( max_value == orig.x )
            {
                color.x       = color.x + adjustcolor( sRGB, color.x, r_adj_cya, r_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sRGB, color.y, r_adj_mag, r_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sRGB, color.z, r_adj_yel, r_adj_bla, corr_method );
            }
        }
        if( any( float4( y_adj_cya, y_adj_mag, y_adj_yel, y_adj_bla )))
        {
            if( min_value == orig.z )
            {
                color.x       = color.x + adjustcolor( sCMY, color.x, y_adj_cya, y_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sCMY, color.y, y_adj_mag, y_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sCMY, color.z, y_adj_yel, y_adj_bla, corr_method );
            }
        }
        if( any( float4( g_adj_cya, g_adj_mag, g_adj_yel, g_adj_bla )))
        {
            if( max_value == orig.y )
            {
                color.x       = color.x + adjustcolor( sRGB, color.x, g_adj_cya, g_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sRGB, color.y, g_adj_mag, g_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sRGB, color.z, g_adj_yel, g_adj_bla, corr_method );
            }
        }
        if( any( float4( c_adj_cya, c_adj_mag, c_adj_yel, c_adj_bla )))
        {
            if( min_value == orig.x )
            {
                color.x       = color.x + adjustcolor( sCMY, color.x, c_adj_cya, c_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sCMY, color.y, c_adj_mag, c_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sCMY, color.z, c_adj_yel, c_adj_bla, corr_method );
            }
        }
        if( any( float4( b_adj_cya, b_adj_mag, b_adj_yel, b_adj_bla )))
        {
            if( max_value == orig.z )
            {
                color.x       = color.x + adjustcolor( sRGB, color.x, b_adj_cya, b_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sRGB, color.y, b_adj_mag, b_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sRGB, color.z, b_adj_yel, b_adj_bla, corr_method );
            }
        }
        if( any( float4( m_adj_cya, m_adj_mag, m_adj_yel, m_adj_bla )))
        {
            if( min_value == orig.y )
            {
                color.x       = color.x + adjustcolor( sCMY, color.x, m_adj_cya, m_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sCMY, color.y, m_adj_mag, m_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sCMY, color.z, m_adj_yel, m_adj_bla, corr_method );
            }
        }
        if( any( float4( w_adj_cya, w_adj_mag, w_adj_yel, w_adj_bla )))
        {
            if( min_value >= 0.5f )
            {
                color.x       = color.x + adjustcolor( sWhites, color.x, w_adj_cya, w_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sWhites, color.y, w_adj_mag, w_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sWhites, color.z, w_adj_yel, w_adj_bla, corr_method );
            }
        }
        if( any( float4( n_adj_cya, n_adj_mag, n_adj_yel, n_adj_bla )))
        {   
            if( max_value != 0.0f && min_value != 1.0f )
            {
                color.x       = color.x + adjustcolor( sNeutrals, color.x, n_adj_cya, n_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sNeutrals, color.y, n_adj_mag, n_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sNeutrals, color.z, n_adj_yel, n_adj_bla, corr_method );
            }
        }
        if( any( float4( bk_adj_cya, bk_adj_mag, bk_adj_yel, bk_adj_bla )))
        {
            if( max_value < 0.5f )
            {
                color.x       = color.x + adjustcolor( sBlacks, color.x, bk_adj_cya, bk_adj_bla, corr_method );
                color.y       = color.y + adjustcolor( sBlacks, color.y, bk_adj_mag, bk_adj_bla, corr_method );
                color.z       = color.z + adjustcolor( sBlacks, color.z, bk_adj_yel, bk_adj_bla, corr_method );
            }
        }
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_SelectiveColor
    {
        pass prod80_sc
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_SelectiveColor;
        }
    }
}


