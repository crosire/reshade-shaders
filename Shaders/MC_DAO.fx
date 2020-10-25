/*
 	Disk Ambient Occlusion by Constantine 'MadCake' Rudenko

 	License: https://creativecommons.org/licenses/by/4.0/
	CC BY 4.0
	
	You are free to:

	Share — copy and redistribute the material in any medium or format
		
	Adapt — remix, transform, and build upon the material
	for any purpose, even commercially.

	The licensor cannot revoke these freedoms as long as you follow the license terms.
		
	Under the following terms:

	Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. 
	You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

	No additional restrictions — You may not apply legal terms or technological measures 
	that legally restrict others from doing anything the license permits.
*/

#include "ReShadeUI.fxh"

uniform float Strength < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 8.0; ui_step = 0.1;
	ui_tooltip = "Strength of the effect (recommended 0.6)";
	ui_label = "Strength";
> = 0.5;

uniform int NumRays < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 16;
	ui_tooltip = "Number of rays (recommended 7)";
	ui_label = "Number of rays in a disk";
> = 7;

uniform int SampleDistance < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 64;
	ui_tooltip = "Sampling disk radius (in pixels)\nrecommended: 32";
	ui_label = "Sampling disk radius";
> = 32.0;

uniform int NumSamples < __UNIFORM_SLIDER_INT1
	ui_min = 1; ui_max = 32;
	ui_tooltip = "Number of samples per ray (recommended 3)";
	ui_label = "Samples per ray";
> = 3;

uniform float StartFade < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 16.0; ui_step = 0.1;
	ui_tooltip = "AO starts fading when Z difference is greater than this\nmust be bigger than \"Z difference end fade\"\nrecommended: 2.0";
	ui_label = "Z difference start fade";
> = 2.0;

uniform float EndFade < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 16.0; ui_step = 0.1;
	ui_tooltip = "AO completely fades when Z difference is greater than this\nmust be bigger than \"Z difference start fade\"\nrecommended: 6.0";
	ui_label = "Z difference end fade";
> = 6.0;

uniform float NormalBias < __UNIFORM_DRAG_FLOAT1
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.025;
	ui_tooltip = "prevents self occlusion (recommended 0.1)";
	ui_label = "Normal bias";
> = 0.1;

uniform int DebugEnabled <
        ui_type = "combo";
        ui_label = "Enable Debug View";
        ui_items = "Disabled\0Blurred\0Before Blur\0";
> = 0;

uniform int BlurRadius < __UNIFORM_SLIDER_INT1
	ui_min = 1.0; ui_max = 32.0;
	ui_tooltip = "Blur radius (in pixels)\nrecommended: 4 to 8";
	ui_label = "Blur radius";
> = 8.0;

uniform float BlurQuality < __UNIFORM_DRAG_FLOAT1
		ui_min = 0.5; ui_max = 1.0; ui_step = 0.1;
		ui_label = "Blur Quality";
		ui_tooltip = "Blur quality (recommended 0.6)";
> = 0.6;

uniform int Mode <
        ui_type = "combo";
		ui_label = "Flicker fix";
        ui_tooltip = "Cloose which one you like better\nMode A might have some flickering\nRecommended mode B";
        ui_items = "Mode A\0Mode B\0";
> = 1;

uniform float Gamma < __UNIFORM_DRAG_FLOAT1
		ui_min = 1.0; ui_max = 4.0; ui_step = 0.1;
		ui_label = "Gamma";
        ui_tooltip = "Recommended 2.2\n(assuming the texture is stored with gamma applied)";
> = 2.2;

uniform float NormalPower < __UNIFORM_DRAG_FLOAT1
		ui_min = 0.5; ui_max = 8.0; ui_step = 0.1;
		ui_label = "Normal power";
        ui_tooltip = "Acts like softer version of normal bias without a threshold\nrecommended: 2";
> = 2.0;

