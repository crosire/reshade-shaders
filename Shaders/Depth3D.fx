 ////---------------------------//
 ///**Depth3D_FlashBack_Basic**///
 //---------------------------////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Depth Map Based 3D post-process shader v1.9.9 FlashBack																														*//
 //* For Reshade 3.0																																								*//
 //* --------------------------																																						*//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																								*//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																				*//
 //* I would also love to hear about a project you are using it with.																												*//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Have fun,																																										*//
 //* Jose Negrete AKA BlueSkyDefender																																				*//
 //*																																												*//
 //* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader																				*//	
 //* ---------------------------------																																				*//
 //*																																												*//
 //* Original work was based on Shader Based on forum user 04348 and be located here http://reshade.me/forum/shader-presentation/1594-3d-anaglyph-red-cyan-shader-wip#15236			*//
 //*																																												*//
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//USER EDITABLE PREPROCESSOR FUNCTIONS START//

// Determines The resolution of the Depth Map.
#define Depth_Map_Division 2.0

// Determines the Max Depth amount, in ReShades GUI.
#define Depth_Max 50

//USER EDITABLE PREPROCESSOR FUNCTIONS END//
//Stereopsis Output//
uniform int Mode <
	ui_type = "combo";
	ui_items = "Reprojection L\0Reprojection R\0Reprojection L & R\0";
	ui_label = "·Reprojection Mode·";
	ui_tooltip = "Reprojection Mode changes the view output for this shader.\n"
			     "Reproject L or R uses a lot less resoruses than L & R.\n"
			     "Default is Reprojection of Left & Right Eyes.";
	ui_category = "Stereopsis Output";
> = 2;

//Divergence & Convergence//
uniform float Divergence <
	ui_type = "drag";
	ui_min = 1; ui_max = Depth_Max;
	ui_label = "·Divergence Slider·";
	ui_tooltip = "Divergence increases differences between the left and right retinal images and allows you to experience depth.\n" 
				 "The process of deriving binocular depth information is called stereopsis.\n"
				 "You can override this value.";
	ui_category = "Divergence & Convergence";
> = 25.0;

uniform bool ZPD_GUIDE <
	ui_label = " ZPD GUIDE";
	ui_tooltip = "A Guide used to Adjust Convergence.";
	ui_category = "Divergence & Convergence";
> = false;

uniform float ZPD <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.100;
	ui_label = " Zero Parallax Distance";
	ui_tooltip = "ZPD controls the focus distance for the screen Pop-out effect also known as Convergence.\n"
				"For FPS Games keeps this low Since you don't want your gun to pop out of screen.\n"
				"If you want to push this higher you need to adjust your weapon hand below.\n"
				"Default is 0.010, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.010;

uniform float Auto_Depth_Range <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.625;
	ui_label = " Auto Depth Range";
	ui_tooltip = "The Map Automaticly scales to outdoor and indoor areas.\n" 
				 "Default is Zero, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.0;

uniform float Disocclusion_Power_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 5.0;
	ui_label = " Disocclusion Power Adjust";
	ui_tooltip = "Automatic occlusion masking power adjust.\n"
				"Default is 1.0";
	ui_category = "Occlusion Masking";
> = 1.250;

//Depth Map//
uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "DM0 Normal\0DM1 Normal Reversed\0";
	ui_label = "·Depth Map Selection·";
	ui_tooltip = "Linearization for the zBuffer also known as Depth Map.\n"
			     "Normally you want to use DM0 or DM1 in most cases.";
	ui_category = "Depth Map";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 1.0; ui_max = 150.0;
	ui_label = " Depth Map Adjustment";
	ui_tooltip = "This allows for you to adjust the DM precision.\n"
				 "Adjust this to keep it as low as possible.\n"
				 "Default is 7.5";
	ui_category = "Depth Map";
> = 7.5;

uniform bool Depth_Map_View <
	ui_label = " Depth Map View";
	ui_tooltip = "Display the Depth Map.";
	ui_category = "Depth Map";
