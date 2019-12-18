////-----------//
///**Depth3D**///
//-----------////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//* Depth Map Based 3D post-process shader v2.0.7
//* For Reshade 3.0+
//* ---------------------------------
//*
//* Original work was based on the shader code from
//* CryTech 3 Dev http://www.slideshare.net/TiagoAlexSousa/secrets-of-cryengine-3-graphics-technology
//* Also Fu-Bama a shader dev at the reshade forums https://reshade.me/forum/shader-presentation/5104-vr-universal-shader
//* Also had to rework Philippe David http://graphics.cs.brown.edu/games/SteepParallax/index.html code to work with reshade. This is used for the parallax effect.
//* This idea was taken from this shader here located at https://github.com/Fubaxiusz/fubax-shaders/blob/596d06958e156d59ab6cd8717db5f442e95b2e6b/Shaders/VR.fx#L395
//* It's also based on Philippe David Steep Parallax mapping code. If I missed any information please contact me so I can make corrections.
//*
//* LICENSE
//* ============
//* Code out side the work of people mention above is licenses under: Attribution-NoDerivatives 4.0 International
//*
//* You are free to:
//* Share - copy and redistribute the material in any medium or format
//* for any purpose, even commercially.
//* The licensor cannot revoke these freedoms as long as you follow the license terms.
//* Under the following terms:
//* Attribution - You must give appropriate credit, provide a link to the license, and indicate if changes were made.
//* You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
//*
//* NoDerivatives - If you remix, transform, or build upon the material, you may not distribute the modified material.
//*
//* No additional restrictions - You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
//*
//* https://creativecommons.org/licenses/by-nd/4.0/
//*
//* Have fun,
//* Jose Negrete AKA BlueSkyDefender
//*
//* https://github.com/BlueSkyDefender/Depth3D
//* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader
//* https://Depth3D.info
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//USER EDITABLE PREPROCESSOR FUNCTIONS START//

// -=UI Mask Texture Mask Intercepter=- This is used to set Two UI Masks for any game. Keep this in mind when you enable UI_MASK.
// You Will have to create Three PNG Textures named DM_Mask.png with transparency for this option.
// They will also need to be the same resolution as what you have set for the game and the color black where the UI is.
// This is needed for games like RTS since the UI will be set in depth. This corrects this issue.
#if exists "DM_Mask.png"
	#define UI_MASK 1
#else
	#define UI_MASK 0
#endif
// To cycle through the textures set a Key. The Key Code for "n" is Key Code Number 78. Default is Numpad Decimal 110.
#define Mask_Cycle_Key 110 // You can use http://keycode.info/ to figure out what key is what.
// Texture EX. Before |::::::::::| After |**********|
//                    |:::       |       |***       |
//                    |:::_______|       |***_______|
// So :::: are UI Elements in game. The *** is what the Mask needs to cover up.
// The game part needs to be trasparent and the UI part needs to be black.

// The Key Code for the mouse is 0-4 key 1 is right mouse button.
#define Fade_Key 1 // You can use http://keycode.info/ to figure out what key is what.
#define Fade_Time_Adjust 0.5625 // From 0 to 1 is the Fade Time adjust for this mode. Default is 0.5625;

//USER EDITABLE PREPROCESSOR FUNCTIONS END//
#include "ReShadeUI.fxh"
#include "ReShade.fxh"

//Divergence & Convergence//
uniform float Divergence <
	ui_type = "drag";
	ui_min = 10; ui_max = 60; ui_step = 0.25;
	ui_label = "Divergence Slider";
	ui_tooltip = "Divergence increases differences between the left and right retinal images and allows you to experience depth.\n"
							 "The process of deriving binocular depth information is called stereopsis.";
	ui_category = "Divergence & Convergence";
> = 25;

uniform float ZPD <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.250;
	ui_label = "Convergence";
	ui_tooltip = "ZPD controls the focus distance for the screen Pop-out effect also known as ZPD.\n"
							 "For FPS Games keeps this low Since you don't want your gun to pop out of screen.\n"
							 "This is controled by Convergence Mode.\n"
							 "Default is 0.025, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.025;

uniform int Auto_Balance_Ex <
	ui_type = "slider";
	ui_min = 0; ui_max = 2;
	ui_label = "Auto Balance";
	ui_tooltip = "Automatically Balance between ZPD Depth and Scene Depth.\n"
				 			 "Default is Off.";
	ui_category = "Divergence & Convergence";
> = 0;

uniform int ZPD_Boundary <
	ui_type = "combo";
	ui_items = "Off\0Normal\0FPS\0Edge\0";
	ui_label = "Screen Boundary Detection";
	ui_tooltip = "This selection menu gives extra boundary conditions to ZPD.\n"
				 			 "This treats your screen as a virtual wall.\n"
				 		   "Default is Off.";
	ui_category = "Divergence & Convergence";
> = 0;

uniform int View_Mode <
	ui_type = "combo";
	ui_items = "View Mode Normal\0View Mode Alpha\0";
	ui_label = "View Mode";
	ui_tooltip = "Changes the way the shader fills in the occlude section in the image.\n"
               "Normal is default output and Alpha is used for higher ammounts of Semi-Transparent objects.\n"
				 		 	 "Default is Normal";
	ui_category = "Occlusion Masking";
> = 0;

