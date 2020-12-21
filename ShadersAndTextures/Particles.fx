 ////-------------//
 ///**Particles**///
 //-------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Particles
 //* For ReShade 3.0+ & Freestyle
 //*  ---------------------------------
 //*                                                                       Particles
 //* Due Diligence
 //* Particles Generator based on the work of bleedingtiger2
 //* https://www.shadertoy.com/view/MscXD7 Search Ref. "Little Part"
 //* If I missed any please tell me.
 //*
 //* LICENSE
 //* ============
 //* Particles is licenses under: Attribution-NoDerivatives 4.0 International
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
 //* Special thanks to NVIDIA on compatibility with GeForce GPUs and feedback on shader development
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//ReShade / Freestyle Check
#if __RESHADE_FXC__
	#define RS 0
#else
	#define RS 1
#endif

uniform float Amount <
    ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Particles Amount";
	ui_tooltip = "Increase or decrease the particles amount.";
	ui_category = "Particle Adjustments";
> = 0.1;

uniform float Size <
    ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Particle Size";
	ui_tooltip = "Use to adjust particles size.";
	ui_category = "Particle Adjustments";
> = 0.1;

uniform float Waviness <
    ui_type = "slider";
	ui_min = 0.0; ui_max = 5.0;
	ui_label = "Particles Waviness";
	ui_tooltip = "Use to adjust particles Waviness.";
	ui_category = "Particle Flow";
	> = 0.500;

uniform float Speed <
    ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Particles Speed";
	ui_tooltip = "Use to adjust particles speed";
	ui_category = "Particle Flow";
	> = 0.1;

uniform int Degrees <
    ui_type = "slider";
	ui_min = 0; ui_max =  360;
	ui_label = "Rotation";
	ui_tooltip = "Left & Right Rotation Angle known as Degrees.\n"
				 "Default is Zero";
	ui_category = "Particle Flow";
> = 180;

uniform int Ambient_Colors<
	ui_type = "combo";
	ui_items = "Off / User Control\0Ambient\0Local Ambient\0";
	ui_label = "Average Ambient Color";
	ui_tooltip = "Uses Average of the screen to color the particles.";
	ui_category = "Particle Color";
> = 0;

uniform int Particles<
	ui_type = "combo";
	ui_items = "Basic Particles\0Halo Particles Dark\0Halo Particles Light\0Halo Particles Dark Alt\0Halo Particles Light Alt\0";
	ui_label = "Particle Type";
	ui_tooltip = "Pick your Ambient Color Mode.";
	ui_category = "Particle Color";
> = 2;
#define D_Color float3(255,215,0)/255
uniform float3 TintColor <
	ui_type = "color";
	ui_label = "Particle Color";
	ui_tooltip = "Lets you adjust the Particles Color";
	ui_category = "Particle Color";
	> = D_Color;

uniform float Intensity <
  ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Particle Color Intensity";
	ui_tooltip = "Use to adjust particles color intensity.";
	ui_category = "Particle Color";
> = 0.2;

uniform float Adjust_PC <
    ui_type = "slider";
	ui_min = -1.0; ui_max =  1.0;
	ui_label = "Particle Clamping";
	ui_tooltip = "Lets you clamp the particles radius.\n"
				 "This can cause artifacts with some setting plus Luma Clamping.\n"
       				 "Default is Zero";
	ui_category = "Particle Color";
> = 0.0;
#if RS
uniform bool MS_Type <
	ui_label = "Motion Detection Type";
	ui_tooltip = "Motion Detection Type lets you pick bettween WASD/Space and or Screen Motion to scale size of the particals.";
	ui_category = "Particle Interaction";
> = false;
#endif
uniform float MS <
    ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Particle Motion Sensitivity";
	ui_tooltip = "Use this to adjust for Motion in image.";
	ui_category = "Particle Interaction";
> = 0.1;

