/*------------------.
| :: Description :: |
'-------------------/

	Splitscreen (version 3.0)

	Version 0.0 - 2.0 Author: CeeJay.dk
	Version 3.0 - 3.0 Author: Charles Fettinger
	License: MIT
	

	About:
	Displays the image before and after it has been modified by effects using a splitscreen
	Initial is to be placed as the first effect, so that before images can be prestine
    

	Ideas for future improvement:
    *

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 1.0
    * Does a splitscreen before/after view
    
	Version 2.0
    * Ported to Reshade 3.x
    * Added UI settings.
    * Added Diagonal split mode
    - Removed curvy mode. I didn't like how it looked.
    - Threatened other modes to behave or they would be next.

    Version 3.0
    * add ability to swap the content areas
    * add Initial sample to allow prestine application of effects to main section of effects
    - Splitscreen is not Initial/Before/After
    * add ability to split on COLORs: Green, Blue, Black and White and NON-SPLIT or ALL
*/

/*------------------.
| :: UI Settings :: |
'------------------*/

#include "ReShadeUI.fxh"

uniform int splitscreen_mode <
    ui_type = "combo";
    ui_label = "Mode";
    ui_tooltip = "Choose a mode";
    //ui_category = "";
    ui_items = 
    "Vertical 50/50 split\0"
    "Vertical 25/50/25 split\0"
    "Angled 50/50 split\0"
    "Angled 25/50/25 split\0"
    "Horizontal 50/50 split\0"
    "Horizontal 25/50/25 split\0"    
    "Diagonal split\0"
    "Circle split\0"
    "White pixels\0"
    "Green Ultimatte(tm) pixels\0"
    "Super Blue Ultimatte(tm) pixels\0"
    "Black pixels\0"
    "MWO - Horz 25/50/25 With Green Ultimatte(tm) pixels\0"
    "All\0"
    ;
> = 0;

uniform bool invert_split<
	ui_label = "Invert Split Areas";
	ui_tooltip = "swap content of split areas";
> = false;

uniform bool use_initial<
	ui_label = "Apply effects to Initial Sample Only";
	ui_tooltip = "Apply effects group to Initial Image not on top of Before sample";
> = false;

/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"


/*-------------------------.
| :: Texture and sampler:: |
'-------------------------*/