uniform int Custom_Sidebars <
	ui_type = "combo";
	ui_items = "Mirrored Edges\0Black Edges\0Stretched Edges\0";
	ui_label = "Edge Handling";
	ui_tooltip = "Edges consideration selection for cropping.";
	ui_category = "Occlusion Masking";
> = 1;

uniform bool Performance_Mode <
	ui_label = "Performance Mode";
	ui_tooltip = "Performance Mode Lowers Occlusion Quality Processing so that there is a small boost to FPS.\n"
							 "Default is off.";
	ui_category = "Occlusion Masking";
> = false;

uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "Depth Normal\0Depth Reversed\0";
	ui_label = "Depth Map Selection";
	ui_tooltip = "Linearization for the zBuffer also known as Depth Map.\n"
			     		 "DM0 is Z-Normal and DM1 is Z-Reversed.\n";
	ui_category = "Depth Map";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 1.0; ui_max = 250.0; ui_step = 0.125;
	ui_label = "Depth Map Adjustment";
	ui_tooltip = "This allows for you to adjust the DM precision.\n"
							 "Adjust this to keep it as low as possible.\n"
							 "Default is 7.5";
	ui_category = "Depth Map";
> = 7.5;

uniform float Offset <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Depth Map Offset";
	ui_tooltip = "Depth Map Offset is for non conforming ZBuffer.\n"
							 "It's rare if you need to use this in any game.\n"
							 "Use this to make adjustments to DM 0 or DM 1.\n"
							 "Default and starts at Zero and it's Off.";
	ui_category = "Depth Map";
> = 0.0;

uniform bool Depth_Detection <
	ui_label = "Depth Detection";
	ui_tooltip = "Use this to dissable/enable in game Depth Detection.";
	ui_category = "Depth Map";
> = false;

uniform bool Depth_Map_Flip <
	ui_label = "Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
	ui_category = "Depth Map";
> = false;

uniform bool Depth_View <
	ui_label = "Depth View";
	ui_tooltip = "Use this to to figure out if depth is working in your game.";
	ui_category = "Depth Map";
> = false;

uniform int WP <
	ui_type = "combo";
	ui_items = "Weapon Profile Off\0Custom WP\0";
	ui_label = "Weapon Profiles";
	ui_tooltip = "Make a Weapon Profile for your game.";
	ui_category = "Weapon Hand Adjust";
> = 0;

uniform float3 Weapon_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 250.0;
	ui_label = "Weapon Hand Adjust";
	ui_tooltip = "Adjust Weapon depth map for your games.\n"
							 "X, CutOff Point used to set a diffrent scale for first person hand apart from world scale.\n"
							 "Y, Precision is used to adjust the first person hand in world scale.\n"
	             "Default is float2(X 0.0, Y 0.0, Z 0.0)";
	ui_category = "Weapon Hand Adjust";
> = float3(0.0,0.0,0.0);

uniform int FPSDFIO <
	ui_type = "combo";
	ui_items = "Off\0Press\0Hold Down\0";
	ui_label = "FPS Focus Depth";
	ui_tooltip = "This lets the shader handle real time depth reduction for aiming down your sights.\n"
							 "This may induce Eye Strain so take this as an Warning.";
	ui_category = "Weapon Hand Adjust";
> = 0;

uniform int2 Eye_Fade_Reduction_n_Power <
	ui_type = "slider";
	ui_min = 0; ui_max = 2;
	ui_label = "Eye Selection & Fade Reduction";
	ui_tooltip = "Fade Reduction decresses the depth ammount by a current percentage.\n"
							 "One is Right Eye only, Two is Left Eye Only, and Zero Both Eyes.\n"
							 "Default is int( X 0 , Y 0 ).";
	ui_category = "Weapon Hand Adjust";
> = int2(0,0);

uniform float Weapon_ZPD_Boundary <
	ui_type = "slider";
	ui_min = 0; ui_max = 0.5;
	ui_label = " Weapon Screen Boundary Detection";
	ui_tooltip = "This selection menu gives extra boundary conditions to WZPD.";
	ui_category = "Weapon Hand Adjust";
> = 0;
//Heads-Up Display
uniform float2 HUD_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "HUD Mode";
	ui_tooltip = "Adjust HUD for your games.\n"
							 "X, CutOff Point used to set a seperation point bettwen world scale and the HUD also used to turn HUD MODE On or Off.\n"
							 "Y, Pushes or Pulls the HUD in or out of the screen if HUD MODE is on.\n"
							 "This is only for UI elements that show up in the Depth Buffer.\n"
	             "Default is float2(X 0.0, Y 0.5)";
	ui_category = "Heads-Up Display";
> = float2(0.0,0.5);
//Stereoscopic Options
uniform int Stereoscopic_Mode <
	ui_type = "combo";
	ui_items = "Side by Side Half & VR Theater\0Top and Bottom\0Line Interlaced\0Anaglyph 3D Red/Cyan\0Anaglyph 3D Green/Magenta\0";
	ui_label = "3D Display Modes";
	ui_tooltip = "Stereoscopic 3D display output selection.\n"
							 "Use your favorite VR app to add the correct barrel distortion for VR.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform int Perspective <
	ui_type = "drag";
	ui_min = -100; ui_max = 100;
	ui_label = "Perspective Slider";
	ui_tooltip = "Determines the perspective point of the two images this shader produces.\n"
							 "For an HMD, use Polynomial Barrel Distortion shader to adjust for IPD.\n"
							 "Do not use this perspective adjustment slider to adjust for IPD.\n"
							 "Default is Zero.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform bool Theater_Mode <
	ui_label = "Theater Mode";
	ui_tooltip = "Sets the 3D Shader in to Theater mode for VR only Usable in Side By Side Half.";
	ui_category = "Stereoscopic Options";