uniform float Luma_Clamp <
 ui_type = "slider";
 ui_min = -1.0; ui_max = 1.0;
 ui_label = "Luma Clamping";
 ui_tooltip = "Use this to set the color based brightness threshold for what is and what isn't allowed.\n"
        "Number 0.0 is default.";
 ui_category = "Particle Interaction";
> = 0.0;
#if !RS
uniform bool Ansel_HDR <
	ui_label = "Ansel-HDR Compatibility";
	ui_tooltip = "This will enable the HDR Buffer in Ansel-enabled games.";
	ui_category = "Particle Interaction";
> = false;
#else
#define Ansel_HDR 0
#endif
//uniform float Spread <
//ui_type = "slider";
//ui_min = 0.0; ui_max =  1.0;
//ui_label = "Fade Out Size";
//ui_tooltip = "Fade Out Size lets you adjust where the Particle falls off.\n"
//				 "Default is 0.1";
// ui_category = "Particle Interaction";
//> = 0.1;

//uniform float Balance <
//  ui_type = "slider";
//	ui_min = 0.0; ui_max = 1.0;
//	ui_label = "Effect and Screen Balance";
//	ui_tooltip = "Adjust the balance between effect and screen.\n"
//				 "Number 0.5 is default.";
//	ui_category = "Particle Interaction";
//> = 0.0;
//Total amount of frames since the game started.

#define Automatic_Resolution_Scaling 1 //[Off | On] This is used to enable or disable Automatic Resolution Scaling. Default is On.
#define RSRes 0.5  
#if Automatic_Resolution_Scaling //Automatic Adjustment based on Resolutionsup to 4k considered. LOL good luck with 8k in 2020
	#undef RSRes
	#if (BUFFER_HEIGHT <= 720)
		#define RSRes 1.0
	#elif (BUFFER_HEIGHT <= 1080)
		#define RSRes 0.8
	#elif (BUFFER_HEIGHT <= 1440)
		#define RSRes 0.7
	#elif (BUFFER_HEIGHT <= 2160)
		#define RSRes 0.6
	#else
		#define RSRes 0.5 //??? 8k Mystery meat
	#endif
#endif

/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define Spread 0.125
#define Balance 0.0
uniform float frametime < source = "frametime";>;
#if RS //Can't use this in NV Freestyle
uniform float2 mousedelta < source = "mousedelta"; >; //Gets the movement of the mouse cursor in screen coordinates.
uniform bool Di_W < source = "key"; keycode = 87;>;
uniform bool Di_A < source = "key"; keycode = 65;>;
uniform bool Di_S < source = "key"; keycode = 83;>;
uniform bool Di_D < source = "key"; keycode = 68;>;
uniform bool Di_SP < source = "key"; keycode = 32;>;
#endif
float fmod(float a, float b)
{
	float c = frac(abs(a / b)) * abs(b);
	return a < 0 ? -c : c;
}
//Done to make controls easier to use in NV Freestyle
float L_Amount() { return lerp(1,300,saturate(Amount));}
float S_Amount() { return lerp(1,50,saturate(Size));}
float MS_Amount() { return lerp(0,25,saturate(MS));}
float Sp_Amount() { return lerp(0,5,saturate(Speed));}
float FO_Amount() { return lerp(0,5,saturate(Spread));}

texture TexHDRPart : HDR;

sampler HDRPart
    {
        Texture = TexHDRPart;
    };

texture BackBufferTexPart : COLOR;

sampler BackBufferPart
	{
		Texture = BackBufferTexPart;
	};

texture PartTex  { Width = BUFFER_WIDTH * RSRes; Height = BUFFER_HEIGHT * RSRes; Format = R8;};

sampler Part
	{
		Texture = PartTex;
	};

texture PastSingleBackBufferPart { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};

sampler PSBackBufferPart
	{
		Texture = PastSingleBackBufferPart;
	};

//pooled textures that well don't really need to be pooled....
texture P_BloomTex < pooled = true; > { Width = BUFFER_WIDTH * 0.25; Height = BUFFER_HEIGHT * 0.25; Format = RG16F; MipLevels = 8;};

