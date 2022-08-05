////------------//
///**3DViewer**///
//------------////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//* Depth Map Displacement 3D post-process shader Based on SuperDepth3D v2.1.0
//* For Reshade 3.0+
//* ---------------------------------
//*	                                                                     3DViewer
//* Due Diligence & References:
//* Fubaxiusz a shader dev at the reshade forums https://reshade.me/forum/shader-presentation/5104-vr-universal-shader for poitning me at POM idea.
//* Had to rework Philippe David code from a reworked Morgan McGuire Shader http://graphics.cs.brown.edu/games/SteepParallax/index.html so that it works reshade.
//* In my case the POM is adjusted againts the Depth Buffer gradient and not a custom Hight Map.
//* If I missed any information please contact me so I can make corrections.
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
//* Special Thank You Hankpunk @ Nvidia for helping me getting this working with NV systems.
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
#define Cursor_Lock_Key 4 // Set default on mouse 4
#define Fade_Key 1 // Set default on mouse 1
#define Fade_Time_Adjust 0.5625 // From 0 to 1 is the Fade Time adjust for this mode. Default is 0.5625;
//USER EDITABLE PREPROCESSOR FUNCTIONS END//

//Divergence & Convergence//
uniform int Divergence <
	ui_type = "drag";
	ui_min = 10; ui_max = 100;
	ui_label = "Divergence Slider";
	ui_tooltip = "Divergence increases differences between the left and right retinal images and allows you to experience depth.\n"
							 "The process of deriving binocular depth information is called stereopsis.";
	ui_category = "Divergence & Convergence";
> = 25;

uniform float2 ZPD_Separation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.250;
	ui_label = "ZPD & Sepration";
	ui_tooltip = "Zero Parallax Distance controls the focus distance for the screen Pop-out effect also known as Convergence.\n"
				"Separation is a way to increase the intensity of Divergence without a performance cost.\n"
				"For FPS Games keeps this low Since you don't want your gun to pop out of screen.\n"
				"Default is 0.025, Zero is off.";
	ui_category = "Divergence & Convergence";
> = float2(0.025,0.0);

uniform int Auto_Balance_Ex <
	ui_type = "slider";
	ui_min = 0; ui_max = 2;
	ui_label = "Auto Balance";
	ui_tooltip = "Automatically Balance between ZPD Depth and Scene Depth.\n"
				 			 "Default Zero, is Off.";
	ui_category = "Divergence & Convergence";
> = 0;

uniform int ZPD_Boundary <
	ui_type = "combo";
	ui_items = "Off\0Normal\0Third Person\0FPS Weapon Center\0FPS Weapon Right\0";
	ui_label = "ZPD Boundary Detection";
	ui_tooltip = "This selection menu gives extra boundary conditions to ZPD.\n"
				 			 "This treats your screen as a virtual wall.";
	ui_category = "Divergence & Convergence";
> = 1;

uniform float ZPD_Boundary_Adjust <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "ZPD Boundary Adjust";
	ui_tooltip = "This selection menu gives extra boundary conditions to scale ZPD & lets you adjust Fade time.";
	ui_category = "Divergence & Convergence";
> = 0.5;

uniform int View_Mode <
	ui_type = "combo";
	ui_items = "View Mode Normal\0View Mode Alpha\0";
	ui_label = "View Mode";
	ui_tooltip = "Changes the way the shader fills in the occlude section in the image.\n"
	             "Normal is default output and Alpha is used for higher ammounts of Semi-Transparent objects.\n"
				 "Default is Normal";
	ui_category = "Occlusion Masking";
> = 0;

uniform bool Performance_Mode <
	ui_label = " Performance Mode";
	ui_tooltip = "Performance Mode Lowers Occlusion Quality Processing so that there is a small boost to FPS.\n"
				 "Please enable the 'Performance Mode Checkbox,' in ReShade's GUI.\n"
				 "It's located in the lower bottom right of the ReShade's Main UI.\n"
				 "Default is False.";
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
	ui_min = 0; ui_max = 1; ui_step = 0.01;
	ui_label = "Depth Map Adjustment";
	ui_tooltip = "This allows for you to adjust the DM precision.\n"
							 "Adjust this to keep it as low as possible.\n"
							 "Default is 7.5";
	ui_category = "Depth Map";