> = false;

uniform bool Eye_Swap <
	ui_label = "Swap Eyes";
	ui_tooltip = "L/R to R/L.";
	ui_category = "Stereoscopic Options";
> = false;
//Cursor Adjustments
uniform int Cursor_Type <
	ui_type = "combo";
	ui_items = "Off\0FPS\0ALL\0RTS\0";
	ui_label = "Cursor Selection";
	ui_tooltip = "Choose the cursor type you like to use.\n"
							 "Default is Zero.";
	ui_category = "Cursor Adjustments";
> = 0;

uniform int2 Cursor_SC <
	ui_type = "drag";
	ui_min = 0; ui_max = 5;
	ui_label = "Cursor Adjustments";
	ui_tooltip = "This controlls the Size & Color.\n"
							 "Defaults are ( X 1, Y 2 ).";
	ui_category = "Cursor Adjustments";
> = int2(1,2);

uniform bool Cursor_Lock <
	ui_label = "Cursor Lock";
	ui_tooltip = "Screen Cursor to Screen Crosshair Lock.";
	ui_category = "Cursor Adjustments";
> = false;

static const float Auto_Balance_Clamp = 0.5; //This Clamps Auto Balance's max Distance
static const float Auto_Depth_Adjust = 0.1; //The Map Automaticly scales to outdoor and indoor areas.
///////////////////////////////////////////////////////////////3D Starts Here/////////////////////////////////////////////////////////////////
uniform bool Mask_Cycle < source = "key"; keycode = Mask_Cycle_Key; toggle = true; >;
uniform bool Trigger_Fade_A < source = "mousebutton"; keycode = Fade_Key; toggle = true; mode = "toggle";>;
uniform bool Trigger_Fade_B < source = "mousebutton"; keycode = Fade_Key;>;
uniform int ran < source = "random"; min = 0; max = 1; >;
uniform float2 Mousecoords < source = "mousepoint"; > ;
//uniform float framecount < source = "framecount"; >;
uniform float frametime < source = "frametime";>;
uniform float timer < source = "timer"; >;

#define WZPD 0.025 //WZPD [Weapon Zero Parallax Distance] controls the focus distance for the screen Pop-out effect also known as Convergence for the weapon hand.
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define Per float2( (Perspective * pix.x) * 0.5, 0) //Per is Perspective

float fmod(float a, float b)
{
	float c = frac(abs(a / b)) * abs(b);
	return a < 0 ? -c : c;
}
//////////////////////////////////////////////////////////////Texture Samplers/////////////////////////////////////////////////////////////////
sampler DepthBuffer
    {
        Texture = ReShade::DepthBufferTex;
        AddressU = BORDER;
        AddressV = BORDER;
        AddressW = BORDER;

    };

sampler BackBufferMIRROR
    {
        Texture = ReShade::BackBufferTex;
        AddressU = MIRROR;
        AddressV = MIRROR;
        AddressW = MIRROR;
    };

sampler BackBufferBORDER
    {
        Texture = ReShade::BackBufferTex;
        AddressU = BORDER;
        AddressV = BORDER;
        AddressW = BORDER;
    };

sampler BackBufferCLAMP
    {
        Texture = ReShade::BackBufferTex;
        AddressU = CLAMP;
        AddressV = CLAMP;
        AddressW = CLAMP;
    };

texture texDM < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };

sampler SamplerDM
	{
		Texture = texDM;
	};

texture texzBuffer < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };

sampler SamplerzBuffer
	{
		Texture = texzBuffer;
	};