sampler P_BloomPart
	{
		Texture = P_BloomTex;
		MinFilter = POINT;
		MagFilter = POINT;
		MipFilter = POINT;
	};

texture PM_BloomTex < pooled = true; > { Width = BUFFER_WIDTH * 0.25; Height = BUFFER_HEIGHT * 0.25; Format = R16F; MipLevels = 8;};

sampler PM_BloomPart
	{
		Texture = PM_BloomTex;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

void A0(float2 texcoord,float PosX,float PosY,inout float D, inout float E, inout float P, inout float T, inout float H, inout float III, inout float DD )
{
	float PosXD = -0.035+PosX, offsetD = 0.001;D = all( abs(float2( texcoord.x -PosXD, texcoord.y-PosY)) < float2(0.0025,0.009));D -= all( abs(float2( texcoord.x -PosXD-offsetD, texcoord.y-PosY)) < float2(0.0025,0.007));
	float PosXE = -0.028+PosX, offsetE = 0.0005;E = all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.009));E -= all( abs(float2( texcoord.x -PosXE-offsetE, texcoord.y-PosY)) < float2(0.0025,0.007));E += all( abs(float2( texcoord.x -PosXE, texcoord.y-PosY)) < float2(0.003,0.001));
	float PosXP = -0.0215+PosX, PosYP = -0.0025+PosY, offsetP = 0.001, offsetP1 = 0.002;P = all( abs(float2( texcoord.x -PosXP, texcoord.y-PosYP)) < float2(0.0025,0.009*0.775));P -= all( abs(float2( texcoord.x -PosXP-offsetP, texcoord.y-PosYP)) < float2(0.0025,0.007*0.680));P += all( abs(float2( texcoord.x -PosXP+offsetP1, texcoord.y-PosY)) < float2(0.0005,0.009));
	float PosXT = -0.014+PosX, PosYT = -0.008+PosY;T = all( abs(float2( texcoord.x -PosXT, texcoord.y-PosYT)) < float2(0.003,0.001));T += all( abs(float2( texcoord.x -PosXT, texcoord.y-PosY)) < float2(0.000625,0.009));
	float PosXH = -0.0072+PosX;H = all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.001));H -= all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.002,0.009));H += all( abs(float2( texcoord.x -PosXH, texcoord.y-PosY)) < float2(0.00325,0.009));
	float offsetFive = 0.001, PosX3 = -0.001+PosX;III = all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.009));III -= all( abs(float2( texcoord.x -PosX3 - offsetFive, texcoord.y-PosY)) < float2(0.003,0.007));III += all( abs(float2( texcoord.x -PosX3, texcoord.y-PosY)) < float2(0.002,0.001));
	float PosXDD = 0.006+PosX, offsetDD = 0.001;DD = all( abs(float2( texcoord.x -PosXDD, texcoord.y-PosY)) < float2(0.0025,0.009));DD -= all( abs(float2( texcoord.x -PosXDD-offsetDD, texcoord.y-PosY)) < float2(0.0025,0.007));
}

/////////////////////////////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////////////////
texture texLumPart {Width = 256*0.5; Height = 256*0.5; Format = RGBA8; MipLevels = 8;}; //Sample at 256x256/2 and a mip bias of 8 should be 1x1

sampler SamplerLumC
	{
		Texture = texLumPart;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};

float LumM(float3 C)
{
	return dot(C.rgb, float3(0.299, 0.587, 0.114));
}

float Bloom(float2 texcoord, float M)
{
	float lodFactor = exp2(M);

	float bloom;
	float2 scale = lodFactor * pix * FO_Amount();

	float2 coord = texcoord.xy;
	float totalWeight;

	for (int i = -5; i < 5; i++)
	{
	    for (int j = -5; j < 5; j++)
		{
			float W = 1.0-length(float2(i,j) * pix) ;
	        bloom = tex2Dlod(P_BloomPart, float4(coord + float2(i,j) * scale + lodFactor * pix,0,M) ).r * W + bloom;
	        totalWeight += W;
	    }
	}

	bloom /= totalWeight;

	return bloom;
}