> = false;

uniform bool Depth_Map_Flip <
	ui_label = " Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
	ui_category = "Depth Map";
> = false;

//Weapon Hand Scale Options//
uniform int Weapon_Scale <
	ui_type = "drag";
	ui_min = 0; ui_max = 2;
	ui_label = " Weapon Scale";
	ui_tooltip = "Use this to target the weapon hand in world.";
	ui_category = "Weapon Depth Map";
> = 0;

uniform float3 Weapon_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 10.0;
	ui_label = " Weapon Hand Adjust";
	ui_tooltip = "Adjust Weapon depth map for your games.\n"
	             "Default is float3(CutOff  is 0.0 Off,Power is 2.0,Trim is 1.5).";
	ui_category = "Weapon Depth Map";
> = float3(0.0,2.0,1.5);

//Stereoscopic Options//
uniform int Stereoscopic_Mode <
	ui_type = "combo";
	ui_items = "Side by Side\0Top and Bottom\0Line Interlaced\0Anaglyph\0";
	ui_label = "·3D Display Modes·";
	ui_tooltip = "Stereoscopic 3D display output selection.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform float Interlace_Optimization <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = " Interlace Optimization";
	ui_tooltip = "Interlace Optimization Is used to reduce alisesing in a Line interlaced image.\n"
	             "This has the side effect of softening the image.\n"
	             "Default is 0.25";
	ui_category = "Stereoscopic Options";
> = 0.25;

uniform int Anaglyph_Colors <
	ui_type = "combo";
	ui_items = "Red/Cyan\0Dubois Red/Cyan\0Green/Magenta\0Dubois Green/Magenta\0";
	ui_label = " Anaglyph Color Mode";
	ui_tooltip = "Select colors for your 3D anaglyph glasses.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform float Anaglyph_Desaturation <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = " Anaglyph Desaturation";
	ui_tooltip = "Adjust anaglyph desaturation, Zero is Black & White, One is full color.";
	ui_category = "Stereoscopic Options";
> = 1.0;

uniform float Perspective <
	ui_type = "drag";
	ui_min = -100; ui_max = 100;
	ui_label = " Perspective Slider";
	ui_tooltip = "Determines the perspective point. Default is 0";
	ui_category = "Stereoscopic Options";
> = 0;

uniform bool Eye_Swap <
	ui_label = " Swap Eyes";
	ui_tooltip = "L/R to R/L.";
	ui_category = "Stereoscopic Options";
> = false;

//Cursor Adjustments//
uniform float4 Cross_Cursor_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 255.0;
	ui_label = "·Cross Cursor Adjust·";
	ui_tooltip = "Pick your own cross cursor color & Size.\n" 
				 " Default is (R 255, G 255, B 255 , Size 25)";
	ui_category = "Cursor Adjustments";
> = float4(255.0, 255.0, 255.0, 25.0);

/////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#include "ReShade.fxh"

#define pix ReShade::PixelSize

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
	
texture texDepth  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT/Depth_Map_Division; Format = RGBA32F; MipLevels = 1;}; 