#if UI_MASK
texture TexMask < source = "DM_Mask.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerDMMask { Texture = TexMask;};
#endif
////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////
texture texLum {Width = 256*0.5; Height = 256*0.5; Format = RGBA16F; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1

sampler SamplerLum
	{
		Texture = texLum;
	};

float2 Lum(float2 texcoord)
	{   //Luminance
		return saturate(tex2Dlod(SamplerLum,float4(texcoord,0,11)).xy);//Average Luminance Texture Sample
	}
//////////////////////////////////////////////////////////Primary Image Out////////////////////////////////////////////////////////////////////
float4 CSB(float2 texcoords)
{
	if(Custom_Sidebars == 0)
		return tex2Dlod(BackBufferMIRROR,float4(texcoords,0,0));
	else if(Custom_Sidebars == 1)
		return tex2Dlod(BackBufferBORDER,float4(texcoords,0,0));
	else
		return tex2Dlod(BackBufferCLAMP,float4(texcoords,0,0));
}
/////////////////////////////////////////////////////////////Cursor///////////////////////////////////////////////////////////////////////////
float4 MouseCursor(float2 texcoord )
{   float4 Out = CSB(texcoord),Color;
	float Cursor, A = 0.9375, B = 1-A;
	if(Cursor_Type > 0)
	{
		float CCA = 0.005, CCB = 0.00025, CCC = 0.25, CCD = 0.00125, Arrow_Size_A = 0.7, Arrow_Size_B = 1.3, Arrow_Size_C = 4.0;//scaling
		float2 MousecoordsXY = Mousecoords * pix, center = texcoord, Screen_Ratio = float2(1.75,1.0), Size_Color = float2(1+Cursor_SC.x,Cursor_SC.y);
		float THICC = (1.5+Size_Color.x) * CCB, Size = Size_Color.x * CCA, Size_Cubed = (Size_Color.x*Size_Color.x) * CCD;

		if (Cursor_Lock)
		MousecoordsXY = float2(0.5,0.5);
		if (Cursor_Type == 3)
		Screen_Ratio = float2(1.6,1.0);

		float S_dist_fromHorizontal = abs((center.x - (Size* Arrow_Size_B) / Screen_Ratio.x) - MousecoordsXY.x) * Screen_Ratio.x, dist_fromHorizontal = abs(center.x - MousecoordsXY.x) * Screen_Ratio.x ;
		float S_dist_fromVertical = abs((center.y - (Size* Arrow_Size_B)) - MousecoordsXY.y), dist_fromVertical = abs(center.y - MousecoordsXY.y);

		//Cross Cursor
		float B = min(max(THICC - dist_fromHorizontal,0),max(Size-dist_fromVertical,0)), A = min(max(THICC - dist_fromVertical,0),max(Size-dist_fromHorizontal,0));
		float CC = A+B; //Cross Cursor

		//Solid Square Cursor
		float SSC = min(max(Size_Cubed - dist_fromHorizontal,0),max(Size_Cubed-dist_fromVertical,0)); //Solid Square Cursor

		if (Cursor_Type == 3)
		{
			dist_fromHorizontal = abs((center.x - Size / Screen_Ratio.x) - MousecoordsXY.x) * Screen_Ratio.x ;
			dist_fromVertical = abs(center.y - Size - MousecoordsXY.y);
		}
		//Cursor
		float C = all(min(max(Size - dist_fromHorizontal,0),max(Size-dist_fromVertical,0)));//removing the line below removes the square.
			  C -= all(min(max(Size - dist_fromHorizontal * Arrow_Size_C,0),max(Size - dist_fromVertical * Arrow_Size_C,0)));//Need to add this to fix a - bool issue in openGL
			  C -= all(min(max((Size * Arrow_Size_A) - S_dist_fromHorizontal,0),max((Size * Arrow_Size_A)-S_dist_fromVertical,0)));
		// Cursor Array //
		if(Cursor_Type == 1)
			Cursor = CC;
		else if (Cursor_Type == 2)
			Cursor = SSC;
		else if (Cursor_Type == 3)
			Cursor = C;

		// Cursor Color Array //
		float3 CCArray[6] = {
			float3(1,1,1),//White
			float3(0,0,1),//Blue
			float3(0,1,0),//Green
			float3(1,0,0),//Red
			float3(1,0,1),//Magenta
			float3(0,0,0) //Black
		};
		int CSTT = clamp(Cursor_SC.y,0,5);
		Color.rgb = CCArray[CSTT];
	}

	if(Depth_View)
	Out.rgb = tex2Dlod(SamplerzBuffer,float4(texcoord,0,0)).xxx;

	return Cursor ? Color : Out;
}

//////////////////////////////////////////////////////////Depth Map Information/////////////////////////////////////////////////////////////////////
float Depth(float2 texcoord)
{
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
	//Conversions to linear space.....
	float zBuffer = tex2Dlod(DepthBuffer, float4(texcoord,0,0)).x, Far = 1., Near = 0.125/Depth_Map_Adjust; //Near & Far Adjustment

	float2 Offsets = float2(1 + Offset,1 - Offset), Z = float2( zBuffer, 1-zBuffer );

	if (Offset > 0)
	Z = min( 1, float2( Z.x * Offsets.x , Z.y / Offsets.y  ));

	if (Depth_Map == 0) //DM0 Normal
		zBuffer = Far * Near / (Far + Z.x * (Near - Far));
	else if (Depth_Map == 1) //DM1 Reverse
		zBuffer = Far * Near / (Far + Z.y * (Near - Far));
	return saturate(zBuffer);
}
/////////////////////////////////////////////////////////Fade In and Out Toggle/////////////////////////////////////////////////////////////////////
float Fade_in_out(float2 texcoord)
{
	float Trigger_Fade, AA = (1-Fade_Time_Adjust)*1000, PStoredfade = tex2D(SamplerLum,texcoord - 1).z;
	//Fade in toggle.
	if(FPSDFIO == 1)
		Trigger_Fade = Trigger_Fade_A;
	else if(FPSDFIO == 2)
		Trigger_Fade = Trigger_Fade_B;

	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp(-frametime/AA)); ///exp2 would be even slower
}