float PM_Bloom(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
  	float MixBloom = Bloom(texcoord, 2);
		return MixBloom ;
	}

float MaskBloom(float2 texcoord)
	{
		float Bloom = tex2Dlod(PM_BloomPart,float4(texcoord,0, 2)).r;
		return Bloom * 8;
	}

float4 LumC(in float2 texcoord)
	{
		float M_Sample = 8;
		if(Ambient_Colors == 2)
			M_Sample = 1;

		float4 Luminance = tex2Dlod(SamplerLumC,float4(texcoord,0,M_Sample)).rgba; //Average Luminance Texture Sample
		return float4(lerp(dot(Luminance.rgb, float3(0.2125, 0.7154, 0.0721)),Luminance.rgb,lerp(1,15,Intensity)),Luminance.w);
	}

float Fade()
{
	#if RS
	float Trigger_Fade = Di_W || Di_A || Di_S || Di_D || Di_SP || mousedelta.x || mousedelta.y;
	#else
	float Trigger_Fade = 0;
	#endif

	float AA = (1-MS)*1000, PStoredfade = tex2Dlod(P_BloomPart,float4(0.5,0.5,0,0)).y;
	return PStoredfade + (Trigger_Fade - PStoredfade) * (1.0 - exp(-frametime/AA)); ///exp2 would be even slower
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
uniform float timer < source = "timer"; >;
//Timer counting time in milliseconds since game start.
float random(float R)
{
  return frac(sin(dot(float2(R + 47.49, 38.2467 / (R + 1.0)), float2(12.9898, 78.233))) * 43758.5453);
}

float GS(float4 C)
{
	return dot(C.rgb, float3(0.299, 0.587, 0.114));
}

float2 GPattern(float2 TC)
{	float2 Grid = floor( TC * float2(BUFFER_WIDTH, BUFFER_HEIGHT ) * 1);
	return float2(fmod(Grid.x+Grid.y,2.0),fmod(Grid.x,2.0));
}

float4 Circle(float2 center, float radius, float2 TC)
{   float4 DC;
	//Rotation Calculation
	float2 Stored_TC = center, PivotPoint = float2(0.5,0.5);
	float Rot = radians(Degrees), sin_factor = sin(Rot), cos_factor = cos(Rot); // This is where you would add mouse mouse movement information.
	Stored_TC = mul(Stored_TC - PivotPoint, float2x2(float2(cos_factor, sin_factor), float2(-sin_factor, cos_factor)));
	Stored_TC += PivotPoint;
	//Particles Fade as motion is detected.
	float M = smoothstep(0,1,LumC(TC).w * MS_Amount());
	#if RS
		float MST = MS_Type;
	#else
		float MST = 0;
	#endif
	//Partical Size
	radius *= MST ? S_Amount() * lerp(1,0, Fade()) : S_Amount() * lerp(1.0,0.0,M); // Mouse delta information can be added here. But, Freestyle this is not allowed.
	//This is used to trick the Hooman that there is more randomness.
	DC.x = smoothstep(radius ,0.0, distance( TC - float2( 0.0,  0.0) , Stored_TC * float2(1.0,0.575 ) ));
	DC.y = smoothstep(radius ,0.0, distance( TC - float2( 0.0,  0.0) , Stored_TC * float2(0.333,0.575 * 1.75) ));
	DC.z = smoothstep(radius ,0.0, distance( TC - float2( 0.333,0.0) , Stored_TC * float2(0.333,0.575 * 1.50) ));
	DC.w = smoothstep(radius ,0.0, distance( TC - float2( 0.666,0.0) , Stored_TC * float2(0.333,0.575 * 1.75) ));
    return DC;
}

float Mask(float2 texcoord)
{
	float4 current_buffer = tex2D(BackBufferPart,texcoord);
	float4 past_single_buffer = tex2D(PSBackBufferPart, texcoord);//Past Single Buffer
	//Used for a mask calculation
	//Velosity Mask
	return length(GS(current_buffer) - GS(past_single_buffer));
}

float Part_Gen(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 mTexcoords = texcoord * float2(1,0.6);
	//Active Timer & Speed adjust
	float  LA = L_Amount(), T = -timer, MB = Luma_Clamp < 0 ? 1 - MaskBloom(texcoord): MaskBloom(texcoord),AT = T * Sp_Amount() * 0.0001, Fin, Switch = Luma_Clamp == 0.0 ? 0 : Luma_Clamp < 0 ? MB < 0 : MB < 0.03;
	float4 Color;
	[loop] //Little Part
	for(float i = 0; i < LA; i++)  //MB < 1 for Positive and MB < 0 for Negitive.
	{
		if(texcoord.x > 1 || texcoord.y > 1 || texcoord.x < 0 || texcoord.y < 0 || Switch)
			break;
		//Amount
		float A = random(cos(i)) * cos( i / LA );
		//Center Particles Generator
		float C = random(i) + Waviness * cos(AT + sin(i));
		float Gen = fmod( sin(i) - A * AT , 1.0);
		//Draw them Circles to create Particles from Center
		Color += Circle( float2(C,Gen), A * max(pix.x,pix.y), mTexcoords );
	}
	Fin = lerp(0,dot(Color,Color),MB);
	//Faster than length
	if( abs(Luma_Clamp) > 0 || Ansel_HDR )
		return Fin;
	else
		return dot(Color,Color);
}

float4 MixPart(float2 texcoord)
{
	float3 Color, Mix, Clamp_Mask;

	float Mask = 1-tex2D(Part,texcoord).x;

	Mix = lerp(1, tex2D(BackBufferPart, texcoord).rgb,Mask);

	Clamp_Mask = Mask;

	Color = TintColor;
	if(Ambient_Colors >= 1)
		Color = LumC(texcoord).rgb;

	Color *= lerp(0,5,Intensity);

	if(Adjust_PC < 0)
		Clamp_Mask = Clamp_Mask > min(0.999,abs(Adjust_PC));
	else if(Adjust_PC > 0)
		Clamp_Mask = smoothstep(0,Adjust_PC,Clamp_Mask);

	if(Particles == 0)
		Mix = lerp(Color, tex2D(BackBufferPart, texcoord).rgb,Clamp_Mask);
	else if(Particles == 1)
		Mix = Mask * lerp(Color, tex2D(BackBufferPart, texcoord).rgb,Clamp_Mask);
	else if(Particles == 2)
		Mix = 1-Mask * lerp(1-Color, 1-tex2D(BackBufferPart, texcoord).rgb,Clamp_Mask);
	else if(Particles == 3)
		Mix = Clamp_Mask * lerp(Color, tex2D(BackBufferPart, texcoord).rgb,Mask);
	else if(Particles == 4)
		Mix = 1-Clamp_Mask * lerp(1-Color, 1-tex2D(BackBufferPart, texcoord).rgb,Mask);

	return lerp(float4(Mix,1) ,tex2D(BackBufferPart, texcoord),Balance);
}

float4 Average_Luminance_Color(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return float4(tex2D(BackBufferPart,float2(texcoord.x,texcoord.y)).rgb,saturate(Mask(texcoord)) );
}

void Past_BackBuffer(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 Past: SV_Target)
{
	Past = float4(tex2D(BackBufferPart,texcoord).rgb,Fade());
}

void P_Bloom(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float2 BW: SV_Target)
{
	float LC = saturate(abs(Luma_Clamp));
	float4 BC = tex2Dlod(BackBufferPart, float4(texcoord,0,0)).rgba;
	if (Ansel_HDR)
		BC = tex2Dlod(HDRPart, float4(texcoord,0,0)).rgba;
	// Check whether fragment output is higher than threshold,if so output as brightness color.
	// Luma Threshold Thank you Adyss x2/Mine :D
	BC.a    = dot(BC.rgb,  float3(0.2126, 0.7152, 0.0722) );//Luma
	if (Ansel_HDR)
	{   //For Real HDR
		BC.a = BC.a > 1.0;
		BC.rgb *= BC.a;
	}
	else
	{
		if(Luma_Clamp < 0)
			LC = 1-LC;
			BC.rgb /= max(BC.a, 0.001);
			BC.a    = max(0.0, BC.a - LC);
			BC.rgb *= BC.a;
	}
	//Bloom Saturation
	BC.rgb  = saturate(BC.rgb + (BC.rgb - BC.a) * 2.5);
	//Out
	BW = float2(LumM(saturate(BC.rgb)),tex2D(PSBackBufferPart,0.5).w);
}

void A1(float2 texcoord,float PosX,float PosY,inout float I, inout float N, inout float F, inout float O)
{
		float PosXI = 0.0155+PosX, PosYI = 0.004+PosY, PosYII = 0.008+PosY;I = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosY)) < float2(0.003,0.001));I += all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYI)) < float2(0.000625,0.005));I += all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYII)) < float2(0.003,0.001));
		float PosXN = 0.0225+PosX, PosYN = 0.005+PosY,offsetN = -0.001;N = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN)) < float2(0.002,0.004));N -= all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN - offsetN)) < float2(0.003,0.005));
		float PosXF = 0.029+PosX, PosYF = 0.004+PosY, offsetF = 0.0005, offsetF1 = 0.001;F = all( abs(float2( texcoord.x -PosXF-offsetF, texcoord.y-PosYF-offsetF1)) < float2(0.002,0.004));F -= all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0025,0.005));F += all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0015,0.00075));
		float PosXO = 0.035+PosX, PosYO = 0.004+PosY;O = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.003,0.005));O -= all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.002,0.003));
}
////////////////////////////////////////////////////////Watermark/////////////////////////////////////////////////////////////////////////
float4 OutPart(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 Color = MixPart(texcoord).rgb;
	float PosX = 0.9525f*BUFFER_WIDTH*pix.x,PosY = 0.975f*BUFFER_HEIGHT*pix.y,A,B,C,D,E,F,G,H,I,J,K,L,PosXDot = 0.011+PosX, PosYDot = 0.008+PosY;L = all( abs(float2( texcoord.x -PosXDot, texcoord.y-PosYDot)) < float2(0.00075,0.0015));A0(texcoord,PosX,PosY,A,B,C,D,E,F,G );A1(texcoord,PosX,PosY,H,I,J,K);
	return timer <= 12500 ? A+B+C+D+E+F+G+H+I+J+K+L ? 0.02 : float4(Color,1.) : float4(Color,1.);
}
///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{// Vertex shader generating a triangle covering the entire screen
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
technique Particles_NV
{			pass PartOne
		{
			VertexShader = PostProcessVS;
			PixelShader = Part_Gen;
			RenderTarget = PartTex;
		}
			pass PartTwo
		{
			VertexShader = PostProcessVS;
			PixelShader = P_Bloom;
			RenderTarget = P_BloomTex;
		}
			pass PartThree
		{
			VertexShader = PostProcessVS;
			PixelShader = PM_Bloom;
			RenderTarget = PM_BloomTex;
		}
			pass PartAverageLuminanceandColor
		{
			VertexShader = PostProcessVS;
			PixelShader = Average_Luminance_Color;
			RenderTarget = texLumPart;
		}
			pass PartPBB
		{
			VertexShader = PostProcessVS;
			PixelShader = Past_BackBuffer;
			RenderTarget = PastSingleBackBufferPart;
		}
			pass Fin
		{
			VertexShader = PostProcessVS;
			PixelShader = OutPart;
		}

}