> = 0.07;

uniform float Offset <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_label = "Depth Map Offset";
	ui_tooltip = "Depth Map Offset is for non conforming ZBuffer.\n"
							 "It's rare if you need to use this in any game.\n"
							 "Use this to make adjustments to DM 0 or DM 1.\n"
							 "Default and starts at Zero and it's Off.";
	ui_category = "Depth Map";
> = 0.0;

uniform bool Depth_Map_Flip <
	ui_label = "Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
	ui_category = "Depth Map";
> = false;

//uniform bool DeBug <
//	ui_label = "Debug Depth";
//	ui_tooltip = "Use this too figure out if depth is working in your game.";
//	ui_category = "Depth Map";
//> = false;

uniform int WP <
	ui_type = "combo";
	ui_items = "Off\0Make Your Own\0ES: Oblivion\0Borderlands 2\0Fallout 4\0Skyrim: SE\0DOOM 2016\0CoD:BO | CoD:MW2 | CoD:MW3\0CoD:BO II\0CoD:Ghost\0CoD:AW | CoD:MW R | CoD:MW 2019\0CoD:IW\0CoD:WaW\0CoD | CoD:UO | CoD:2\0CoD:BO IIII\0Quake DarkPlaces\0Quake 2 XP\0Quake 4\0Metro Redux Games\0Minecraft\0S.T.A.L.K.E.R: Games\0Prey 2006\0Prey 2017 High Settings and <\0Prey 2017 Very High\0RtC Wolfenstine\0Wolfenstein\0Wolfenstein: TNO & TOB\0BorderLands 3\0Black Mesa\0SOMA\0Cryostasis\0Unreal Gold with v227\0Serious Sam Games\0Serious Sam Fusion\0Wrath\0TitanFall 2\0Project Warlock\0Euro Truck Sim II\0F.E.A.R & F.E.A.R 2\0Condemned Criminal Origins\0Immortal Redneck\0NecroVisioN & NecroVisioN: Lost Company\0Rage 2011\0BorderLands\0Bioshock Remastred\0Bioshock 2 Remastred\0Talos Principle\0";
	ui_label = "Weapon Profiles";
	ui_tooltip = "Pick Weapon Profile for your game or make your own.";
	ui_category = "Weapon Hand Adjust";
> = 0;

uniform float3 Weapon_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 250.0; ui_step = 0.001;
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
	ui_min = 0; ui_max = 0.5; ui_step = 0.001;
	ui_label = "Weapon Screen Boundary Detection";
	ui_tooltip = "This selection menu gives extra boundary conditions to WZPD.";
	ui_category = "Weapon Hand Adjust";
> = 0;
//Heads-Up Display
uniform float2 HUD_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
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
	ui_items = "Side by Side Half & VR Theater\0Top and Bottom & VR Theater\0Line Interlaced\0Anaglyph 3D Red/Cyan\0Anaglyph 3D Green/Magenta\0";
	ui_label = "3D Display Modes";
	ui_tooltip = "Stereoscopic 3D display output selection.";
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
static const float ZPD_Boundary_Fade = 0.4; //This adjust the Fade Time for ZPD Boundry Focusing.
///////////////////////////////////////////////////////////////3D Starts Here/////////////////////////////////////////////////////////////////
uniform bool Mask_Cycle < source = "key"; keycode = Mask_Cycle_Key; toggle = true; >;
uniform bool CLK < source = "mousebutton"; keycode = Cursor_Lock_Key; toggle = true; mode = "toggle";>;
uniform bool Trigger_Fade_A < source = "mousebutton"; keycode = Fade_Key; toggle = true; mode = "toggle";>;
uniform bool Trigger_Fade_B < source = "mousebutton"; keycode = Fade_Key;>;
uniform float2 Mousecoords < source = "mousepoint"; >;
uniform bool hasdepth < source = "bufready_depth"; >;
uniform float frametime < source = "frametime";>;
uniform float timer < source = "timer"; >;
//WZPD [Weapon Zero Parallax Distance] controls the focus distance for the screen Pop-out effect also known as Convergence for the weapon hand.
#define WZPD 0.025
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define Per float2( (Perspective * pix.x) * 0.5, 0) //Per is Perspective
float DMA(){ return lerp(1,250,Depth_Map_Adjust); }
float fmod(float a, float b)
{
	float c = frac(abs(a / b)) * abs(b);
	return a < 0 ? -c : c;
}
//////////////////////////////////////////////////////////////Texture Samplers/////////////////////////////////////////////////////////////////
texture TexDepthBufferV : DEPTH;

