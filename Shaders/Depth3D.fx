////-----------//
///**Depth3D**///
//-----------////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//* Depth Map Based 3D post-process shader Depth3D v1.2.0                                                                                                                          *//
//* For Reshade 3.0 & 4.0                                                                                                                                                          *//
//* ---------------------------------------------------------------------------------------------------                                                                            *//
//* This work is licensed under a Creative Commons Attribution 3.0 Unported License.                                                                                               *//
//* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.                                                                              *//
//* I would also love to hear about a project you are using it with.                                                                                                               *//
//* https://creativecommons.org/licenses/by/3.0/us/                                                                                                                                *//
//*                                                                                                                                                                                *//
//* Have fun,                                                                                                                                                                      *//
//* Jose Negrete AKA BlueSkyDefender                                                                                                                                               *//
//*                                                                                                                                                                                *//
//* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader                                                                             *//
//* ---------------------------------------------------------------------------------------------------                                                                            *//
//*                                                                                                                                                                                *//
//* This Shader is an simplified version of SuperDepth3D_FlashBack.fx a shader I made for ReShade's collection standard effects. For the use with stereo 3D screen                 *//
//* The main shader this Depth3D shader is based on is located here. https://github.com/BlueSkyDefender/Depth3D/blob/master/Shaders/SuperDepth3D_FB.fx                             *//
//* Original work was based on Shader Based on forum user 04348 and be located here. http://reshade.me/forum/shader-presentation/1594-3d-anaglyph-red-cyan-shader-wip#15236        *//
//*                                                                                                                                                                                *//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//USER EDITABLE PREPROCESSOR FUNCTIONS START//

// Determines the Max Depth amount, in ReShades GUI.
#define Depth_Max 50

//Define Display aspect ratio for screen cursor. A 16:9 aspect ratio will equal (1.77:1)
#define DAR float2(1.77, 1.0)

//USER EDITABLE PREPROCESSOR FUNCTIONS END//

#if !defined(__RESHADE__) || __RESHADE__ < 40000
	#define Compatibility 1
#else
	#define Compatibility 0
#endif

//Divergence & Convergence//
uniform float Divergence <
	ui_type = "drag";
	ui_min = 1; ui_max = Depth_Max; ui_step = 0.5;
	ui_label = "·Divergence·";
	ui_tooltip = "Divergence increases differences between the left and right images, allows you to experience depth.\n" 
				 "The process of deriving binocular depth information is called stereopsis.\n"
				 "You can override this value, at an peformance cost.";
	ui_category = "Divergence & Convergence";
> = 25.0;

uniform float ZPD <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.125;
	ui_label = " Convergence";
	ui_tooltip = "Convergence controls the focus distance for the screen Pop-out effect also known as ZPD.\n"
				 "For FPS Games keeps this low Since you don't want your gun to pop out of screen.\n"
				 "If you want to push this higher you need to adjust your Weapon Hand below.\n"
				 "It helps to keep this around 0.03 when adjusting the DM or Weapon Hand.\n"
				 "Default is 0.010, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.010;

uniform float Auto_Depth_Range <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.625;
	ui_label = " Auto Depth Range";
	ui_tooltip = "The Map Automaticly scales to outdoor and indoor areas.\n" 
				 "Default is 0.1f, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.1;

//Depth Buffer Adjust//
uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "Z-Buffer Normal\0Z-Buffer Reversed\0";
	ui_label = "·Z-Buffer Selection·";
	ui_tooltip = "Select Depth Buffer Linearization.";
	ui_category = "Depth Buffer Adjust";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 1.0; ui_max = 250.0; ui_step = 0.125;
	ui_label = " Z-Buffer Adjustment";
	ui_tooltip = "This allows for you to adjust Depth Buffer Precision.\n"
				 "Try to adjust this to keep it as low as possible.\n"
				 "Don't go too high with this adjustment.\n"
				 "Default is 7.5";
	ui_category = "Depth Buffer Adjust";
> = 7.5;

uniform float Offset <
	ui_type = "drag";
	ui_min = 0; ui_max = 1.0;
	ui_label = " Z-Buffer Offset";
	ui_tooltip = "Depth Buffer Offset is for non conforming Z-Buffer.\n"
				 "It's rare if you need to use this in any game.\n"
				 "This makes adjustments to Normal and Reversed.\n"
				 "Default is Zero & Zero is Off.";
	ui_category = "Depth Buffer Adjust";
