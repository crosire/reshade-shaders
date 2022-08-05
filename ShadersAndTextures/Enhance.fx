////------------------------------//
///**Image Contrast Enhancement**///
//------------------------------////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//* Local Contrast Based on Depth Cues
//* For Reshade 3.0+
//*  ---------------------------------
//*                                                       Image Contrast Enhancement
//* Due Diligence
//* Depth Cues
//* https://github.com/BlueSkyDefender/AstrayFX/blob/master/Shaders/Depth_Cues.fx
//* https://www.uni-konstanz.de/mmsp/pubsys/publishedFiles/LuCoDe06.pdf
//*
//* If I miss any please tell me.
//*
//* LICENSE
//* ============
//* Image Contrast Enhancement is licenses under: Attribution-NoDerivatives 4.0 International
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

uniform float Contrast_Type <
 ui_type = "slider";
 ui_min = 0.0; ui_max = 1.0;
 ui_label = "Shading Type";
 ui_tooltip = "Adjust the Shading Type game.\n"
              "Number 1.0 is default.";
 ui_category = "Local Contrast";
> = 1.0;

uniform float Shade_Power <
 ui_type = "slider";
 ui_min = 0.0; ui_max = 1.0;
 ui_label = "Intensity";
 ui_tooltip = "Adjust the Shading to improve AO, Shadows, & Darker Areas and or the opposite in game.\n"
              "This gives the illusion of Pop.\n"
              "Number 0.5 is default.";
 ui_category = "Local Contrast";
> = 0.5;

uniform float Spread <
 ui_type = "slider";
 ui_min = 1.0; ui_max = 25.0; ui_step = 0.25;
 ui_label = "Spread";
 ui_tooltip = "Adjust this to have the shade effect fill in areas & gives a fakeAO effect.\n"
        "This is used for gap filling.\n"
        "Number 7.5 is default.";
 ui_category = "Local Contrast";
> = 12.5;

uniform bool V_Output <
   ui_label = "Debug View";
   ui_tooltip = "Shows Local Contrast in a 50% Grey Debug View";
 ui_category = "Local Contrast";
> = 0;

/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)
#define BlurSamples 12 //BlurSamples = # * 2
uniform float timer < source = "timer"; >;

float lum(float3 RGB){ return dot(RGB, float3(0.2126, 0.7152, 0.0722) );}
float GS(float3 color){return clamp(dot(color.rgb, float3(0.2126, 0.7152, 0.0722)),0.003,1.0);}//clamping to protect from over Dark.
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

texture texBackBuffer : COLOR;

sampler BackBufferCE
   {
       Texture = texBackBuffer;
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

texture texPHB { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };

sampler SamplerPHBCE
 {
     Texture = texPHB;
 };

texture texPopCE { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; MipLevels = 2; };

sampler SamplerPopCE
 {
   Texture = texPopCE;
 };


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void BB(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float HPop : SV_Target)
{
   //Pop Hor Blur
   float S = Spread * 0.125, sum = lum(tex2D(BackBufferCE,texcoord).rgb) * BlurSamples;
   float total = BlurSamples;
   [unroll]
   for ( int j = -BlurSamples; j <= BlurSamples; ++j)
   {
       float W = BlurSamples;
       sum += lum(tex2D(BackBufferCE,texcoord + float2(pix.x * S,0) * j).rgb) * W;
       total += W;
   }
   HPop = saturate(sum / total); // Get it Total sum..... :D
}

// Spread the blur a bit more.
void Pop(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float pop : SV_Target)
{   float3 Color = tex2D(BackBufferCE,texcoord).rgb;
	float2 Scale, S = Spread * 0.75f * pix;
	int Mip = 1;
	float result = tex2Dlod(SamplerPHBCE,float4(texcoord, 0, Mip)).x;
	Scale = S * 0.75;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 1, 1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2(-1,-1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2(-1, 1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 1,-1) * Scale, 0, Mip)).x;
	Scale = S * 0.5;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 1, 1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2(-1,-1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2(-1, 1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 1,-1) * Scale, 0, Mip)).x;
	Scale = S * 0.5;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 1, 0) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 0, 1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2(-1, 0) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 0,-1) * Scale, 0, Mip)).x;
	Scale = S * 0.25;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 1, 1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2(-1,-1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2(-1, 1) * Scale, 0, Mip)).x;
	result += tex2Dlod(SamplerPHBCE,float4(texcoord + float2( 1,-1) * Scale, 0, Mip)).x;
	result *= rcp(17);
	// Formula for Image Pop = Original + (Original / Blurred).
	float DC = GS(Color) / result;

	pop = lerp(max(1,DC),min(1,DC),saturate(Contrast_Type));
}