texture TexBackBufferV : COLOR;

sampler DepthBufferV
    {
        Texture = TexDepthBufferV;
        AddressU = BORDER;
        AddressV = BORDER;
        AddressW = BORDER;
    };

sampler BackBufferBORDERV
    {
        Texture = TexBackBufferV;
        AddressU = BORDER;
        AddressV = BORDER;
        AddressW = BORDER;
    };

sampler BackBufferCLAMPV
    {
        Texture = TexBackBufferV;
        AddressU = CLAMP;
        AddressV = CLAMP;
        AddressW = CLAMP;
    };

texture texDM_NV  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };

sampler SamplerDM_NV
	{
		Texture = texDM_NV;
	};

texture texZBuffer_NV  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };

sampler SamplerZBuffer_NV
	{
		Texture = texZBuffer_NV;
	};

#if UI_MASK
texture TexMask < source = "DM_Mask.png"; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler SamplerDMMask { Texture = TexMask;};
#endif
////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////
texture texLum_NV {Width = 256*0.5; Height = 256*0.5; Format = RGBA16F; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1

sampler SamplerLum_NV
	{
		Texture = texLum_NV;
	};

float2 Lum(float2 texcoord)
	{   //Luminance
		return saturate(tex2Dlod(SamplerLum_NV,float4(texcoord,0,11)).xy);//Average Luminance Texture Sample
	}
//////////////////////////////////////////////////////////Primary Image Out////////////////////////////////////////////////////////////////////
float4 CSB(float2 texcoords)
{
	return tex2Dlod(BackBufferBORDERV,float4(texcoords,0,0));
}
/////////////////////////////////////////////////////////////Cursor///////////////////////////////////////////////////////////////////////////
float4 MouseCursor(float2 texcoord )
{   float4 Out = CSB(texcoord),Color;
		float A = 0.959375, B = 1-A;
		float Cursor;
		if(Cursor_Type > 0)
		{
			float CCA = 0.005, CCB = 0.00025, CCC = 0.25, CCD = 0.00125, Arrow_Size_A = 0.7, Arrow_Size_B = 1.3, Arrow_Size_C = 4.0;//scaling
			float2 MousecoordsXY = Mousecoords * pix, center = texcoord, Screen_Ratio = float2(1.75,1.0), Size_Color = float2(1+Cursor_SC.x,Cursor_SC.y);
			float THICC = (1.5+Size_Color.x) * CCB, Size = Size_Color.x * CCA, Size_Cubed = (Size_Color.x*Size_Color.x) * CCD;

			if (Cursor_Lock && !CLK)
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

	//if(DeBug)
	//{
	//	if(texcoord.y > A || texcoord.y < B) //Doing this to keep the Depth Map from getting used as an cheating device.
	//		Out.rgb = tex2Dlod(SamplerZBuffer_NV,float4(texcoord,0,0)).xxx;
	//}
return Cursor ? Color : Out;
}

//////////////////////////////////////////////////////////Depth Map Information/////////////////////////////////////////////////////////////////////
float Depth(float2 texcoord)
{
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
	//Conversions to linear space.....
	float zBuffer = tex2Dlod(DepthBufferV, float4(texcoord,0,0)).x, Far = 1., Near = 0.125/DMA(); //Near & Far Adjustment

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
	float Trigger_Fade, AA = (1-Fade_Time_Adjust)*1000, PStoredfade = tex2D(SamplerLum_NV,texcoord - 1).z;
	//Fade in toggle.
	if(FPSDFIO == 1)
		Trigger_Fade = Trigger_Fade_A;
	else if(FPSDFIO == 2)
		Trigger_Fade = Trigger_Fade_B;

	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp(-frametime/AA)); ///exp2 would be even slower
}

float Fade(float2 texcoord)
{   //Check Depth
	float CD, Detect;
	if(ZPD_Boundary > 0)
	{   //Normal A & B for both
		float CDArray_A[7] = { 0.125 ,0.25, 0.375,0.5, 0.625, 0.75, 0.875}, CDArray_B[7] = { 0.25 ,0.375, 0.4375, 0.5, 0.5625, 0.625, 0.75};
		float CDArrayZPD_A[7] = { ZPD_Separation.x * 0.625, ZPD_Separation.x * 0.75, ZPD_Separation.x * 0.875, ZPD_Separation.x, ZPD_Separation.x * 0.875, ZPD_Separation.x * 0.75, ZPD_Separation.x * 0.625 },
			  CDArrayZPD_B[7] = { ZPD_Separation.x * 0.3, ZPD_Separation.x * 0.5, ZPD_Separation.x * 0.75, ZPD_Separation.x, ZPD_Separation.x * 0.75, ZPD_Separation.x * 0.5, ZPD_Separation.x * 0.3};
		float2 GridXY;
		//Screen Space Detector 7x7 Grid from between 0 to 1 and ZPD Detection becomes stronger as it gets closer to the Center.
		[loop]
		for( int i = 0 ; i < 7; i++ )
		{
			for( int j = 0 ; j < 7; j++ )
			{
				if(ZPD_Boundary == 1)
					GridXY = float2( CDArray_A[i], CDArray_A[j]);
				else if(ZPD_Boundary == 2 || ZPD_Boundary == 4)
					GridXY = float2( CDArray_B[i], CDArray_B[j]);
				else if(ZPD_Boundary == 3)
					GridXY = float2( CDArray_A[i], CDArray_B[j]);

				float ZPD_I = ZPD_Boundary == 2 || ZPD_Boundary == 4  ? CDArrayZPD_B[i] : CDArrayZPD_A[i] ;

				if(ZPD_Boundary == 3 || ZPD_Boundary == 4)
				{
					if ( Depth(GridXY) == 1 )
						ZPD_I = 0;
				}
				// CDArrayZPD[i] reads across prepDepth.......
				CD = 1 - ZPD_I / Depth(GridXY);

				if ( CD < 0 )//may lower this to like -0.1
					Detect = 1;
			}
		}
	}
	float Trigger_Fade = Detect, AA = (1-(ZPD_Boundary_Fade*2.))*1000, PStoredfade = tex2Dlod(SamplerLum_NV,float4(texcoord + 1,0,0)).z;
	//Fade in toggle.
	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp(-frametime/AA)); ///exp2 would be even slower
}
float3 WHS()  //if you see Game it's an Empty Spot for a future profile. Will List the Weapon Profiles on my website. Not Every game will need an update.
{switch(WP)
	{ case  2:
			return float3(0.425,5.0,1.125);      //ES: Oblivion
		case  3:
			return float3(0.625,37.5,7.25);      //BorderLands 2
		case  4:
			return float3(0.253,28.75,98.5);     //Fallout 4
		case  5:
			return float3(0.276,20.0,9.5625);    //Skyrim: SE
		case  6:
			return float3(0.338,20.0,9.25);      //DOOM 2016
		case  7:
			return float3(0.255,177.5,63.025);   //CoD:Black Ops  CoD:MW2  CoD:MW3
		case  8:
			return float3(0.254,100.0,0.9843);   //CoD:Black Ops II
		case  9:
			return float3(0.254,203.125,0.98435);//CoD:Ghost
		case  10:
			return float3(0.254,203.125,0.98433);//CoD:AW CoD:MW R CoD:MW 2019
		case  11:
			return float3(0.254,125.0,0.9843);   //CoD:IW
		case  12:
			return float3(0.255,200.0,63.0);     //CoD:WaW
		case  13:
			return float3(0.510,162.5,3.975);    //CoD CoD:UO CoD:2
		case  14:
			return float3(0.254,23.75,0.98425);  //CoD: Black Ops IIII
		case  15:
			return float3(0.375,60.0,15.15625);  //Quake DarkPlaces
		case  16:
			return float3(0.7,14.375,2.5);       //Quake 2 XP
		case  17:
			return float3(0.750,30.0,1.050);     //Quake 4
		case  18:
			return float3(0.450,12.0,23.75);     //Metro Redux Games
		case  19:
			return float3(0.625,350.0,0.785);    //Minecraft
		case  20:
			return float3(0.255,6.375,53.75);    //S.T.A.L.K.E.R: Games
		case  21:
			return float3(0.750,30.0,1.025);     //Prey 2006
		case  22:
			return float3(0.2832,13.125,0.8725); //Prey 2017 High Settings and <
		case  23:
			return float3(0.2832,13.75,0.915625);//Prey 2017 Very High
		case  24:
			return float3(0.7,9.0,2.3625);       //Return to Castle Wolfenstine
		case  25:
			return float3(0.4894,62.50,0.98875); //Wolfenstein
		case  26:
			return float3(1.0,93.75,0.81875);    //Wolfenstein: The New Order / The Old Blood
		case  27:
			return float3(0.284,10.5,0.8725);    //BorderLands 3
		case  28:
			return float3(0.278,37.50,9.1);      //Black Mesa
		case  29:
			return float3(0.785,21.25,0.3875);   //SOMA
		case  30:
			return float3(0.444,20.0,1.1875);    //Cryostasis
		case  31:
			return float3(0.286,80.0,7.0);       //Unreal Gold with v227
		case  32:
			return float3(0.280,18.75,9.03);     //Serious Sam Games
		case  33:
			return float3(0.3,17.5,0.9015);      //Serious Sam Fusion
		case  34:
			return float3(0.266,30.0,14.0);      //Wrath
		case  35:
			return float3(0.277,20.0,8.8);       //TitanFall 2
		case  36:
			return float3(0.7,16.250,0.300);     //Project Warlock
		case  38:
			return float3(0.28,20.0,9.0);        //EuroTruckSim2
		case  39:
			return float3(0.458,10.5,1.105);     //F.E.A.R & F.E.A.R 2: Project Origin
		case  40:
			return float3(1.5,37.5,0.99875);     //Condemned Criminal Origins
		case  41:
			return float3(2.0,16.25,0.09);       //Immortal Redneck
		case  42:
			return float3(0.489,68.75,1.02);     //NecroVisioN & NecroVisioN: Lost Company
		case  43:
			return float3(1.0,237.5,0.83625);    //Rage64
		case  44:
			return float3(0.276,16.25,9.2);      //BorderLands
		case  45:
			return float3(0.425,15.0,99.0);      //Bioshock Remastred
		case  46:
			return float3(0.425,21.25,99.5);     //Bioshock 2 Remastred
		case  47:
			return float3(0.279,100.0,0.905);    //Talos Principle
    default: // X Cutoff | Y Adjust | Z Tuneing //
			return float3(Weapon_Adjust.x,Weapon_Adjust.y,Weapon_Adjust.z);
	}
}
//////////////////////////////////////////////////////////Depth Map Alterations/////////////////////////////////////////////////////////////////////
float2 WeaponDepth(float2 texcoord)
{	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
	//Conversions to linear space.....
	float zBufferWH = tex2Dlod(DepthBufferV, float4(texcoord,0,0)).x, Far = 1.0, Near = 0.125/WHS().y;  //Near & Far Adjustment

	float2 Offsets = float2(1 + WHS().z,1 - WHS().z), Z = float2( zBufferWH, 1-zBufferWH );

	if (WHS().z > 0)
	Z = min( 1, float2( Z.x * Offsets.x , Z.y / Offsets.y  ));

	[branch] if (Depth_Map == 0)//DM0. Normal
		zBufferWH = Far * Near / (Far + Z.x * (Near - Far));
	else if (Depth_Map == 1)//DM1. Reverse
		zBufferWH = Far * Near / (Far + Z.y * (Near - Far));

	return float2(saturate(zBufferWH), WHS().x);
}