uniform int FOV < __UNIFORM_DRAG_FLOAT1
		ui_min = 40; ui_max = 180; ui_step = 1.0;
		ui_label = "FOV";
        ui_tooltip = "Leaving it at 90 regardless of your actual FOV provides accetable results";
> = 90;

uniform float DepthShrink < __UNIFORM_DRAG_FLOAT1
		ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
		ui_label = "Depth shrink";
        ui_tooltip = "Higher values cause AO to become finer on distant objects\nrecommended: 0.3";
> = 0.3;

uniform int DepthAffectsRadius <
		ui_type = "combo";
		ui_label = "Depth affects radius";
        ui_tooltip = "Far away objects have finer AO\nrecommended: yes";
		ui_items = "No\0Yes\0";
> = 1;

#include "ReShade.fxh"

texture2D AOTex	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F; MipLevels = 1;};
texture2D AOTex2	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F; MipLevels = 1;};

sampler2D sAOTex { Texture = AOTex; };
sampler2D sAOTex2 { Texture = AOTex2; };

float GetTrueDepth(float2 coords)
{
	return ReShade::GetLinearizedDepth(coords) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

float3 GetPosition(float2 coords)
{
	float2 fov;
	fov.x = FOV / 180.0 * 3.1415;
	fov.y = fov.x / BUFFER_ASPECT_RATIO; 
	float3 pos;
	pos.z = GetTrueDepth(coords.xy);
	coords.y = 1.0 - coords.y;
	pos.xy = coords.xy * 2.0 - 1.0;
	float2 h;
	h.x	= 1.0 / tan(fov.x * 0.5);
	h.y = 1.0 / tan(fov.y * 0.5);
	pos.xy /= h / pos.z;
	return pos;
}

float3 GetNormalFromDepth(float2 coords) 
{
	float3 centerPos = GetPosition(coords);
	
	float2 offx = float2(BUFFER_PIXEL_SIZE.x, 0);
	float2 offy = float2(0, BUFFER_PIXEL_SIZE.y);
	
	float3 ddx1 = GetPosition(coords + offx) - centerPos;
	float3 ddx2 = centerPos - GetPosition(coords - offx);

	float3 ddy1 = GetPosition(coords + offy) - centerPos;
	float3 ddy2 = centerPos - GetPosition(coords - offy);

	//ddx1 = lerp(ddx1, ddx2, abs(ddx1.z) > abs(ddx2.z));
	//ddy1 = lerp(ddy1, ddy2, abs(ddy1.z) > abs(ddy2.z));
	
	ddx1 = ddx1 + ddx2;
	ddy1 = ddy1 + ddy2;

	float3 normal = cross(ddx1, ddy1);
	
	return normalize(normal);
}

float rand2D(float2 uv){
	uv = frac(uv);
	float x = frac(cos(uv.x*64)*256);
	float y = frac(cos(uv.y*137)*241);
	float z = x+y;
	return frac(cos((z)*107)*269);
}

float3 BlurAOHorizontalPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float range = clamp(BlurRadius, 1, 32);

	float tmp = 1.0 / (range * range);
	float gauss = 1.0;
	float helper = exp(tmp * 0.5);
	float helper2 = exp(tmp);
	float sum = tex2D(sAOTex, texcoord).r;
	float sumCoef = 1.0;
	
	float blurQuality = clamp(BlurQuality, 0.0, 1.0);
	range *= 3.0 * blurQuality;

	float2 off = float2(BUFFER_PIXEL_SIZE.x, 0);
	
	[loop]
	for(int k = 1; k < range; k++){
		gauss = gauss / helper;
		helper = helper * helper2;
		sumCoef += gauss * 2.0;
		sum += tex2D(sAOTex, texcoord + off * k).r * gauss;
		sum += tex2D(sAOTex, texcoord - off * k).r * gauss;
	}
	
	return sum / sumCoef;
}