float3 ShaderICE(float2 texcoord : TEXCOORD0)
{   //No fractional values on LOD.... would have liked 0.5 here. But, whatcan you do.
	float LOD = 1, DC = tex2Dlod(SamplerPopCE,float4(texcoord,0,LOD)).x;
	float3 Color = tex2D(BackBufferCE,texcoord).rgb;
	//Local Contrast Shade
	Color = lerp(Color,Color * DC,saturate(Shade_Power));

	if (V_Output == 1)
		Color = lerp(1.0f,DC,saturate(Shade_Power)) - 0.5;

	return Color;
}

void A1(float2 texcoord,float PosX,float PosY,inout float I, inout float N, inout float F, inout float O)
{
	float PosXI = 0.0155+PosX, PosYI = 0.004+PosY, PosYII = 0.008+PosY;I = all( abs(float2( texcoord.x - PosXI, texcoord.y - PosY)) < float2(0.003,0.001));I += all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYI)) < float2(0.000625,0.005));I += all( abs(float2( texcoord.x - PosXI, texcoord.y - PosYII)) < float2(0.003,0.001));
	float PosXN = 0.0225+PosX, PosYN = 0.005+PosY,offsetN = -0.001;N = all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN)) < float2(0.002,0.004));N -= all( abs(float2( texcoord.x - PosXN, texcoord.y - PosYN - offsetN)) < float2(0.003,0.005));
	float PosXF = 0.029+PosX, PosYF = 0.004+PosY, offsetF = 0.0005, offsetF1 = 0.001;F = all( abs(float2( texcoord.x -PosXF-offsetF, texcoord.y-PosYF-offsetF1)) < float2(0.002,0.004));F -= all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0025,0.005));F += all( abs(float2( texcoord.x -PosXF, texcoord.y-PosYF)) < float2(0.0015,0.00075));
	float PosXO = 0.035+PosX, PosYO = 0.004+PosY;O = all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.003,0.005));O -= all( abs(float2( texcoord.x -PosXO, texcoord.y-PosYO)) < float2(0.002,0.003));
}

////////////////////////////////////////////////////////Logo/////////////////////////////////////////////////////////////////////////
float4 OutCE(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float3 Color = ShaderICE(texcoord).rgb;
	float PosX = 0.9525f*BUFFER_WIDTH*pix.x,PosY = 0.975f*BUFFER_HEIGHT*pix.y,A,B,C,D,E,F,G,H,I,J,K,L,PosXDot = 0.011+PosX, PosYDot = 0.008+PosY;L = all( abs(float2( texcoord.x -PosXDot, texcoord.y-PosYDot)) < float2(0.00075,0.0015));A0(texcoord,PosX,PosY,A,B,C,D,E,F,G );A1(texcoord,PosX,PosY,H,I,J,K);
	return timer <= 12500 ? A+B+C+D+E+F+G+H+I+J+K+L ? 0.02 : float4(Color,1.) : float4(Color,1.);
}
///////////////////////////////////////////////////////////////////ReShade.fxh//////////////////////////////////////////////////////////////////////
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{// Vertex shader generating a triangle covering the entire screen
 texcoord.x = (id == 2) ? 2.0 : 0.0;
 texcoord.y = (id == 1) ? 2.0 : 0.0;
 position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}//Using this to make it portable
//*Rendering passes*//
technique Enhance
{
   pass Mip_BackBuffer
 {
   VertexShader = PostProcessVS;
   PixelShader = BB;
   RenderTarget = texPHB;
 }
   pass Pop
 {
   VertexShader = PostProcessVS;
   PixelShader = Pop;
   RenderTarget = texPopCE;
 }
   pass UnsharpMask
 {
   VertexShader = PostProcessVS;
   PixelShader = OutCE;
 }
}