> = 0.0;

uniform bool Depth_Map_View <
	ui_label = " Display Depth";
	ui_tooltip = "Display the Depth Buffer.";
	ui_category = "Depth Buffer Adjust";
> = false;

uniform bool Depth_Map_Flip <
	ui_label = " Flip Depth";
	ui_tooltip = "Flip the Depth Buffer if it is upside down.";
	ui_category = "Depth Buffer Adjust";
> = false;

//Weapon Hand Adjust//
uniform bool WP <
	ui_label = "·Weapon Hand Adjust·";
	ui_tooltip = "Enables Weapon Hand Adjust for your game.";
	ui_category = "Weapon Hand Adjust";
> = false;

uniform int Weapon_Scale <
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
	ui_min = -3; ui_max = 3;
	ui_label = " Weapon Scale";
	ui_tooltip = "Use this to set the proper weapon hand scale.";
	ui_category = "Weapon Hand Adjust";
> = 0;

uniform float2 Weapon_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 25.0;
	ui_label = " Weapon Hand Adjust";
	ui_tooltip = "Adjust Weapon depth map for your games.\n"
				 "X, CutOff Point used to set a diffrent scale for first person hand apart from world scale.\n"
				 "Y, Precision is used to adjust the first person hand in world scale.\n"
	             "Default is float2(X 0.0, Y 0.0)";
	ui_category = "Weapon Hand Adjust";
> = float2(0.0,0.0);

uniform float Weapon_Depth_Adjust <
	ui_type = "drag";
	ui_min = -50.0; ui_max = 50.0; ui_step = 0.25;
	ui_label = " Weapon Depth Adjustment";
	ui_tooltip = "Pushes or Pulls the FPS Hand in or out of the screen if a weapon profile is selected.\n"
				 "This also used to fine tune the Weapon Hand if creating a weapon profile.\n" 
				 "Default is Zero.";
	ui_category = "Weapon Hand Adjust";
> = 0;

//Stereoscopic Options//
uniform int Stereoscopic_Mode <
	ui_type = "combo";
	ui_items = "Side by Side\0Top and Bottom\0Line Interlaced\0Anaglyph 3D Red/Cyan\0Anaglyph 3D Dubois Red/Cyan\0Anaglyph 3D Green/Magenta\0Anaglyph 3D Dubois Green/Magenta\0";
	ui_label = "·3D Display Modes·";
	ui_tooltip = "Stereoscopic 3D display output selection.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform float Anaglyph_Desaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = " Anaglyph Desaturation";
	ui_tooltip = "Adjust anaglyph desaturation, Zero is Black & White, One is full color.";
	ui_category = "Stereoscopic Options";
> = 1.0;

uniform int Perspective <
	ui_type = "drag";
	ui_min = -100; ui_max = 100;
	ui_label = " Perspective Slider";
	ui_tooltip = "Determines the perspective point of your stereo pair.\n"
				 "Default is 0.0";
	ui_category = "Stereoscopic Options";
> = 0;

uniform bool Eye_Swap <
	ui_label = " Swap Eyes";
	ui_tooltip = "Left : Right to Right : Left.";
	ui_category = "Stereoscopic Options";
> = false;

//Crosshair Adjustments//
uniform float3 Cursor_STT <
	ui_type = "drag";
	ui_min = 0; ui_max = 1;
	ui_label = " Crosshair Adjustments";
	ui_tooltip = "This controlls the Size, Thickness, & Transparency.\n" 
				 "Defaults are ( X 0.125, Y 0.5, Z 0.75 ).";
	ui_category = "Cursor Adjustments";
> = float3(0.125,0.5,0.75);

uniform float3 Cursor_Color <
	ui_type = "color";
	ui_label = " Crosshair Color";
	ui_category = "Cursor Adjustments";
> = float3(1.0,1.0,1.0);

uniform bool SCSC <
	ui_label = " Cursor Lock";
	ui_tooltip = "Screen Cursor to Screen Crosshair Lock.";
	ui_category = "Cursor Adjustments";