float3 DepthMap(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
		float4 DM = Depth(texcoord).xxxx;
		float R, G, B, WD = WeaponDepth(texcoord).x, CoP = WeaponDepth(texcoord).y, CutOFFCal = (CoP/DMA()) * 0.5; //Weapon Cutoff Calculation
		CutOFFCal = step(DM.x,CutOFFCal);

		[branch] if (WP == 0)
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
{ float LumAdjust_ADR = smoothstep(-0.0175,Auto_Depth_Adjust,Lum(texcoord).x);
    return min(1,( d - 0 ) / ( LumAdjust_ADR - 0));
}

float2 Conv(float D,float2 texcoord)
{	float Z = ZPD_Separation.x, WZP = 0.5, ZP = 0.5, ALC = abs(Lum(texcoord).x), W_Convergence = WZPD;

	if (Weapon_ZPD_Boundary > 0)
	{ //only really only need to check one point just above the center bottom.
		float WZPDB = 1 - WZPD / tex2Dlod(SamplerDM_NV,float4(float2(0.5,0.9375),0,0)).x;
		if (WZPDB < -0.1)
			W_Convergence *= 0.5-Weapon_ZPD_Boundary;
	}

		W_Convergence = 1 - W_Convergence / D;

		if (Auto_Depth_Adjust > 0)
			D = AutoDepthRange(D,texcoord);

		if(Auto_Balance_Ex > 0 )
			ZP = saturate(ALC);
		//ZPD Boundary Adjust
		Z *= lerp( 1, ZPD_Boundary_Adjust, smoothstep(0,1,tex2Dlod(SamplerLum_NV,float4(texcoord + 1,0,0)).z));
		float Convergence = 1 - Z / D;
		if (ZPD_Separation.x == 0)
			ZP = 1;

		if (WZPD <= 0)
			WZP = 1;

		if (ALC <= 0.025)
			WZP = 1;

		ZP = min(ZP,Auto_Balance_Clamp);
	float Separation = lerp(1.0,5.0,ZPD_Separation.y);
    return float2(lerp(Separation * Convergence,D, ZP),lerp(W_Convergence,D,WZP));
}

float DB(float2 texcoord)
{
	float3 DM = tex2Dlod(SamplerDM_NV,float4(texcoord,0,0)).xyz;

	if (WP == 0 || WZPD <= 0)
		DM.y = 0;

	DM.y = lerp(Conv(DM.x,texcoord).x, Conv(DM.z,texcoord).y, DM.y);

	if (!hasdepth)
		DM = 0.0625;

	return DM.y;
}

float zBuffer(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{   // Find Edges
		float t = DB( float2( texcoord.x , texcoord.y - pix.y ) ),
		d = DB( float2( texcoord.x , texcoord.y + pix.y ) ),
		l = DB( float2( texcoord.x - pix.x , texcoord.y ) ),
		r = DB( float2( texcoord.x + pix.x , texcoord.y ) );
		float2 n = float2(t - d,-(r - l));
		// Lets make that mask from Edges
		float Mask = length(n) * 0.1;
		Mask = Mask > 0 ? 1-Mask : 1;
		Mask = saturate(lerp(Mask,1,-1));// Super Evil Mix.
		// Final Depth
		return lerp(1,DB( texcoord.xy ),Mask);
}

float GetDB(float2 texcoord)
{
	return tex2Dlod(SamplerZBuffer_NV, float4(texcoord,0,0) ).x;
}
//////////////////////////////////////////////////////////Parallax Generation///////////////////////////////////////////////////////////////////////
float2 Parallax(float Diverge, float2 Coordinates) // Horizontal parallax offset & Hole filling effect
{ float2 ParallaxCoord = Coordinates;
	float Perf = 1, MS = Diverge * pix.x;

	if(Performance_Mode)
		Perf = .5;
	//ParallaxSteps Calculations
	float D = abs(Diverge), Cal_Steps = (D * Perf) + (D * 0.04), Steps = clamp(Cal_Steps,0,255);
	// Offset per step progress & Limit
	float LayerDepth = rcp(Steps);
	//Offsets listed here Max Seperation is 3% - 8% of screen space with Depth Offsets & Netto layer offset change based on MS.
	float deltaCoordinates = MS * LayerDepth, CurrentDepthMapValue = GetDB(ParallaxCoord), CurrentLayerDepth = 0, DepthDifference;
	float2 DB_Offset = float2(Diverge * 0.03, 0) * pix;

	if(View_Mode == 1)
		DB_Offset = 0;
	//DX12 nor Vulkan was tested.
	//Do-While Loop Seems to be faster then for or while loop in DX 9, 10, and 11. But, not in openGL. In some rare openGL games it causes CTD
	//For loop is broken in this shader for some reason in DX9. I don't know why. This is the reason for the change. I blame Voodoo Magic
	//While Loop is the most compatible of the bunch. So I am forced to use this loop.
	[loop] // Steep parallax mapping
	while ( CurrentDepthMapValue > CurrentLayerDepth)
	{   // Shift coordinates horizontally in linear fasion
	    ParallaxCoord.x -= deltaCoordinates;
	    // Get depth value at current coordinates
	    CurrentDepthMapValue = GetDB(ParallaxCoord - DB_Offset);
	    // Get depth of next layer
		CurrentLayerDepth += LayerDepth;
		continue;
	}
	// Parallax Occlusion Mapping
	float2 PrevParallaxCoord = float2(ParallaxCoord.x + deltaCoordinates, ParallaxCoord.y);
	float beforeDepthValue = GetDB(ParallaxCoord), afterDepthValue = CurrentDepthMapValue - CurrentLayerDepth;
		beforeDepthValue += LayerDepth - CurrentLayerDepth;
	// Interpolate coordinates
	float weight = afterDepthValue / (afterDepthValue - beforeDepthValue);
		ParallaxCoord = PrevParallaxCoord * weight + ParallaxCoord * (1. - weight);
	//This is to limit artifacts.
	if(View_Mode == 0)
		ParallaxCoord += DB_Offset * 0.5;
	// Apply gap masking
	DepthDifference = (afterDepthValue-beforeDepthValue) * MS;
	if(View_Mode == 1)
		ParallaxCoord.x -= DepthDifference;

	return ParallaxCoord;
}
//////////////////////////////////////////////////////////////HUD Alterations///////////////////////////////////////////////////////////////////////
float3 HUD(float3 HUD, float2 texcoord )
{
	float Mask_Tex, CutOFFCal = ((HUD_Adjust.x * 0.5)/DMA()) * 0.5, COC = step(Depth(texcoord).x,CutOFFCal); //HUD Cutoff Calculation

	//This code is for hud segregation.
	if (HUD_Adjust.x > 0)
		HUD = COC > 0 ? tex2D(BackBufferCLAMPV,texcoord).rgb : HUD;

	#if UI_MASK
	    if (Mask_Cycle == true)
	        Mask_Tex = tex2D(SamplerDMMask,texcoord.xy).a;

		float MAC = step(1.0-Mask_Tex,0.5); //Mask Adjustment Calculation
		//This code is for hud segregation.
		HUD = MAC > 0 ? tex2D(BackBufferCLAMPV,texcoord).rgb : HUD;
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

	float4 color, Left = MouseCursor(Parallax(-DLR.x, TCL)), Right = MouseCursor(Parallax(DLR.y, TCR));
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
		float3 LMA = lerp(HalfLA,Left.rgb,0.75), RMA = lerp(HalfRA,Right.rgb,0.75);//Hard Locked 0.75% color forlower ghosting.
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

	float Storage = texcoord < 0.5 ? tex2D(SamplerDM_NV,0).x : tex2D(SamplerDM_NV,1).x;

	return float3(Average_Lum_ZPD,Average_Lum_Bottom,Storage);
}
/////////////////////////////////////////////////////////////////////////Logo///////////////////////////////////////////////////////////////////////
float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float PosX = 0.9525f*BUFFER_WIDTH*pix.x,PosY = 0.975f*BUFFER_HEIGHT*pix.y;
	float4 Color = float4(PS_calcLR(texcoord).rgb,1.0),D,E,P,T,H,Three,DD,Dot,I,N,F,O;

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
///////////////////////////////////////////////////////////////////ReShade.fxh//////////////////////////////////////////////////////////////////////
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{// Vertex shader generating a triangle covering the entire screen
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}//Using this to make it portable
//*Rendering passes*//
technique Depth3D_NV
{
		pass DepthBufferV
	{
		VertexShader = PostProcessVS;
		PixelShader = DepthMap;
		RenderTarget = texDM_NV;
	}
		pass zbufferLM
	{
		VertexShader = PostProcessVS;
		PixelShader = zBuffer;
		RenderTarget = texZBuffer_NV;
	}
		pass AverageLuminance
	{
		VertexShader = PostProcessVS;
		PixelShader = Average_Luminance;
		RenderTarget = texLum_NV;
	}
		pass StereoOut
	{
		VertexShader = PostProcessVS;
		PixelShader = Out;
	}
}