float Fade(float2 texcoord)
{
	//Check Depth
	float CD, Detect, RArrayA[2] = {0.375,0.625}, RArrayB[2] = {0.25,0.75};
	if(ZPD_Boundary > 0)
	{
		float CDArrayX[4] = {0.25,0.5,0.75,RArrayA[ran]};
		float CDArrayY[4] = {0.125,0.25,0.375,0.5};
		float CDArrayA[4] = {0.25,0.5,0.75,RArrayA[ran]};
		float CDArrayB[4] = {0.05,0.5,0.95,RArrayB[ran]};
		//Screen Space Detector
		[loop]
		for( int i = 0 ; i < 4; i++ )
		{
			for( int j = 0 ; j < 4; j++ )
			{
				if(ZPD_Boundary == 1)
					CD = 1 - ZPD / Depth( float2( CDArrayA[i], CDArrayA[j]) );
				else if(ZPD_Boundary == 2)
					CD = 1 - ZPD / Depth( float2( CDArrayX[i], CDArrayY[j]) );
				else if(ZPD_Boundary == 3)
					CD = 1 - ZPD / Depth( float2( CDArrayB[i], CDArrayB[j]) );

				if( CD < 0)
					Detect = 1;
			}
		}
	}
	float Trigger_Fade = Detect, AA = (1-Fade_Time_Adjust)*1000, PStoredfade = tex2Dlod(SamplerLum,float4(texcoord + 1,0,0)).z;
	//Fade in toggle.
	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp(-frametime/AA)); ///exp2 would be even slower
}

//////////////////////////////////////////////////////////Depth Map Alterations/////////////////////////////////////////////////////////////////////
float2 WeaponDepth(float2 texcoord)
{ //if you see Game it's an Empty Spot for a future profile. Will List the Weapon Profiles on my website. Not Every game will need an update.
	//Weapon Setting// This is here only for user convenience. That is all.
	float3 WA_XYZ = float3(Weapon_Adjust.x,Weapon_Adjust.y,Weapon_Adjust.z);
	//Weapon Profiles Ends Here// - Removed since this not the point of this shader. Also to reduce compile time.

	// Here on out is the Weapon Hand Adjustment code.
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
	//Conversions to linear space.....
	float zBufferWH = tex2Dlod(DepthBuffer, float4(texcoord,0,0)).x, Far = 1.0, Near = 0.125/WA_XYZ.y;  //Near & Far Adjustment

	float2 Offsets = float2(1 + WA_XYZ.z,1 - WA_XYZ.z), Z = float2( zBufferWH, 1-zBufferWH );

	if (WA_XYZ.z > 0)
	Z = min( 1, float2( Z.x * Offsets.x , Z.y / Offsets.y  ));

	[branch] if (Depth_Map == 0)//DM0. Normal
		zBufferWH = Far * Near / (Far + Z.x * (Near - Far));
	else if (Depth_Map == 1)//DM1. Reverse
		zBufferWH = Far * Near / (Far + Z.y * (Near - Far));

	return float2(saturate(zBufferWH), WA_XYZ.x);
}

float3 DepthMap(in float4 position : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
		float4 DM = Depth(texcoord).xxxx;
		float R, G, B, WD = WeaponDepth(texcoord).x, CoP = WeaponDepth(texcoord).y, CutOFFCal = (CoP/Depth_Map_Adjust) * 0.5; //Weapon Cutoff Calculation
		CutOFFCal = step(DM.x,CutOFFCal);

		if (!WP)
		{
			DM.x = DM.x;
		}
		else
		{
			DM.x = lerp(DM.x,WD,CutOFFCal);
			DM.y = lerp(0.0,WD,CutOFFCal);
			DM.z = lerp(0.5,WD,CutOFFCal);
		}

		R = DM.x; //Mix Depth
		G = DM.y > smoothstep(0,2.5,DM.w); //Weapon Mask
		B = DM.z; //Weapon Hand
		//A = DM.w; //Normal Depth
		//Fade Storage
		if(texcoord.x < pix.x * 2 && texcoord.y < pix.y * 2)
			R = Fade_in_out(texcoord);
		if(1-texcoord.x < pix.x * 2 && 1-texcoord.y < pix.y * 2)
			R = Fade(texcoord);
	//Alpha Don't work in DX9 under ReShade
	return saturate(float3(R,G,B));
}

float AutoDepthRange(float d, float2 texcoord )
{
	float LumAdjust_ADR = smoothstep(-0.0175,Auto_Depth_Adjust,Lum(texcoord).x);
    return min(1,( d - 0 ) / ( LumAdjust_ADR - 0));
}

float2 Conv(float D,float2 texcoord)
{
	float Z = ZPD, WZP = 0.5, ZP = 0.5, ALC = abs(Lum(texcoord).x), W_Convergence = WZPD;

	if (Weapon_ZPD_Boundary > 0)
	{   //only really only need to check one point just above the center bottom.
		float WZPDB = 1 - WZPD / tex2Dlod(SamplerDM,float4(float2(0.5,0.9375),0,0)).x;
		if (WZPDB < -0.1)
			W_Convergence *= 0.5-Weapon_ZPD_Boundary;
	}

	W_Convergence = 1 - W_Convergence / D;

	if (Auto_Depth_Adjust > 0)
		D = AutoDepthRange(D,texcoord);

	if(Auto_Balance_Ex > 0 )
		ZP = saturate(ALC);
	//Screen ZPD Violation Detection.
	Z *= lerp( 1, 0.5, smoothstep(0,1,tex2Dlod(SamplerLum,float4(texcoord + 1,0,0)).z));

	float Convergence = 1 - Z / D;
	if (ZPD == 0)
		ZP = 1;

	if (WZPD <= 0)
		WZP = 1;

	if (ALC <= 0.025)
		WZP = 1;

	ZP = min(ZP,Auto_Balance_Clamp);

  return float2(lerp(Convergence,D, ZP),lerp(W_Convergence,D,WZP));
}

