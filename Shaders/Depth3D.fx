 ////-----------//
 ///**Depth3D**///
 //-----------////

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Depth Map Based 3D post-process shader Depth3D v1.0 																															*//
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
 //* 																																												*//
 //* This Shader is an simplified version of SuperDepth3D_FlashBack.fx a shader I made for ReShade's collection standard effects. For the use with stereo 3D screen					*//
 //* The main shader this Depth3D shader is based on is located here. https://github.com/BlueSkyDefender/Depth3D/blob/master/Shaders/SuperDepth3D_FB.fx								*//
 //* Original work was based on Shader Based on forum user 04348 and be located here. http://reshade.me/forum/shader-presentation/1594-3d-anaglyph-red-cyan-shader-wip#15236		*//
 //*																																												*//
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//USER EDITABLE PREPROCESSOR FUNCTIONS START//

// Determines the Max Depth amount, in ReShades GUI.
#define Depth_Max 52.5

//USER EDITABLE PREPROCESSOR FUNCTIONS END//
//Divergence & Convergence//
uniform float Divergence <
	ui_type = "drag";
	ui_min = 1; ui_max = Depth_Max;
	ui_label = "·Divergence·";
	ui_tooltip = "Divergence increases differences between the left and right images, allows you to experience depth.\n" 
				 "The process of deriving binocular depth information is called stereopsis.\n"
				 "You can override this value, at an peformance cost.";
	ui_category = "Divergence & Convergence";
> = 25.0;

uniform bool ZPD_GUIDE <
	ui_label = " Convergence Guide";
	ui_tooltip = "A Guide used to help adjust convergence.";
	ui_category = "Divergence & Convergence";
> = false;

uniform float ZPD <
	ui_type = "slider";
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
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.625;
	ui_label = " Auto Depth Range";
	ui_tooltip = "The Map Automaticly scales to outdoor and indoor areas.\n" 
				 "Default is Zero, Zero is off.";
	ui_category = "Divergence & Convergence";
> = 0.0;

//Depth Buffer Adjust//
uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "Z-Buffer Normal\0Z-Buffer Reversed\0";
	ui_label = "·Z-Buffer Selection·";
	ui_tooltip = "Select Depth Buffer Linearization.";
	ui_category = "Depth Buffer Adjust";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 250.0;
	ui_label = " Z-Buffer Adjustment";
	ui_tooltip = "This allows for you to adjust Depth Buffer Precision.\n"
				 "Try to adjust this to keep it as low as possible.\n"
				 "Don't go too high with this adjustment.\n"
				 "Default is 7.5";
	ui_category = "Depth Buffer Adjust";
> = 7.5;

uniform float Offset <
	ui_type = "slider";
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

//Weapon Hand Scale Options//
uniform int Weapon_Scale <
	ui_type = "slider";
	ui_min = 0; ui_max = 2;
	ui_label = " Weapon Scale";
	ui_tooltip = "Use this to set the proper weapon hand scale.";
	ui_category = "Weapon Hand Adjust";
> = 0;

uniform float3 Weapon_Adjust <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 10.0;
	ui_label = " Weapon Hand Adjust";
	ui_tooltip = "Adjust Weapon depth map for your games.\n"
				 "X, The CutOff point used to set a diffrent depth scale for first person view.\n"
				 "Y, The Power needed to scale the first person view apart from world scale.\n"
				 "Z, Adjust is used to fine tune the first person view scale.\n"
	             "Default is float3(X 0.0, Y 2.0, Z 1.5)";
	ui_category = "Weapon Hand Adjust";
> = float3(0.0,2.0,1.5);

//Stereoscopic Options//
uniform int Stereoscopic_Mode <
	ui_type = "combo";
	ui_items = "Side by Side\0Top and Bottom\0Line Interlaced\0Anaglyph 3D Red/Cyan\0Anaglyph 3D Dubois Red/Cyan\0Anaglyph 3D Green/Magenta\0Anaglyph 3D Dubois Green/Magenta\0";
	ui_label = "·3D Display Modes·";
	ui_tooltip = "Stereoscopic 3D display output selection.";
	ui_category = "Stereoscopic Options";
> = 0;

uniform float Anaglyph_Desaturation <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = " Anaglyph Desaturation";
	ui_tooltip = "Adjust anaglyph desaturation, Zero is Black & White, One is full color.";
	ui_category = "Stereoscopic Options";