sampler SamplerDepth
	{
		Texture = texDepth;
		MipLODBias = 1.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
texture texDiso  { Width = BUFFER_WIDTH/Depth_Map_Division; Height = BUFFER_HEIGHT/Depth_Map_Division; Format = RGBA32F; MipLevels = 2;}; 

sampler SamplerDiso
	{
		Texture = texDiso;
		MipLODBias = 2.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
			
uniform float2 Mousecoords < source = "mousepoint"; > ;	
////////////////////////////////////////////////////////////////////////////////////Cross Cursor////////////////////////////////////////////////////////////////////////////////////	
float4 MouseCursor(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 MousecoordsXY = Mousecoords * pix;
	float2 CC_Size = Cross_Cursor_Adjust.a * pix;
	float2 CC_ModeA = float2(1.25,1.0), CC_ModeB = float2(0.5,0.5);
	float4 Mpointer = all(abs(texcoord - MousecoordsXY) < CC_Size*CC_ModeA) * (1 - all(abs(texcoord - MousecoordsXY) > CC_Size/(Cross_Cursor_Adjust.a*CC_ModeB))) ? float4(Cross_Cursor_Adjust.rgb/255, 1.0) : tex2D(BackBuffer, texcoord);//cross
	
	return Mpointer;
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
float D()
{
	float D,D_Ammount = Divergence;
	if(Mode == 2)
	{
		D = D_Ammount;
	}
	else
	{
		D = D_Ammount * 2.0;
	}

	return D;
}

float NearestScaled( float DM )
{
	float NearestScaled, ScaleAdjust, TrasformAdjust;
	
	if (Weapon_Scale == 0)
	{
		NearestScaled = 0.001/(Weapon_Adjust.y*0.5);
		ScaleAdjust = Weapon_Adjust.z * 1.5;
		TrasformAdjust = 7.5;
	}
	else if (Weapon_Scale == 1)
	{
		NearestScaled = 0.0001/(Weapon_Adjust.y*0.5);
		ScaleAdjust = Weapon_Adjust.z * 6.25;
		TrasformAdjust = 3.75;
	}
	else if (Weapon_Scale == 2)
	{
		NearestScaled = 0.00001/(Weapon_Adjust.y*0.5);
		ScaleAdjust = Weapon_Adjust.z * 50.0;
		TrasformAdjust = 1.0;
	}
	
	DM = (smoothstep(0,1,DM) / NearestScaled ) - ScaleAdjust;
	
	float Far = 1, Near = 0.125/TrasformAdjust; //Division Depth Map Adjust - Near
	
	DM = Far * Near / (Far + DM * (Near - Far));
	
    return  DM;
}

float NearestScaledMerge( float DM )
{
		float Merge = lerp(DM,NearestScaled(DM),step(DM,Weapon_Adjust.x/100));
		Merge = lerp(Merge,DM,0.250);
		return  Merge;
}

void DepthMap(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 Color : SV_Target)
{		
		float R,G,B,A = 1.0;
		if (Depth_Map_Flip)
			texcoord.y =  1 - texcoord.y;
			
		float zBuffer = tex2D(DepthBuffer, texcoord).r; //Depth Buffer

		//Conversions to linear space.....
		//Near & Far Adjustment
		float Far = 1, Near = 0.125/Depth_Map_Adjust, NearLocked = 0.125/7.5; //Division Depth Map Adjust - Near
		
		//0. Normal
		float Normal = Far * Near / (Far + zBuffer * (Near - Far));
		float NormalLocked = Far * NearLocked / (Far + zBuffer * (NearLocked - Far));
		
		//1. Reverse
		float NormalReverse = Far * Near / (Near + zBuffer * (Far - Near));
		float NormalReverseLocked = Far * NearLocked / (NearLocked + zBuffer * (Far - NearLocked));
			
		float2 DM;
		
		if (Depth_Map == 0)
		{
			DM.x = Normal;
			DM.y = NormalLocked;
		}		
		else
		{
			DM.x = NormalReverse;
			DM.y = NormalReverseLocked;
		}
		
		R = DM.x;
		R = saturate(R);
		G = NearestScaledMerge(DM.y);
		//G = saturate(G);
	
	Color = float4(R,G,B,A);
}

float AutoDepthRange( float d, float2 texcoord )
{
	float LumAdjust = smoothstep(-0.0175,Auto_Depth_Range,Lumi(texcoord));
    return min(1,( d - 0 ) / ( LumAdjust - 0));
}

float Conv(float DM_A,float DM_B,float2 texcoord)
{
	float DM, Convergence, Z = ZPD, ZP = 0.5625;
		
		if (ZPD == 0)
			ZP = 1.0;
				
		float Convergence_A = 1 - Z / DM_A;		
		float Convergence_B = 1 - Z / DM_B;
						
		if (Auto_Depth_Range > 0)
		{
			DM_A = AutoDepthRange(DM_A,texcoord);
		}
		
		if (Weapon_Adjust.x > 0)
			Convergence_A = Convergence_B;
		
		DM = DM_A;		
		Convergence	= Convergence_A;
			
		Z = lerp(Convergence,DM, ZP);
		
    return Z;
}

void  Disocclusion(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0)
{
float X, Y, Z, W = 1, A, DP = D(), Disocclusion_PowerA , AMoffset = 0.00285714, BMoffset = 0.09090909;
float2 dirA, DM;

	DP *= Disocclusion_Power_Adjust;
		
	Disocclusion_PowerA = DP*AMoffset;
		
	if (Disocclusion_Power_Adjust > 0) 
	{
		const float weight[11] = {0.0,0.010,-0.010,0.020,-0.020,0.030,-0.030,0.040,-0.040,0.050,-0.050}; //By 10

		dirA = float2(0.5,0.0);
		A = Disocclusion_PowerA;

		
		[loop]
		for (int i = 0; i < 11; i++)
		{	
			DM += tex2Dlod(SamplerDepth,float4(texcoord + dirA * weight[i] * A,0,0)).xy*BMoffset;

		}	
	}
	else
	{
		DM = tex2Dlod(SamplerDepth,float4(texcoord,0,0)).xy;
	}

	X = DM.x;
	Y = DM.y;	
	color = float4(X,Y,Z,W);
}

/////////////////////////////////////////L/R//////////////////////////////////////////////////////////////////////

float2  Encode(in float2 texcoord : TEXCOORD0) //zBuffer Color Channel Encode
{
	float2 GetDepthL = tex2Dlod(SamplerDiso,float4(texcoord.x,texcoord.y,0,0)).xy;
	float2 GetDepthR = tex2Dlod(SamplerDiso,float4(texcoord.x,texcoord.y,0,0)).xy;
	
	GetDepthL.x = Conv(GetDepthL.x,GetDepthL.y,texcoord);
	GetDepthR.x = Conv(GetDepthR.x,GetDepthR.y,texcoord);
	
	float MS = D()*pix.x;
	
	// X Left	
	float X = texcoord.x+MS*GetDepthL.x;

	// Y Right
	float Y = (1-texcoord.x)+MS*GetDepthR.x;	
	
	return float2(X,Y);
}

float4 PS_calcLR(float2 texcoord)
{
	float Znum;
	float2 TCL, TCR, TexCoords = texcoord;
	float4 color, Right, Left;
	
	if(ZPD_GUIDE == 1)
	{
		Znum = 1;
	}
	else
	{
		Znum = 0;
	}
	
	float DepthL = Znum, DepthR = Znum, N, S, L, R;
	
	//P is Perspective Adjustment,PD is Perspective Aliment for mode 0 & 1.
	float P = Perspective * pix.x, PD = (D() * 0.5) * pix.x;
	
	if (Mode == 0)
		texcoord.x = texcoord.x	- PD;	
	else if (Mode == 1)
		texcoord.x = texcoord.x	+ PD;	
						
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
	
	//Optimization for line & column interlaced out.
	if (Stereoscopic_Mode == 2)
	{
		TCL.y = TCL.y + (Interlace_Optimization * pix.y);
		TCR.y = TCR.y - (Interlace_Optimization * pix.y);
	}
	else if (Stereoscopic_Mode == 3)
	{
		TCL.x = TCL.x + (Interlace_Optimization * pix.y);
		TCR.x = TCR.x - (Interlace_Optimization * pix.y);
	}
	
		[loop]
		for (int i = 0; i < D() + 0.5; i++) 
		{
			if(Mode == 0)
			{
				//L
				if ( Encode(float2(TCL.x+i*pix.x,TCL.y)).y >= (1-TCL.x))
				{
					DepthL = i * pix.x; //Good
				}
				
				DepthR = 0;
			}	
			
			if(Mode == 1)
			{
				DepthL = 0;
				
				//R
				if ( Encode(float2(TCR.x-i*pix.x,TCR.y)).x >= TCR.x )
				{
					DepthR = i * pix.x; //Good
				}
			}
			
			if(Mode == 2)
			{
				//L
				if ( Encode(float2(TCL.x+i*pix.x,TCL.y)).y >= (1-TCL.x) )
				{
					DepthL = i * pix.x; //Good
				}
				
				//R
				if ( Encode(float2(TCR.x-i*pix.x,TCR.y)).x >= TCR.x )
				{
					DepthR = i * pix.x; //Good
				}
			}
		}				

		Left = tex2Dlod(BackBuffer, float4(TCL.x + DepthL, TCL.y,0,0));
		Right = tex2Dlod(BackBuffer, float4(TCR.x - DepthR, TCR.y,0,0));
	
	float4 cL = Left,cR = Right; //Left Image & Right Image

	if ( Eye_Swap )
	{
		cL = Right;
		cR = Left;	
	}
		
	if(!Depth_Map_View)
	{	
	float2 gridxy = floor(float2(TexCoords.x*BUFFER_WIDTH,TexCoords.y*BUFFER_HEIGHT));

			
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
			color = int(gridxy.y) & 1 ? cR : cL;	
		}
		else if(Stereoscopic_Mode == 3)
		{													
				float3 HalfLA = dot(cL.rgb,float3(0.299, 0.587, 0.114));
				float3 HalfRA = dot(cR.rgb,float3(0.299, 0.587, 0.114));
				float3 LMA = lerp(HalfLA,cL.rgb,Anaglyph_Desaturation);  
				float3 RMA = lerp(HalfRA,cR.rgb,Anaglyph_Desaturation); 
				
				float4 cA = float4(LMA,1);
				float4 cB = float4(RMA,1);
	
			if (Anaglyph_Colors == 0)
			{
				float4 LeftEyecolor = float4(1.0,0.0,0.0,1.0);
				float4 RightEyecolor = float4(0.0,1.0,1.0,1.0);
				
				color =  (cA*LeftEyecolor) + (cB*RightEyecolor);
			}
			else if (Anaglyph_Colors == 1)
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
			else if (Anaglyph_Colors == 2)
			{
				float4 LeftEyecolor = float4(0.0,1.0,0.0,1.0);
				float4 RightEyecolor = float4(1.0,0.0,1.0,1.0);
				
				color =  (cA*LeftEyecolor) + (cB*RightEyecolor);			
			}
			else
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
			float4 Top = TexCoords.x < 0.5 ? Lumi(float2(TexCoords.x*2,TexCoords.y*2)).xxxx : tex2Dlod(SamplerDepth,float4(TexCoords.x*2-1 , TexCoords.y*2,0,0)).gggg;
			float4 Bottom = TexCoords.x < 0.5 ?  AutoDepthRange(tex2Dlod(SamplerDepth,float4(TexCoords.x*2 , TexCoords.y*2-1,0,0)).x,TexCoords) : tex2Dlod(SamplerDiso,float4(TexCoords.x*2-1,TexCoords.y*2-1,0,0)).xxxx;
			color = TexCoords.y < 0.5 ? Top : Bottom;
	}

	return float4(color.rgb,1.0);
}

float4 Average_Luminance(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 Average_Lum = tex2D(SamplerDepth,float2(texcoord.x,texcoord.y)).xxx;
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

technique Cross_Cursor
{			
			pass Cursor
		{
			VertexShader = PostProcessVS;
			PixelShader = MouseCursor;
		}	
}

technique Depth3D
{
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
		pass AverageLuminance
	{
		VertexShader = PostProcessVS;
		PixelShader = Average_Luminance;
		RenderTarget = texLumi;
	}
		pass StereoOut
	{
		VertexShader = PostProcessVS;
		PixelShader = Out;
	}
}