texture Initial { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler Initial_sampler { Texture = Initial; };

texture Before { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler Before_sampler { Texture = Before; };


/*-------------.
| :: Effect :: |
'-------------*/

float4 Apply_Split(float4 pos, float2 texcoord, float4 color_before, float4 color_after, float4 color_initial)
{
	float4 color; 

	    // -- Vertical 50/50 split --
    [branch] if (splitscreen_mode == 0)
        color = (texcoord.x < 0.5 ) ? color_before : color_after;

    // -- Vertical 25/50/25 split --
    [branch] if (splitscreen_mode == 1)
    {
        //Calculate the distance from center
        float dist = abs(texcoord.x - 0.5);
        
        //Further than 1/4 away from center?
        dist = saturate(dist - 0.25);
        
        color = dist ? color_before : color_after;
	}

    // -- Angled 50/50 split --
    [branch] if (splitscreen_mode == 2)
    {
        //Calculate the distance from center
        float dist = ((texcoord.x - 3.0/8.0) + (texcoord.y * 0.25));

        //Further than 1/4 away from center?
        dist = saturate(dist - 0.25);

        color = dist ? color_after : color_before;
    }

    // -- Angled 25/50/25 split --
    [branch] if (splitscreen_mode == 3)
    {
        //Calculate the distance from center
        float dist = ((texcoord.x - 3.0/8.0) + (texcoord.y * 0.25));

        dist = abs(dist - 0.25);

        //Further than 1/4 away from center?
        dist = saturate(dist - 0.25);

        color = dist ? color_before : color_after;
    }
  
    // -- Horizontal 50/50 split --
    [branch] if (splitscreen_mode == 4)
	    color =  (texcoord.y < 0.5) ? color_before : color_after;
	
    // -- Horizontal 25/50/25 split --
    [branch] if (splitscreen_mode == 5)
    {
        //Calculate the distance from center
        float dist = abs(texcoord.y - 0.5);
        
        //Further than 1/4 away from center?
        dist = saturate(dist - 0.2575);
        
        color = dist ? color_before : color_after;
    }

    // -- Diagonal split --
    [branch] if (splitscreen_mode == 6)
    {
        //Calculate the distance from center
        float dist = (texcoord.x + texcoord.y);
        
        //Further than 1/2 away from center?
        //dist = saturate(dist - 1.0);
        
        color = (dist < 1.0) ? color_before : color_after;
    }

     // -- Circle split --
    [branch] if (splitscreen_mode == 7)
    {    	
    	float dist = distance(texcoord.xy, float2(0.5,0.5)) * float2((ReShade::PixelSize.y / ReShade::PixelSize.x), 1.0) ;

    	color = (dist <= 0.55) ? color_before : color_after; 
    }

    // -- White Pixels -- must use intiial
    [branch] if (splitscreen_mode == 8)
    {
    	color = (distance(color_before.rgb, float3(1.0,1.0,1.0)) <= 0.075) ? color_after : color_before; 
    }

    // -- Green Pixels -- must use intiial
    [branch] if (splitscreen_mode == 9)
    {
    	color = (distance(color_before.rgb,float3(0.29, 0.84, 0.36)) <= 0.075 ) ? color_after : color_before; 
    }

    // -- Blue Pixels -- must use intiial
    [branch] if (splitscreen_mode == 10)
    {
    	color = (distance(color_before.rgb,float3(0.07, 0.18, 0.72)) <= 0.075 ) ? color_after : color_before; 
    }

    // -- White Pixels -- must use intiial
    [branch] if (splitscreen_mode == 11)
    {
    	color = (distance(color_before.rgb, float3(0.0,0.0,0.0)) <= 0.075) ? color_after : color_before; 
    }
    
    // -- Green Pixels -- must use intiial
    [branch] if (splitscreen_mode == 12)
    {
    	//Calculate the distance from center
        float dist = abs(texcoord.y - 0.5);
        
        //Further than 1/4 away from center?
        dist = saturate(dist - 0.2575);
        
        color = dist ? color_initial : ((distance(color_before.rgb,float3(0.29, 0.84, 0.36)) <= 0.075 ) ? color_after : color_before);
    }

    // -- ALL  --
    [branch] if (splitscreen_mode == 13)
    {
    	color = color_after;
    }
    return color;
}

float4 PS_Initial(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return tex2D(ReShade::BackBuffer, texcoord);
}

float4 PS_Before(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{	
	return tex2D(ReShade::BackBuffer, texcoord);    
}

float4 PS_Before_OutputInitial(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{	
    return (use_initial) ? tex2D(Initial_sampler, texcoord) : tex2D(ReShade::BackBuffer, texcoord);
}

float4 PS_After(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 color; 
    float4 color_init = tex2D(Initial_sampler, texcoord);
    float4 color_bef = tex2D(Before_sampler, texcoord);
    float4 color_aft = tex2D(ReShade::BackBuffer, texcoord);

    if (invert_split)
    {
    	color = color_aft;
    	color_aft = color_bef;
    	color_bef = color;
    }
    
    color =  Apply_Split(pos, texcoord, color_bef, color_aft, color_init);

 	return color;
}


/*-----------------.
| :: Techniques :: |
'-----------------*/

technique Initial < ui_label = "Initial Effect Sample"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Initial;
        RenderTarget = Initial;
    }
}

technique Before < ui_label = "Start of Effect Group"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Before;
        RenderTarget = Before;
    }

    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Before_OutputInitial;
    }
}

technique After < ui_label = "End of Effect Group"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_After;
    }
}