> = false;

/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#include "ReShade.fxh"

#define pix ReShade::PixelSize

float fmod(float a, float b) 
{
	float c = frac(abs(a / b)) * abs(b);
	return a < 0 ? -c : c;
}	

sampler DepthBuffer
{
	Texture = ReShade::DepthBufferTex;
};

sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
	AddressU = BORDER;
	AddressV = BORDER;
	AddressW = BORDER;
};	
	
texture texDepth  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT ; Format = RGBA16F;}; 

sampler SamplerDepth
	{
		Texture = texDepth;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
texture texDiso  { Width = BUFFER_WIDTH ; Height = BUFFER_HEIGHT ; Format = RGBA16F; MipLevels = 1;}; 

sampler SamplerDiso
	{
		Texture = texDiso;
		MipLODBias = 1.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

texture texEncode  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; MipLevels = 1;};

sampler SamplerEncode
	{
		Texture = texEncode;
		MipLODBias = 1.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};			

uniform float2 Mousecoords < source = "mousepoint"; > ;	
////////////////////////////////////////////////////////////////////////////////////Cross Cursor////////////////////////////////////////////////////////////////////////////////////	
float4 MCursor(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float CCA = 0.1,CCB = 0.0025, CCC = 0.025, CCD = 0.05;
	float2 MousecoordsXY = Mousecoords * pix, center = texcoord, Screen_Ratio = float2(DAR.x,DAR.y), Size_Thickness = float2(Cursor_STT.x,Cursor_STT.y + 0.00000001);
	
	if (SCSC)
	MousecoordsXY = float2(0.5,0.5);
	
	float dist_fromHorizontal = abs(center.x - MousecoordsXY.x) * Screen_Ratio.x, Size_H = Size_Thickness.x * CCA, THICC_H = Size_Thickness.y * CCB;
	float dist_fromVertical = abs(center.y - MousecoordsXY.y) * Screen_Ratio.y , Size_V = Size_Thickness.x * CCA, THICC_V = Size_Thickness.y * CCB;	
	
	//Cross Cursor
	float B = min(max(THICC_H - dist_fromHorizontal,0)/THICC_H,max(Size_H-dist_fromVertical,0));
	float A = min(max(THICC_V - dist_fromVertical,0)/THICC_V,max(Size_V-dist_fromHorizontal,0));
	float CC = A+B; //Cross Cursor
		
	return lerp( CC  ? float4(Cursor_Color.rgb, 1.0) : tex2D(BackBuffer, texcoord),tex2D(BackBuffer, texcoord),1-Cursor_STT.z);
}
/////////////////////////////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////////////////
texture texLumi {Width = 256*0.5; Height = 256*0.5; Format = RGBA8; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1 
																				
sampler SamplerLumi																
	{
		Texture = texLumi;
		MipLODBias = 8.0f; //Luminance adapted luminance value from 1x1 Texture Mip lvl of 8
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
		
float Lumi(in float2 texcoord : TEXCOORD0)
	{
		float Luminance = tex2Dlod(SamplerLumi,float4(texcoord,0,0)).r; //Average Luminance Texture Sample 

		return Luminance;
	}
	
/////////////////////////////////////////////////////////////////////////////////Depth Map Information/////////////////////////////////////////////////////////////////////////////////

float Depth(in float2 texcoord : TEXCOORD0)
{	
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
		
	float zBuffer = tex2D(DepthBuffer, texcoord).x, DMA = Depth_Map_Adjust; //Depth Buffer

	
	//Conversions to linear space.....
	//Near & Far Adjustment
	float Far = 1.0, Near = 0.125/DMA; //Division Depth Map Adjust - Near
	
	float2 Offsets = float2(1 + Offset,1 - Offset), Z = float2( zBuffer, 1-zBuffer );
	
	if (Offset > 0)
	Z = min( 1, float2( Z.x*Offsets.x , Z.y /  Offsets.y  ));
		
	if (Depth_Map == 0)//DM0. Normal
		zBuffer = Far * Near / (Far + Z.x * (Near - Far));		
	else if (Depth_Map == 1)//DM1. Reverse
		zBuffer = Far * Near / (Far + Z.y * (Near - Far));
			
	return zBuffer;
}

float2 WeaponDepth(in float2 texcoord : TEXCOORD0)
{
	if (Depth_Map_Flip)
	texcoord.y =  1 - texcoord.y;
		
	float zBufferWH = tex2D(DepthBuffer, texcoord).x, CutOff = Weapon_Adjust.x , Adjust = Weapon_Adjust.y, Tune = Weapon_Depth_Adjust, Scale = Weapon_Scale;
	
	float4 WA_XYZW;//Weapon Profiles Starts Here
	if (WP == 1)                                   // WA_XYZW.x | WA_XYZW.y | WA_XYZW.z | WA_XYZW.w 
		WA_XYZW = float4(CutOff,Adjust,Tune,Scale);// X Cutoff  | Y Adjust  | Z Tuneing | W Scaling 		
	
	// Code Adjustment Values.
	// WA_XYZW.x | WA_XYZW.y | WA_XYZW.z | WA_XYZW.w 
	// X Cutoff  | Y Adjust  | Z Tuneing | W Scaling 	
	
	// Hear on out is the Weapon Hand Adjustment code.		
	float Set_Scale , P = WA_XYZW.y;
	
	if (WA_XYZW.w == -3)
	{
		WA_XYZW.x *= 21.0f;
		P = (P + 0.00000001) * 100;
		Set_Scale = 0.5f;
	}			
	if (WA_XYZW.w == -2)
	{
		P = (P + 0.00000001) * 100;
		Set_Scale = 0.5f;
	}
	else if (WA_XYZW.w == -1)
	{
		Set_Scale = 0.332;
		P = (P + 0.00000001) * 100;
	}
	else if (WA_XYZW.w == 0)
	{
		Set_Scale = 0.105;
		P = (P + 0.00000001) * 100;
	}
	else if (WA_XYZW.w == 1)
	{
		Set_Scale = 0.07265625;
		P = (P + 0.00000001) * 100;
	}
	else if (WA_XYZW.w == 2)
	{
		Set_Scale = 0.0155;
		P = (P + 0.00000001) * 2000;
	}	
	else if (WA_XYZW.w == 3)
	{
		Set_Scale = 0.01;
		P = (P + 0.00000001) * 100;
	}
	//FPS Hand Depth Maps require more precision at smaller scales to look right.		 		
	float Far = (P * Set_Scale) * (1+(WA_XYZW.z * 0.01f)), Near = P;
	
	float2 Z = float2( zBufferWH, 1-zBufferWH );
			
	if ( Depth_Map == 0 )
		zBufferWH /= Far - Z.x * (Near - Far);
	else if ( Depth_Map == 1 )
		zBufferWH /= Far - Z.y * (Near - Far);
	
	zBufferWH = saturate(zBufferWH);
	
	//This code is used to adjust the already set Weapon Hand Profile.
	float WA = 1 + (Weapon_Depth_Adjust * 0.015);
	if (WP > 1)
	zBufferWH = (zBufferWH - 0) /  (WA - 0);
	
	//Auto Anti Weapon Depth Map Z-Fighting is always on.
	float WeaponLumAdjust = saturate(abs(smoothstep(0,0.5,Lumi(texcoord)*2.5)));	
			
	//Anti Weapon Hand Z-Fighting code trigger
	//if (WP > 1)
	zBufferWH = saturate(lerp(0.025, zBufferWH, saturate(WeaponLumAdjust)));
				
	return float2(zBufferWH.x,WA_XYZW.x);	
}

void DepthMap(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 Color : SV_Target)
{		
		float4 DM = Depth(texcoord).xxxx;
		
		float DMA = Depth_Map_Adjust;
		
		float R, G, B, A, WD = WeaponDepth(texcoord).x, CoP = WeaponDepth(texcoord).y, CutOFFCal = (CoP / DMA) * 0.5f; //Weapon Cutoff Calculation
		
		CutOFFCal = step(DM.x,CutOFFCal);
					
		if (WP == 0)
		{
			DM.x = DM.x;
		}
		else
		{
			DM.x = lerp(DM.x,WD,CutOFFCal);
		}
		
		R = DM.x; //Mix Depth
		A = DM.w; //AverageLuminance
				
	Color = saturate(float4(R,G,B,A));
}

float AutoDepthRange( float d, float2 texcoord )
{
	float LumAdjust = smoothstep(-0.0175,Auto_Depth_Range,Lumi(texcoord));
    return min(1,( d - 0 ) / ( LumAdjust - 0));
}

float Conv(float DM,float2 texcoord)
{
	float Z = ZPD, ZP = 0.54875f;
				
		if (ZPD == 0)
			ZP = 1.0f;
		
		if (Auto_Depth_Range > 0)
			DM = AutoDepthRange(DM,texcoord);
								
		float Convergence = 1 - Z / DM;
									
		Z = lerp(Convergence,DM, ZP);
				
    return Z;
}

void  Disocclusion(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0)
{
	float DM, A, S, MS =  (Divergence * 0.875f) * pix.x, Div = 1.0f / 7.0f, MA = 2.0 , M = distance(1.0f , tex2Dlod(SamplerDepth,float4(texcoord,0,0)).w), Mask = saturate(M * MA - 1.0f) > 0.0f;
	
	A += 5.5; // Normal
	float2 dir = float2(0.5,0.0);	
	
	const float weight[7] = {0.0f,0.0125f,-0.0125f,0.0375f,-0.0375f,0.05f,-0.05f};
				
	[loop]
	for (int i = 0; i < 7; i++)
	{	
		S = weight[i] * MS;
		DM += tex2Dlod(SamplerDepth,float4(texcoord + dir * S * A,0,0)).x*Div;
	}
	
	DM = lerp(lerp(tex2Dlod(SamplerDepth,float4(texcoord,0,0)).w, DM, abs(Mask)), DM, 0.625f );
	
	color = float4(DM,0,0,1.0);
}

/////////////////////////////////////////L/R//////////////////////////////////////////////////////////////////////

void Encode(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0) //zBuffer Color Channel Encode
{
	float N = 3, samples[3] = {0.5f,0.75f,1.0f};
	
	float DepthR = 1.0f, DepthL = 1.0f, MS = (-Divergence * pix.x) * 0.1f, MSL = Divergence * 0.3f;

	[loop]
	for ( int i = 0 ; i < N; i++ ) 
	{
		DepthL = min(DepthL,tex2Dlod(SamplerDiso, float4((texcoord.x - MS) - (samples[i] * MSL) * pix.x, texcoord.y,0,0)).x);
		DepthR = min(DepthR,tex2Dlod(SamplerDiso, float4((texcoord.x + MS) + (samples[i] * MSL) * pix.x, texcoord.y,0,0)).x);
	}	

	// X Right & Y Left
	float X = DepthL, Y = DepthR, Z = tex2Dlod(SamplerDiso,float4(texcoord,0,0)).x;
	color = float4(X,Y,Z,1.0);
}

float3 Decode(in float2 texcoord : TEXCOORD0)
{
	//Byte Shift for Debanding depth buffer in final 3D image & Disocclusion Decoding.
	float ByteN = 384, MS = Divergence * pix.x, X = texcoord.x + MS * Conv(tex2Dlod(SamplerEncode,float4(texcoord,0,0)).x,texcoord), Y = (1 - texcoord.x) + MS * Conv(tex2Dlod(SamplerEncode,float4(texcoord,0,0)).y,texcoord), Z = Conv(tex2Dlod(SamplerEncode,float4(texcoord,0,0)).z,texcoord);
	float A = dot(X.xxx, float3(1.0f, 1.0f / ByteN, 1.0f / (ByteN * ByteN)) ); //byte_to_float Left
	float B = dot(Y.xxx, float3(1.0f, 1.0f / ByteN, 1.0f / (ByteN * ByteN)) ); //byte_to_float Right
	float C = dot(Z.xxx, float3(1.0f, 1.0f / ByteN, 1.0f / (ByteN * ByteN)) ); //byte_to_float ZPD L & R
	return float3(A,B,C);
}

float4 PS_calcLR(float2 texcoord)
{
	float2 TCL, TCR, TexCoords = texcoord;
	float4 color, Right, Left;
	
	//MS is Max Seperation and P is Perspective Adjustment.	
	float MS = Divergence * pix.x, P = Perspective * pix.x, N, S;
						
	if(Eye_Swap)
	{
		if ( Stereoscopic_Mode == 0 )
		{
			TCL = float2((texcoord.x*2-1) - P,texcoord.y);
			TCR = float2((texcoord.x*2) + P,texcoord.y);
		}
		else if( Stereoscopic_Mode == 1 )
		{
			TCL = float2(texcoord.x - P,texcoord.y*2-1);
			TCR = float2(texcoord.x + P,texcoord.y*2);
		}
		else
		{
			TCL = float2(texcoord.x - P,texcoord.y);
			TCR = float2(texcoord.x + P,texcoord.y);
		}
	}	
	else
	{
		if (Stereoscopic_Mode == 0)
		{
			TCL = float2((texcoord.x*2) + P,texcoord.y);
			TCR = float2((texcoord.x*2-1) - P,texcoord.y);
		}
		else if(Stereoscopic_Mode == 1)
		{
			TCL = float2(texcoord.x + P,texcoord.y*2);
			TCR = float2(texcoord.x - P,texcoord.y*2-1);
		}
		else
		{
			TCL = float2(texcoord.x + P,texcoord.y);
			TCR = float2(texcoord.x - P,texcoord.y);
		}
	}
	
		float CCL = MS * Decode(float2(TCL.x + (Divergence * 0.1875) * pix.x, TCL.y)).z;
		float CCR = MS * Decode(float2(TCR.x - (Divergence * 0.1875) * pix.x, TCR.y)).z;
		
		Left = tex2Dlod(BackBuffer, float4(TCL.x + CCL, TCL.y,0,0));
		Right = tex2Dlod(BackBuffer, float4(TCR.x - CCR, TCR.y,0,0));
		
		[loop]
		for (int i = 0; i < Divergence + 5; i++) 
		{
			//L
			if( Decode(float2(TCL.x+i*pix.x,TCL.y)).y >= (1-TCL.x)-pix.x && Decode(float2(TCL.x+i*pix.x,TCL.y)).y <= (1-TCL.x)+pix.x * 7.5 )
						Left = tex2Dlod(BackBuffer, float4(TCL.x + i * pix.x, TCL.y,0,0));
			
			//R
			if( Decode(float2(TCR.x-i*pix.x,TCR.y)).x >= TCR.x-pix.x && Decode(float2(TCR.x-i*pix.x,TCR.y)).x <= TCR.x+pix.x * 7.5 )
						Right = tex2Dlod(BackBuffer, float4(TCR.x - i * pix.x, TCR.y,0,0));
		}		
	
	float4 cL = Left,cR = Right; //Left Image & Right Image

	if ( Eye_Swap )
	{
		cL = Right;
		cR = Left;	
	}
		
	if(!Depth_Map_View)
	{	
		float gridy = floor(TexCoords.y*BUFFER_HEIGHT);
		
		if(Stereoscopic_Mode == 0)
		{	
			color = TexCoords.x < 0.5 ? cL : cR;
		}
		else if(Stereoscopic_Mode == 1)
		{	
			color = TexCoords.y < 0.5 ? cL : cR;
		}
		else if(Stereoscopic_Mode == 2)
		{
			color = fmod(gridy,2.0) ? cR : cL;	
		}
		else if(Stereoscopic_Mode >= 3)
		{													
				float3 HalfLA = dot(cL.rgb,float3(0.299, 0.587, 0.114));
				float3 HalfRA = dot(cR.rgb,float3(0.299, 0.587, 0.114));
				float3 LMA = lerp(HalfLA,cL.rgb,Anaglyph_Desaturation);  
				float3 RMA = lerp(HalfRA,cR.rgb,Anaglyph_Desaturation); 
				
				float4 cA = float4(LMA,1);
				float4 cB = float4(RMA,1);
	
			if (Stereoscopic_Mode == 3)
			{
				float4 LeftEyecolor = float4(1.0,0.0,0.0,1.0);
				float4 RightEyecolor = float4(0.0,1.0,1.0,1.0);
				
				color =  (cA*LeftEyecolor) + (cB*RightEyecolor);
			}
			else if (Stereoscopic_Mode == 4)
			{
			float red = 0.437 * cA.r + 0.449 * cA.g + 0.164 * cA.b
					- 0.011 * cB.r - 0.032 * cB.g - 0.007 * cB.b;
			
			if (red > 1) { red = 1; }   if (red < 0) { red = 0; }

			float green = -0.062 * cA.r -0.062 * cA.g -0.024 * cA.b 
						+ 0.377 * cB.r + 0.761 * cB.g + 0.009 * cB.b;
			
			if (green > 1) { green = 1; }   if (green < 0) { green = 0; }

			float blue = -0.048 * cA.r - 0.050 * cA.g - 0.017 * cA.b 
						-0.026 * cB.r -0.093 * cB.g + 1.234  * cB.b;
			
			if (blue > 1) { blue = 1; }   if (blue < 0) { blue = 0; }

			color = float4(red, green, blue, 0);
			}
			else if (Stereoscopic_Mode == 5)
			{
				float4 LeftEyecolor = float4(0.0,1.0,0.0,1.0);
				float4 RightEyecolor = float4(1.0,0.0,1.0,1.0);
				
				color =  (cA*LeftEyecolor) + (cB*RightEyecolor);			
			}
			else if (Stereoscopic_Mode == 6)
			{
								
			float red = -0.062 * cA.r -0.158 * cA.g -0.039 * cA.b
					+ 0.529 * cB.r + 0.705 * cB.g + 0.024 * cB.b;
			
			if (red > 1) { red = 1; }   if (red < 0) { red = 0; }

			float green = 0.284 * cA.r + 0.668 * cA.g + 0.143 * cA.b 
						- 0.016 * cB.r - 0.015 * cB.g + 0.065 * cB.b;
			
			if (green > 1) { green = 1; }   if (green < 0) { green = 0; }

			float blue = -0.015 * cA.r -0.027 * cA.g + 0.021 * cA.b 
						+ 0.009 * cB.r + 0.075 * cB.g + 0.937  * cB.b;
			
			if (blue > 1) { blue = 1; }   if (blue < 0) { blue = 0; }
					
			color = float4(red, green, blue, 0);
			}
		}
	}
		else
	{		
			float3 RGB = tex2Dlod(SamplerDiso,float4(TexCoords.x, TexCoords.y,0,0)).xxx;
			color = float4(RGB.r,AutoDepthRange(RGB.g,TexCoords),RGB.b,1.0);
	}

	return float4(color.rgb,1.0);
}

float4 Average_Luminance(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 Average_Lum = tex2D(SamplerDepth,float2(texcoord.x,texcoord.y)).www;
	return float4(Average_Lum,1.0);
}

////////////////////////////////////////////////////////Logo/////////////////////////////////////////////////////////////////////////
uniform float timer < source = "timer"; >;
float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float PosX = 0.5*BUFFER_WIDTH*pix.x,PosY = 0.5*BUFFER_HEIGHT*pix.y;	
	float4 Color = float4(PS_calcLR(texcoord).rgb,1.0),Done,Website,D,E,P,T,H,Three,DD,Dot,I,N,F,O;
	
	if(timer <= 10000)
	{
	//DEPTH
	//D
	float PosXD = -0.035+PosX, offsetD = 0.001;
	float4 OneD = all( abs(float2( texcoord.x -PosXD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoD = all( abs(float2( texcoord.x -PosXD-offsetD, texcoord.y-PosY)) < float2(0.0025,0.007));
	D = OneD-TwoD;
	
	//E
	float PosXE = -0.028+PosX, offsetE = 0.0005;
	float4 OneE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.009));
	float4 TwoE = all( abs(float2( texcoord.x -PosXE-offsetE, texcoord.y-PosY)) < float2(0.0025,0.007));
	float4 ThreeE = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.001));
	E = (OneE-TwoE)+ThreeE;
	
	//P
	float PosXP = -0.0215+PosX, PosYP = -0.0025+PosY, offsetP = 0.001, offsetP1 = 0.002;
	float4 OneP = all( abs(float2( texcoord.x -PosXP, texcoord.y-PosYP)) < float2(0.0025,0.009*0.682));
	float4 TwoP = all( abs(float2( texcoord.x -PosXP-offsetP, texcoord.y-PosYP)) < float2(0.0025,0.007*0.682));
	float4 ThreeP = all( abs(float2( texcoord.x -PosXP+offsetP1, texcoord.y-PosY)) < float2(0.0005,0.009));
	P = (OneP-TwoP) + ThreeP;

	//T
	float PosXT = -0.014+PosX, PosYT = -0.008+PosY;
	float4 OneT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosYT)) < float2(0.003,0.001));
	float4 TwoT = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosY)) < float2(0.000625,0.009));
	T = OneT+TwoT;
	
	//H
	float PosXH = -0.0071+PosX;
	float4 OneH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.001));
	float4 TwoH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 ThreeH = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.003,0.009));
	H = (OneH-TwoH)+ThreeH;
	
	//Three
	float offsetFive = 0.001, PosX3 = -0.001+PosX;
	float4 OneThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.009));
	float4 TwoThree = all( abs(float2( texcoord.x -PosX3 - offsetFive, texcoord.y-PosY)) < float2(0.003,0.007));
	float4 ThreeThree = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.001));
	Three = (OneThree-TwoThree)+ThreeThree;
	
	//DD
	float PosXDD = 0.006+PosX, offsetDD = 0.001;	
	float4 OneDD = all( abs(float2( texcoord.x -PosXDD, texcoord.y-PosY)) < float2(0.0025,0.009));
	float4 TwoDD = all( abs(float2( texcoord.x -PosXDD-offsetDD, texcoord.y-PosY)) < float2(0.0025,0.007));
	DD = OneDD-TwoDD;
	
	//Dot
	float PosXDot = 0.011+PosX, PosYDot = 0.008+PosY;		
	float4 OneDot = all( abs(float2( texcoord.x -PosXDot, texcoord.y-PosYDot)) < float2(0.00075,0.0015));
	Dot = OneDot;
	
	//INFO
	//I
	float PosXI = 0.0155+PosX, PosYI = 0.004+PosY, PosYII = 0.008+PosY;
	float4 OneI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosY)) < float2(0.003,0.001));
	float4 TwoI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYI)) < float2(0.000625,0.005));
	float4 ThreeI = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYII)) < float2(0.003,0.001));
	I = OneI+TwoI+ThreeI;
	
	//N
	float PosXN = 0.0225+PosX, PosYN = 0.005+PosY,offsetN = -0.001;
	float4 OneN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN)) < float2(0.002,0.004));
	float4 TwoN = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN - offsetN)) < float2(0.003,0.005));
	N = OneN-TwoN;
	
	//F
	float PosXF = 0.029+PosX, PosYF = 0.004+PosY, offsetF = 0.0005, offsetF1 = 0.001;
	float4 OneF = all( abs(float2( texcoord.x -PosXF-offsetF, texcoord.y-PosYF-offsetF1)) < float2(0.002,0.004));
	float4 TwoF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0025,0.005));
	float4 ThreeF = all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0015,0.00075));
	F = (OneF-TwoF)+ThreeF;
	
	//O
	float PosXO = 0.035+PosX, PosYO = 0.004+PosY;
	float4 OneO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.003,0.005));
	float4 TwoO = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.002,0.003));
	O = OneO-TwoO;
	}
	
	Website = D+E+P+T+H+Three+DD+Dot+I+N+F+O ? float4(1.0,1.0,1.0,1) : Color;
	
	if(timer >= 10000)
	{
		Done = Color;
	}
	else
	{
		Done = Website;
	}

	return Done;
}

//*Rendering passes*//

technique Crosshair
{			
		pass CrossCursor
	{
		VertexShader = PostProcessVS;
		PixelShader = MCursor;
	}	
}

technique Depth3D
{
		pass AverageLuminance
	{
		VertexShader = PostProcessVS;
		PixelShader = Average_Luminance;
		RenderTarget = texLumi;
	}
		pass zbuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = DepthMap;
		RenderTarget = texDepth;
	}
		pass Disocclusion
	{
		VertexShader = PostProcessVS;
		PixelShader = Disocclusion;
		RenderTarget = texDiso;
	}
		pass Encoding
	{
		VertexShader = PostProcessVS;
		PixelShader = Encode;
		RenderTarget = texEncode;
	}
		pass StereoOut
	{
		VertexShader = PostProcessVS;
		PixelShader = Out;
	}
}