float3 BlurAOVerticalPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float range = clamp(BlurRadius, 1, 32);

	float tmp = 1.0 / (range * range);
	float gauss = 1.0;
	float helper = exp(tmp * 0.5);
	float helper2 = exp(tmp);
	float sum = tex2D(sAOTex2, texcoord).r;
	float sumCoef = 1.0;
	
	float blurQuality = clamp(BlurQuality, 0.0, 1.0);
	range *= 3.0 * blurQuality;

	float2 off = float2(0, BUFFER_PIXEL_SIZE.y);
	
	[loop]
	for(int k = 1; k < range; k++){
		gauss = gauss / helper;
		helper = helper * helper2;
		sumCoef += gauss * 2.0;
		sum += tex2D(sAOTex2, texcoord + off * k).r * gauss;
		sum += tex2D(sAOTex2, texcoord - off * k).r * gauss;
	}
	
	sum = sum / sumCoef;
	
	if (DebugEnabled == 2)
	{
		return tex2D(sAOTex, texcoord).r;
	}
	
	if (DebugEnabled == 1)
	{
		return sum;
	}
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	color = pow(color, 1.0 / Gamma) * sum;
	color = pow(color, Gamma);
	return  color;
}

//PS_InputBufferSetup
//normals calculated from depth

float3 MadCakeDiskAOPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 position = GetPosition(texcoord);
	float3 normal = GetNormalFromDepth(texcoord);
	
	int num_rays = clamp(NumRays, 1, 16);
	int num_samples = clamp(NumSamples, 1, 64);
	int sample_dist = clamp(SampleDistance, 1, 128);
	float start_fade = clamp(StartFade, 0.0, 16.0);
	float end_fade = clamp(EndFade, 0.0, 16.0);
	float normal_bias = clamp(NormalBias, 0.0, 1.0);
	
	float occlusion = 0;
	float fade_range = end_fade - start_fade;
	
	float angle_jitter = rand2D(texcoord);
	float radius_jitter = rand2D(texcoord + float2(1,1));
	
	float shrink = 1.0 + log(position.z * pow(DepthShrink,2.2) + 1.0);

	[loop]
	for (int i = 0; i < num_rays; i++)
	{
		float angle = 3.1415 * 2.0 / num_rays * (i + angle_jitter);
		float2 ray;
		ray.x = sin(angle);
		ray.y = cos(angle);
		ray *= BUFFER_PIXEL_SIZE * sample_dist;
		int depthAffectsRadius = clamp(DepthAffectsRadius, 0, 1);
		if (depthAffectsRadius)
		{
			ray = ray / shrink;
		}
		float ray_occlusion = 0.0;
		[loop]
		for (int k = 0; k < num_samples; k++)
		{
			float radius_coef = (float(k) + radius_jitter + 1.0) / num_samples;
			float2 sample_coord = texcoord + ray * radius_coef;
			float3 sampled_position = GetPosition(sample_coord);
			float3 v = sampled_position - position;
			float cur_occlusion = dot(normal, normalize(v));
			cur_occlusion = max(0.0, cur_occlusion);
			cur_occlusion = pow (cur_occlusion, NormalPower);
			cur_occlusion = (cur_occlusion - normal_bias) / (1.0 - normal_bias);
			float zdiff = abs(v.z);
			if (zdiff >= start_fade)
			{
				cur_occlusion *= saturate(1.0 - (zdiff - start_fade) / fade_range);
			}
			if (Mode)
			{
				ray_occlusion += max(0.0,cur_occlusion) / num_samples;
			}
			else
			{
				ray_occlusion = max(ray_occlusion, cur_occlusion);
			}
			
		}
		occlusion += ray_occlusion / num_rays;
	}
	occlusion = max(0.0, 1.0 - occlusion * Strength);
	return occlusion;
}

technique MC_DAO
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MadCakeDiskAOPass;
		RenderTarget0 = AOTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurAOHorizontalPass;
		RenderTarget0 = AOTex2;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurAOVerticalPass;
	}
}