> = 1.0;

uniform float Perspective <
	ui_type = "slider";
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

//Cursor Adjustments//
uniform float4 Cross_Cursor_Adjust <
	ui_type = "slider";
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
	
texture texDepth  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT * 0.5; Format = RGBA32F; MipLevels = 1;}; 

sampler SamplerDepth
	{
		Texture = texDepth;
		MipLODBias = 1.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
texture texDiso  { Width = BUFFER_WIDTH * 0.5; Height = BUFFER_HEIGHT * 0.5; Format = RGBA32F; MipLevels = 2;}; 

sampler SamplerDiso
	{
		Texture = texDiso;
		MipLODBias = 2.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

texture texEncode  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA32F; MipLevels = 1;}; 

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

float NearestScaled( float DM )
{
	float WDM = DM, Nearest_Scaled = Weapon_Adjust.y, Scale_Adjust = Weapon_Adjust.z,CutOff = Weapon_Adjust.x/100, Set_Scale;
	
	if (Weapon_Scale == 0)
	{
		Nearest_Scaled = 0.001/(Nearest_Scaled*0.5);
		Scale_Adjust = Scale_Adjust * 1.5;
		Set_Scale = 7.5;
	}
	else if (Weapon_Scale == 1)
	{
		Nearest_Scaled = 0.0001/(Nearest_Scaled*0.5);
		Scale_Adjust = Scale_Adjust * 6.25;
		Set_Scale = 5.625;
	}
	else if (Weapon_Scale == 2)
	{
		Nearest_Scaled = 0.00001/(Nearest_Scaled*0.5);
		Scale_Adjust = Scale_Adjust * 50.0;
		Set_Scale = 3.75;
	}

	WDM = (smoothstep(0,1,WDM) / Nearest_Scaled ) - Scale_Adjust;
	
	float Far = 1, Near = 0.125/Set_Scale;
	
	WDM = Far * Near / (Far + WDM * (Near - Far));
    
	float Merge = lerp(DM,WDM,step(DM,CutOff)); //Cutoff point
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
	
	float2 DM, Offsets = float2(1 + Offset,1 - Offset), Z = float2( zBuffer, 1 - zBuffer );
	
	if (Offset > 0)
	Z = min( 1, float2( Z.x*Offsets.x , ( Z.y - 0.0 ) / ( Offsets.y - 0.0 ) ) );
	
	if (Depth_Map == 0) //DM0. Normal
	{
		DM = float2( 2.0 * Near * Far / (Far + Near - pow(abs(Z.x),2) * (Far - Near)), 2.0 * NearLocked * Far / (Far + NearLocked - pow(abs(Z.x),2) * (Far - NearLocked)) );
	}		
	else //DM1. Reverse
	{
		DM = float2( 2.0 * Near * Far / (Far + Near - pow(abs(Z.y),1.375) * (Far - Near)) , 2.0 * NearLocked * Far / (Far + NearLocked - pow(abs(Z.y),1.375) * (Far - NearLocked)) );
	}
	
	R = saturate(DM.x);
	G = saturate(NearestScaled(DM.y));
	
	Color = float4(R,G,B,A);
}

float AutoDepthRange( float d, float2 texcoord )
{
	float LumAdjust = smoothstep(-0.0175,Auto_Depth_Range,Lumi(texcoord));
    return min(1,( d - 0 ) / ( LumAdjust - 0));
}

float Conv(float2 DM_IN,float2 texcoord)
{
	float DM, Convergence, Z = ZPD, ZP = 0.54875f;
		
	if (Auto_Depth_Range > 0)
	{
		DM_IN.x = AutoDepthRange(DM_IN.x,texcoord);
		DM_IN.y = AutoDepthRange(DM_IN.y,texcoord);
	}
	
	if (ZPD == 0)
		ZP = 1.0;
		
	// You need to readjust the Z-Buffer if your going to use use the Convergence equation.
	float2 DMC = DM_IN.xy/(1-Z);		
					
	float Convergence_A = 1 - Z / DMC.x;		
	float Convergence_B = 1 - Z / DMC.y;
			  
	if (Weapon_Adjust.x > 0)
		Convergence_A = Convergence_B;
	
	DM = DM_IN.x;		
	Convergence	= Convergence_A;
		
	Z = lerp(Convergence,DM, ZP);
		
    return Z;
}

void  Disocclusion(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0)
{
float A, S, MS =  Divergence * pix.x, Div = 1.0f / 7.0f;
float2 DM, dir;
	
	A += 5.5; // Normal
	dir = float2(0.5,0.0);	
	
	const float weight[7] = {0.0f,0.0125f,-0.0125f,0.0375f,-0.0375f,0.05f,-0.05f};
				
	[loop]
	for (int i = 0; i < 7; i++)
	{	
		S = weight[i] * MS;
		DM += tex2Dlod(SamplerDepth,float4(texcoord + dir * S * A,0,1)).xy*Div;
	}
	
	color = float4(DM.x,DM.y,0,1.0);
}

/////////////////////////////////////////L/R//////////////////////////////////////////////////////////////////////

void Encode(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 color : SV_Target0) //zBuffer Color Channel Encode
{
	float2 DepthL = 1.0, DepthR = 1.0;
	float samples[3] = {0.5f,0.75f,1.0f}, MSL = (Divergence * 0.25f) * pix.x, S, MS = Divergence * pix.x;
		[loop]
	for ( int i = 0 ; i < 3; i++ ) 
	{
		S = samples[i] * MSL;
		DepthL = min(DepthL,tex2Dlod(SamplerDiso, float4(texcoord.x - S, texcoord.y,0,0)).xy);
		DepthR = min(DepthR,tex2Dlod(SamplerDiso, float4(texcoord.x + S, texcoord.y,0,0)).xy);
	}
	
	// X Left & Y Right
	float X = texcoord.x + MS * Conv(DepthL,texcoord), Y = (1 - texcoord.x) + MS * Conv(DepthR,texcoord);

	color = float4(X,Y,0.0,1.0);
}

float2 Decode(in float2 texcoord : TEXCOORD0)
{
	float3 X = abs(tex2Dlod(SamplerEncode,float4(texcoord,0,0)).xxx), Y = abs(tex2Dlod(SamplerEncode,float4(texcoord,0,0)).yyy);
	float ByteN = 640; //Byte Shift for Debanding depth buffer in final 3D image.
	float A = dot(X, float3(1.0f, 1.0f / ByteN, 1.0f / (ByteN * ByteN)) ); //byte_to_float
	float B = dot(Y, float3(1.0f, 1.0f / ByteN, 1.0f / (ByteN * ByteN)) ); //byte_to_float
	return float2(A,B);
}

float4 PS_calcLR(float2 texcoord)
{
	float2 TCL, TCR, TexCoords = texcoord;
	float4 color, Right, Left;
	
	//P is Perspective Adjustment.	
	float P = Perspective * pix.x, N, S;
						
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
		TCL.y = TCL.y + (0.25f * pix.y);
		TCR.y = TCR.y - (0.25f * pix.y);
	}
	else if (Stereoscopic_Mode == 3)
	{
		TCL.x = TCL.x + (0.25f * pix.x);
		TCR.x = TCR.x - (0.25f * pix.x);
	}
	
	if(ZPD_GUIDE == 1)
	{
		Left = 0.0f;
		Right = 0.0f;
	}
	else
	{
		Left = tex2Dlod(BackBuffer, float4(TCL,0,0));
		Right = tex2Dlod(BackBuffer, float4(TCR,0,0));
	}	
		
		[loop]
		for (int i = 0; i < Divergence + 5; i++) 
		{
			//L
			[flatten] if( Decode(float2(TCL.x+i*pix.x,TCL.y)).y > (1-TCL.x)-pix.x * 5 )
						Left = tex2Dlod(BackBuffer, float4(TCL.x + i * pix.x, TCL.y,0,0));
			
			//R
			[flatten] if( Decode(float2(TCR.x-i*pix.x,TCR.y)).x > TCR.x-pix.x * 5 )
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
			color = int(gridy) & 1 ? cR : cL;	
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
			float R = tex2Dlod(SamplerDepth,float4(TexCoords.x, TexCoords.y,0,0)).x;
			float G = AutoDepthRange(tex2Dlod(SamplerDepth,float4(TexCoords.x, TexCoords.y,0,0)).x,TexCoords);
			float B = tex2Dlod(SamplerDiso,float4(TexCoords.x,TexCoords.y,0,0)).g;
			color = float4(R,G,B,1.0);
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