float zBuffer(in float4 position : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
	float3 DM = tex2Dlod(SamplerDM,float4(texcoord,0,0)).xyz;

	if (WP == 0 || WZPD == 0)
		DM.y = 0;

	DM.y = lerp(Conv(DM.x,texcoord).x, Conv(DM.z,texcoord).y, DM.y);

	if ( Depth_Detection )
	{   //Check Depth at 3 Point D_A Top_Center / Bottom_Center / ??Check evey 1 in 100 frames C100 = (framecount % 100) < 0.01??
		float D_A = tex2Dlod(SamplerDM,float4(float2(0.5,0.0),0,0)).x, D_B = tex2Dlod(SamplerDM,float4(float2(0.0,1.0),0,0)).x;

		if (D_A != 1 && D_B != 1)//Has to be Sky
		{
			if (D_A == D_B)//No depth
				DM = 0.0625;
		}
	}

	return DM.y;
}
//////////////////////////////////////////////////////////Parallax Generation///////////////////////////////////////////////////////////////////////
float2 Parallax(float Diverge, float2 Coordinates) // Horizontal parallax offset & Hole filling effect
{   float2 ParallaxCoord = Coordinates;
	float Perf = 1, MS = Diverge * pix.x;

	if(Performance_Mode)
	Perf = .5;
	//ParallaxSteps Calculations
	float D = abs(Diverge), Cal_Steps = (D * Perf) + (D * 0.04), Steps = clamp(Cal_Steps,0,255);
	// Offset per step progress & Limit
	float LayerDepth = rcp(Steps);
	//Offsets listed here Max Seperation is 3% - 8% of screen space with Depth Offsets & Netto layer offset change based on MS.
	float deltaCoordinates = MS * LayerDepth, CurrentDepthMapValue = tex2Dlod(SamplerzBuffer,float4(ParallaxCoord,0,0)).x, CurrentLayerDepth = 0, DepthDifference;
	float2 DB_Offset = float2(Diverge * 0.03, 0) * pix;

  if(View_Mode == 1)
  	DB_Offset = 0;
	//DX12 nor Vulkan was tested.
	//Do-While Loop Seems to be faster then for or while loop in DX 9, 10, and 11. But, not in openGL. In some rare openGL games it causes CTD
	//For loop is broken in this shader for some reason in DX9. I don't know why. This is the reason for the change. I blame Voodoo Magic
	//While Loop is the most compatible of the bunch. So I am forced to use this loop.
	[loop]
	while ( CurrentDepthMapValue > CurrentLayerDepth) // Steep parallax mapping
	{   // Shift coordinates horizontally in linear fasion
	    ParallaxCoord.x -= deltaCoordinates;
	    // Get depth value at current coordinates
	    CurrentDepthMapValue = tex2Dlod(SamplerzBuffer,float4(ParallaxCoord - DB_Offset,0,0)).x;
	    // Get depth of next layer
	    CurrentLayerDepth += LayerDepth;
		continue;
	}
	// Parallax Occlusion Mapping
	float2 PrevParallaxCoord = float2(ParallaxCoord.x + deltaCoordinates, ParallaxCoord.y);
	float beforeDepthValue = tex2Dlod(SamplerzBuffer,float4( ParallaxCoord ,0,0)).x + LayerDepth - CurrentLayerDepth, afterDepthValue = CurrentDepthMapValue - CurrentLayerDepth;
	// Interpolate coordinates
	float weight = afterDepthValue / (afterDepthValue - beforeDepthValue);
	ParallaxCoord = PrevParallaxCoord * weight + ParallaxCoord * (1. - weight);

	if(View_Mode == 0)//This is to limit artifacts.
	ParallaxCoord += DB_Offset * 0.625;
	// Apply gap masking
	DepthDifference = (afterDepthValue-beforeDepthValue) * MS;
	if(View_Mode == 1)
		ParallaxCoord.x -= DepthDifference;

	return ParallaxCoord;
}
//////////////////////////////////////////////////////////////HUD Alterations///////////////////////////////////////////////////////////////////////
float3 HUD(float3 HUD, float2 texcoord )
{
	float Mask_Tex, CutOFFCal = ((HUD_Adjust.x * 0.5)/Depth_Map_Adjust) * 0.5, COC = step(Depth(texcoord).x,CutOFFCal); //HUD Cutoff Calculation

	//This code is for hud segregation.
	if (HUD_Adjust.x > 0)
		HUD = COC > 0 ? tex2D(BackBufferCLAMP,texcoord).rgb : HUD;

	#if UI_MASK
	    if (Mask_Cycle == true)
	        Mask_Tex = tex2D(SamplerDMMask,texcoord.xy).a;

		float MAC = step(1.0-Mask_Tex,0.5); //Mask Adjustment Calculation
		//This code is for hud segregation.
		HUD = MAC > 0 ? tex2D(BackBufferCLAMP,texcoord).rgb : HUD;
	#endif
	return saturate(HUD);
}
///////////////////////////////////////////////////////////Stereo Calculation///////////////////////////////////////////////////////////////////////
float3 PS_calcLR(float2 texcoord)
{
	float2 TCL, TCR, TexCoords = texcoord;

	[branch] if (Stereoscopic_Mode == 0)
	{
		TCL = float2(texcoord.x*2,texcoord.y);
		TCR = float2(texcoord.x*2-1,texcoord.y);
	}
	else if(Stereoscopic_Mode == 1)
	{
		TCL = float2(texcoord.x,texcoord.y*2);
		TCR = float2(texcoord.x,texcoord.y*2-1);
	}
	else
	{
		TCL = float2(texcoord.x,texcoord.y);
		TCR = float2(texcoord.x,texcoord.y);
	}

	TCL += Per;
	TCR -= Per;

	float D = Divergence;
	if (Eye_Swap)
		D = -Divergence;

	float FadeIO = smoothstep(0,1,1-Fade_in_out(texcoord).x), FD = D, FD_Adjust = 0.1;

	if( Eye_Fade_Reduction_n_Power.y == 1)
		FD_Adjust = 0.2;
	else if( Eye_Fade_Reduction_n_Power.y == 2)
		FD_Adjust = 0.3;

	if (FPSDFIO == 1 || FPSDFIO == 2)
		FD = lerp(FD * FD_Adjust,FD,FadeIO);

	float2 DLR = float2(FD,FD);

	if( Eye_Fade_Reduction_n_Power.x == 1)
			DLR = float2(D,FD);
	else if( Eye_Fade_Reduction_n_Power.x == 2)
			DLR = float2(FD,D);

	float4 image = 1, accum, color, Left = MouseCursor(Parallax(-DLR.x, TCL)), Right = MouseCursor(Parallax(DLR.y, TCR));
	//HUD Mode
	float HUD_Adjustment = ((0.5 - HUD_Adjust.y)*25.) * pix.x;
	Left.rgb = HUD(Left.rgb,float2(TCL.x - HUD_Adjustment,TCL.y));
	Right.rgb = HUD(Right.rgb,float2(TCR.x + HUD_Adjustment,TCR.y));

	float2 gridxy = floor(float2(TexCoords.x * BUFFER_WIDTH, TexCoords.y * BUFFER_HEIGHT)); //Native

	if(Stereoscopic_Mode == 0)
		color = TexCoords.x < 0.5 ? Left : Right;
	else if(Stereoscopic_Mode == 1)
		color = TexCoords.y < 0.5 ? Left : Right;
	else if(Stereoscopic_Mode == 2)
		color = fmod(gridxy.y,2.0) ? Right : Left;
	else if(Stereoscopic_Mode >= 3)
	{
		float3 HalfLA = dot(Left.rgb,float3(0.299, 0.587, 0.114)), HalfRA = dot(Right.rgb,float3(0.299, 0.587, 0.114));
		float3 LMA = lerp(HalfLA,Left.rgb,0.75), RMA = lerp(HalfRA,Right.rgb,0.75);//Hard Locked 0.75% color for lower ghosting.
		// Left/Right Image
		float4 cA = float4(LMA,1);
		float4 cB = float4(RMA,1);

		if (Stereoscopic_Mode == 3) // Anaglyph 3D Colors Red/Cyan
		{
			float4 LeftEyecolor = float4(1.0,0.0,0.0,1.0);
			float4 RightEyecolor = float4(0.0,1.0,1.0,1.0);

			color =  (cA*LeftEyecolor) + (cB*RightEyecolor);
		}
		else if (Stereoscopic_Mode == 4) // Anaglyph 3D Green/Magenta
		{
			float4 LeftEyecolor = float4(0.0,1.0,0.0,1.0);
			float4 RightEyecolor = float4(1.0,0.0,1.0,1.0);

			color =  (cA*LeftEyecolor) + (cB*RightEyecolor);
		}
	}

	return color.rgb;
}
/////////////////////////////////////////////////////////Average Luminance Textures/////////////////////////////////////////////////////////////////
float3 Average_Luminance(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 ABEA, ABEArray[3] = {
		float4(0.0,1.0,0.0, 1.0),           //No Edit
		float4(0.375, 0.250, 0.4375, 0.125),//Center Small
		float4(0.375, 0.250, 0.0, 1.0)      //Center Long
	};
	ABEA = ABEArray[clamp(Auto_Balance_Ex,0,2)];

	float Average_Lum_ZPD = Depth(float2(ABEA.x + texcoord.x * ABEA.y, ABEA.z + texcoord.y * ABEA.w)), Average_Lum_Bottom = Depth( texcoord );

	float Storage = texcoord < 0.5 ? tex2D(SamplerDM,0).x : tex2D(SamplerDM,1).x;

	return float3(Average_Lum_ZPD,Average_Lum_Bottom,Storage);
}
/////////////////////////////////////////////////////////////////////////Logo///////////////////////////////////////////////////////////////////////
float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 Z_A = float2(1.0,0.5); //Theater Mode
	if(Theater_Mode && Stereoscopic_Mode == 0)
	{
		Z_A = float2(1.0,1.0); //Full Screen Mode
	}
	//Texture Zoom & Aspect Ratio//
	float X = Z_A.x;
	float Y = Z_A.y * Z_A.x * 2;
	float midW = (X - 1)*(BUFFER_WIDTH*0.5)*pix.x;
	float midH = (Y - 1)*(BUFFER_HEIGHT*0.5)*pix.y;

	float2 TM = float2((texcoord.x*X)-midW,(texcoord.y*Y)-midH);

	float PosX = 0.9525f*BUFFER_WIDTH*pix.x,PosY = 0.975f*BUFFER_HEIGHT*pix.y;
	float4 Color = float4(PS_calcLR(TM).rgb,1.0),D,E,P,T,H,Three,DD,Dot,I,N,F,O;

	if(timer <= 12500)
	{
		//DEPTH
		//D
		float PosXD = -0.035+PosX, offsetD = 0.001;
		float OneD = all( abs(float2( texcoord.x -PosXD, texcoord.y-PosY)) < float2(0.0025,0.009));
		float TwoD = all( abs(float2( texcoord.x -PosXD-offsetD, texcoord.y-PosY)) < float2(0.0025,0.007));
		D = OneD-TwoD;

		//E
		float PosXE = -0.028+PosX, offsetE = 0.0005;
		float OneE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.009));
		float TwoE = all( abs(float2( texcoord.x -PosXE-offsetE, texcoord.y-PosY)) < float2(0.0025,0.007));
		float ThreeE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.001));
		E = (OneE-TwoE)+ThreeE;

		//P
		float PosXP = -0.0215+PosX, PosYP = -0.0025+PosY, offsetP = 0.001, offsetP1 = 0.002;
		float OneP = all( abs(float2( texcoord.x -PosXP, texcoord.y-PosYP)) < float2(0.0025,0.009*0.775));
		float TwoP = all( abs(float2( texcoord.x -PosXP-offsetP, texcoord.y-PosYP)) < float2(0.0025,0.007*0.680));
		float ThreeP = all( abs(float2( texcoord.x -PosXP+offsetP1, texcoord.y-PosY)) < float2(0.0005,0.009));
		P = (OneP-TwoP) + ThreeP;

		//T
		float PosXT = -0.014+PosX, PosYT = -0.008+PosY;
		float OneT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosYT)) < float2(0.003,0.001));
		float TwoT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosY)) < float2(0.000625,0.009));
		T = OneT+TwoT;

		//H
		float PosXH = -0.0072+PosX;
		float OneH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.001));
		float TwoH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.009));
		float ThreeH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.00325,0.009));
		H = (OneH-TwoH)+ThreeH;

		//Three
		float offsetFive = 0.001, PosX3 = -0.001+PosX;
		float OneThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.009));
		float TwoThree = all( abs(float2( texcoord.x -PosX3 - offsetFive, texcoord.y-PosY)) < float2(0.003,0.007));
		float ThreeThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.001));
		Three = (OneThree-TwoThree)+ThreeThree;

		//DD
		float PosXDD = 0.006+PosX, offsetDD = 0.001;
		float OneDD = all( abs(float2( texcoord.x -PosXDD, texcoord.y-PosY)) < float2(0.0025,0.009));
		float TwoDD = all( abs(float2( texcoord.x -PosXDD-offsetDD, texcoord.y-PosY)) < float2(0.0025,0.007));
		DD = OneDD-TwoDD;

		//Dot
		float PosXDot = 0.011+PosX, PosYDot = 0.008+PosY;
		float OneDot = all( abs(float2( texcoord.x -PosXDot, texcoord.y-PosYDot)) < float2(0.00075,0.0015));
		Dot = OneDot;

		//INFO
		//I
		float PosXI = 0.0155+PosX, PosYI = 0.004+PosY, PosYII = 0.008+PosY;
		float OneI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosY)) < float2(0.003,0.001));
		float TwoI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYI)) < float2(0.000625,0.005));
		float ThreeI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYII)) < float2(0.003,0.001));
		I = OneI+TwoI+ThreeI;

		//N
		float PosXN = 0.0225+PosX, PosYN = 0.005+PosY,offsetN = -0.001;
		float OneN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN)) < float2(0.002,0.004));
		float TwoN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN - offsetN)) < float2(0.003,0.005));
		N = OneN-TwoN;

		//F
		float PosXF = 0.029+PosX, PosYF = 0.004+PosY, offsetF = 0.0005, offsetF1 = 0.001;
		float OneF = all( abs(float2( texcoord.x -PosXF-offsetF, texcoord.y-PosYF-offsetF1)) < float2(0.002,0.004));
		float TwoF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0025,0.005));
		float ThreeF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0015,0.00075));
		F = (OneF-TwoF)+ThreeF;

		//O
		float PosXO = 0.035+PosX, PosYO = 0.004+PosY;
		float OneO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.003,0.005));
		float TwoO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.002,0.003));
		O = OneO-TwoO;
		//Website
		return D+E+P+T+H+Three+DD+Dot+I+N+F+O ? 1-texcoord.y*50.0+48.35f : Color;
	}
	else
		return Color;
}

//*Rendering passes*//
technique Depth3D //Note to self: this should start the same as to not break profiles.
< ui_tooltip = "This Shader should be the VERY LAST Shader in your master shader list.\n"
	           "You can always Drag shaders around by clicking them and moving them.\n"
	           "For more help you can always contact me at DEPTH3D.info or my Github."; >
{
		pass DepthBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = DepthMap;
		RenderTarget = texDM;
	}
		pass zbufferLM
	{
		VertexShader = PostProcessVS;
		PixelShader = zBuffer;
		RenderTarget = texzBuffer;
	}
		pass AverageLuminance
	{
		VertexShader = PostProcessVS;
		PixelShader = Average_Luminance;
		RenderTarget = texLum;
	}
		pass StereoOut
	{
		VertexShader = PostProcessVS;
		PixelShader = Out;
	}
}
