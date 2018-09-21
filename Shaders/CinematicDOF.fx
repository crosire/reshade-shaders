////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Cinematic Depth of Field shader, using scatter-as-gather for ReShade 3.x. 
// By Frans Bouma, aka Otis / Infuse Project (Otis_Inf)
// https://fransbouma.com 
//
// This shader has been released under the following license:
//
// Copyright (c) 2018 Frans Bouma
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// 
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Version history:
// 21-sep-2018:		v1.0.7: Better near-plane bleed. Optimized near plane CoC storage so less reads are needed.
// 04-sep-2018:		v1.0.6: Small fix for DX9 and autofocus.
// 17-aug-2018:		v1.0.5: Much better highlighting, higher range for manual focus
// 12-aug-2018:		v1.0.4: Finetuned the workaround for d3d9 to only affect reshade 3.4 or lower. 
//							Finetuned the near highlight extrapolation a bit. Removed highlight threshold as it ruined the blur
// 10-aug-2018:		v1.0.3: Daodan's crosshair code added.
// 09-aug-2018:		v1.0.2: Added workaround for d3d9 glitch in reshade 3.4.
// 08-aug-2018:		v1.0.1: namespace addition for samplers/textures.
// 08-aug-2018:		v1.0.0: beta. Feature complete. 
//
////////////////////////////////////////////////////////////////////////////////////////////////////
// Additional credits:
// Gaussian blur code based on the Gaussian blur ReShade shader by Ioxa
// Thanks to Daodan for the crosshair code in the focus helper.
////////////////////////////////////////////////////////////////////////////////////////////////////
// References:
//
// [Lee2008]		Sungkil Lee, Gerard Jounghyun Kim, and Seungmoon Choi: Real-Time Depth-of-Field Rendering Using Point Splatting 
//					on Per-Pixel Layers. 
//					https://pdfs.semanticscholar.org/80f6/f40fe971eddc810c3c86fca6fdfe5c0fdd76.pdf
// 
// [Jimenez2014]	Jorge Jimenez, Sledgehammer Games: Next generation post processing in Call of Duty Advanced Warfare, SIGGRAPH2014
//					http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
//
// [Nilsson2012]	Filip Nilsson: Implementing realistic depth of field in OpenGL. 
//					http://fileadmin.cs.lth.se/cs/education/edan35/lectures/12dof.pdf
////////////////////////////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"

namespace CinematicDOF
{
	//////////////////////////////////////////////////
	//
	// User interface controls
	//
	//////////////////////////////////////////////////

	// ------------- FOCUSING
	uniform bool UseAutoFocus <
		ui_category = "Focusing";
		ui_label = "Use auto-focus";
		ui_tooltip = "If enabled it will make the shader focus on the point specified as 'Auto-focus point',\notherwise it will put the focus plane at the depth specified in 'Manual-focus plane'.";
	> = true;
	uniform bool UseMouseDrivenAutoFocus <
		ui_category = "Focusing";
		ui_label = "Use mouse-driven auto-focus";
		ui_tooltip = "Enables mouse driven auto-focus. If enabled, and 'Use auto-focus' is enabled, the\nauto-focus point is read from the mouse coordinates, otherwise the 'Auto-focus point' is used.";
	> = true;
	uniform float2 AutoFocusPoint <
		ui_category = "Focusing";
		ui_label = "Auto-focus point";
		ui_type = "drag";
		ui_step = 0.001;
		ui_min = 0.000; ui_max = 1.000;
		ui_tooltip = "The X and Y coordinates of the auto-focus point. 0,0 is the upper left corner,\nand 0.5, 0.5 is at the center of the screen. Only used if 'Use auto focus' is enabled.";
	> = float2(0.5, 0.5);
	uniform float ManualFocusPlane <
		ui_category = "Focusing";
		ui_label= "Manual-focus plane";
		ui_type = "drag";
		ui_min = 0.100; ui_max = 150.00;
		ui_step = 0.01;
		ui_tooltip = "The depth of focal plane related to the camera when 'Use auto-focus' is off.\nOnly used if 'Use auto-focus' is disabled.";
	> = 10.00;
	uniform float FocalLength <
		ui_category = "Focusing";
		ui_label = "Focal length (mm)";
		ui_type = "drag";
		ui_min = 10; ui_max = 300.0;
		ui_step = 1.0;
		ui_tooltip = "Focal length of the used lens. The longer the focal length, the narrower the\ndepth of field and thus the more\nis out of focus";
	> = 50.00;
	uniform float FNumber <
		ui_category = "Focusing";
		ui_label = "Aperture (f-number)";
		ui_type = "drag";
		ui_min = 1; ui_max = 22.0;
		ui_step = 0.1;
		ui_tooltip = "The f-number (also known as f-stop) to use. The higher the number, the wider\nthe depth of field, meaning the more is in-focus and thus the less is out of focus";
	> = 5.6;
	// ------------- FOCUSING, OVERLAY
	uniform bool ShowOutOfFocusPlaneOnMouseDown <
		ui_category = "Focusing, overlay";
		ui_label = "Show out-of-focus plane overlay on mouse down";
		ui_tooltip = "Enables the out-of-focus plane overlay when the left mouse button is pressed down,\nwhich helps with fine-tuning the focusing.";
	> = true;
	uniform float3 OutOfFocusPlaneColor <
		ui_category = "Focusing, overlay";
		ui_label = "Out-of-focus plane overlay color";
		ui_type= "color";
		ui_tooltip = "Specifies the color of the out-of-focus planes rendered when the left-mouse button\nis pressed and 'Show out-of-focus plane on mouse down' is enabled. In (red , green, blue)";
	> = float3(0.8,0.8,0.8);
	uniform float OutOfFocusPlaneColorTransparency <
		ui_category = "Focusing, overlay";
		ui_label = "Out-of-focus plane transparency";
		ui_type = "drag";
		ui_min = 0.01; ui_max = 1.0;
		ui_tooltip = "Amount of transparency of the out-of-focus planes. 0.0 is transparent, 1.0 is opaque.";
	> = 0.7;
	uniform float3 FocusPlaneColor <
		ui_category = "Focusing, overlay";
		ui_label = "Focus plane overlay color";
		ui_type= "color";
		ui_tooltip = "Specifies the color of the focus plane rendered when the left-mouse button\nis pressed and 'Show out-of-focus plane on mouse down' is enabled. In (red , green, blue)";
	> = float3(0.0, 0.0, 1.0);
	uniform float4 FocusCrosshairColor<
		ui_category = "Focusing, overlay";
		ui_label = "Focus crosshair color";
		ui_type = "color";
		ui_tooltip = "Specifies the color of the crosshair for the auto-focus.\nAuto-focus must be enabled";
	> = float4(1.0, 0.0, 1.0, 1.0);
	
	// ------------- BLUR TWEAKING
	uniform float FarPlaneMaxBlur <
		ui_category = "Blur tweaking";
		ui_label = "Far plane max blur";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 20.0;
		ui_step = 0.01;
		ui_tooltip = "The maximum blur a pixel can have. Use this as a tweak to adjust the max far\nplane blur defined by the lens parameters.";
	> = 2.0;
	uniform float NearPlaneMaxBlur <
		ui_category = "Blur tweaking";
		ui_label = "Near plane max blur";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 20.0;
		ui_step = 0.01;
		ui_tooltip = "The maximum blur a pixel can have. Use this as a tweak to adjust the max near\nplane blur defined by the lens parameters.";
	> = 1.0;
	uniform float BlurQuality <
		ui_category = "Blur tweaking";
		ui_label = "Overall blur quality";
		ui_type = "drag";
		ui_min = 2; ui_max = 12;
		ui_tooltip = "The number of rings to use in the disc-blur algorithm. The more rings the better\nthe blur results, but also the slower it will get.";
		ui_step = 1.0;
	> = 5.0;
	uniform float PostBlurSmoothing <
		ui_category = "Blur tweaking";
		ui_label = "Post-blur smoothing factor";
		ui_type = "drag";
		ui_min = 0.0; ui_max = 2.0;
		ui_tooltip = "The amount of post-blur smoothing blur to apply. 0.0 means no smoothing blur is applied.";
		ui_step = 0.01;
	> = 0.0;
	// ------------- HIGHLIGHT TWEAKING
	uniform float HighlightEdgeBias <
		ui_category = "Highlight tweaking";
		ui_label="Highlight edge bias";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 2.00;
		ui_tooltip = "The bias for the highlight: 0 means equally spread, 2 means everything is at the\nedge of the bokeh circle.";
		ui_step = 0.01;
	> = 0.0;
	uniform float HighlightGainFarPlane <
		ui_category = "Highlight tweaking, far plane";
		ui_label = "Highlight gain";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1000.00;
		ui_tooltip = "The gain for highlights in the far plane. The higher the more a highlight gets\nbrighter. Tweak this in tandem with the Highlight threshold. Best results are\nachieved with bright spots in dark(er) backgrounds. Start with a high threshold to limit\nthe number of bright spots and then crank up this gain slowly to accentuate them.";
		ui_step = 1;
	> = 0.0;
	uniform float HighlightThresholdFarPlane <
		ui_category = "Highlight tweaking, far plane";
		ui_label="Highlight threshold";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1.00;
		ui_tooltip = "The threshold for the source pixels. Pixels with a luminosity above this threshold\nwill be highlighted. Raise this value to only keep the highlights you want.";
		ui_step = 0.01;
	> = 0.0;
	uniform float HighlightGainNearPlane <
		ui_category = "Highlight tweaking, near plane";
		ui_label = "Highlight gain";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1000.00;
		ui_tooltip = "The gain for highlights in the near plane. The higher the more a highlight gets\nbrighter. Tweak this in tandem with the Highlight threshold. Best results are\nachieved with bright spots in dark(er) foregrounds. Start with a high threshold to limit\nthe number of bright spots and then crank up this gain slowly to accentuate them.";
		ui_step = 1;
	> = 0.0;
	uniform float HighlightThresholdNearPlane <
		ui_category = "Highlight tweaking, near plane";
		ui_label="Highlight threshold";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1.00;
		ui_tooltip = "The threshold for the source pixels. Pixels with a luminosity above this threshold\nwill be highlighted. Raise this value to only keep the highlights you want.";
		ui_step = 0.01;
	> = 0.0;
	// ------------- DEBUG
	uniform bool ShowDebugInfo <
		ui_category = "Debugging";
		ui_tooltip = "Shows blur disc size as grey, depth of field as red and focus plane as blue";
	> = false;
	uniform bool ShowNearCoCBlur <
		ui_category = "Debugging";
		ui_tooltip = "Shows the near coc blur buffer as b&w";
	> = false;
	uniform bool ShowOriginal <
		ui_category = "Debugging";
	> = false;

	//////////////////////////////////////////////////
	//
	// Defines, constants, samplers, textures, uniforms, structs
	//
	//////////////////////////////////////////////////

	#define SENSOR_SIZE			0.024		// Height of the 35mm full-frame format (36mm x 24mm)
	#define PI 					3.1415926535897932

	texture texCDFocus			{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
	texture texCDFocusTmp1		{ Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = R16F; };	// half res, single value
	texture texCDFocusBlurred	{ Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = RG16F; };	// half res, blurred CoC (r) and real CoC (g)
	texture texCDBuffer1 		{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
	texture texCDBuffer2 		{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; }; 
	texture texCDBuffer3 		{ Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; }; 

	sampler SamplerCDBuffer1 		{ Texture = texCDBuffer1; };
	sampler SamplerCDBuffer2 		{ Texture = texCDBuffer2; };
	sampler SamplerCDBuffer3 		{ Texture = texCDBuffer3; };
	sampler SamplerCDFocus			{ Texture = texCDFocus; };
	sampler SamplerCDFocusTmp1		{ Texture = texCDFocusTmp1; };
	sampler SamplerCDFocusBlurred	{ Texture = texCDFocusBlurred; };

	uniform float2 MouseCoords < source = "mousepoint"; >;
	uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = false; >;

	// simple struct for the Focus vertex shader.
	struct VSFOCUSINFO
	{
		float4 vpos : SV_Position;
		float2 texcoord : TEXCOORD0;
		float focusDepth : TEXCOORD1;
		float focusDepthInM : TEXCOORD2;
		float focusDepthInMM : TEXCOORD3;
		float pixelSizeLength : TEXCOORD4;
		float nearPlaneInMM : TEXCOORD5;
		float farPlaneInMM : TEXCOORD6;
	};

	struct VSDISCBLURINFO
	{
		float4 vpos : SV_Position;
		float2 texcoord : TEXCOORD0;
		float numberOfRings : TEXCOORD1;
		float farPlaneMaxBlurInPixels : TEXCOORD2;
		float nearPlaneMaxBlurInPixels : TEXCOORD3;
	};

	//////////////////////////////////////////////////
	//
	// Functions
	//
	//////////////////////////////////////////////////

	// Calculates an RGBA fragment based on the CoC radius specified, for debugging purposes.
	// In: 	radius, the CoC radius to calculate the fragment for
	//		showInFocus, flag which will give a blue edge at the focus plane if true
	// Out:	RGBA fragment for color buffer based on the radius specified. 
	float4 GetDebugFragment(float radius, bool showInFocus)
	{
		return (radius/2 <= length(ReShade::PixelSize)) && showInFocus ? float4(0.0, 0.0, 1.0, 1.0) : float4(radius, radius, radius, 1.0);
	}

	// Calculates the blur disc size for the pixel at the texcoord specified. A blur disc is the CoC size at the image plane.
	// In:	VSFOCUSINFO struct filled by the vertex shader VS_Focus
	// Out:	The blur disc size for the pixel at texcoord. Format: near plane: < 0. In-focus: 0. Far plane: > 0. Range: [-1, 1].
	float CalculateBlurDiscSize(VSFOCUSINFO focusInfo)
	{
		float pixelDepth = ReShade::GetLinearizedDepth(focusInfo.texcoord);
		float pixelDepthInM = pixelDepth * 1000.0;			// in meter

		// CoC (blur disc size) calculation based on [Lee2008]
		// CoC = ((EF / Zf - F) * (abs(Z-Zf) / Z)
		// where E is aperture size in mm, F is focal length in mm, Zf is depth of focal plane in mm, Z is depth of pixel in mm.
		// To calculate aperture in mm, we use D = F/N, where F is focal length and N is f-number
		// For the people getting confused: 
		// Remember element sizes are in mm, our depth sizes are in meter, so we have to divide S1 by 1000 to get from meter -> mm. We don't have to
		// divide the elements in the 'abs(x-S1)/x' part, as the 1000.0 will then simply be muted out (as  a / (x/1000) == a * (1000/x))
		// formula: (((f*f) / N) / ((S1/1000.0) -f)) * (abs(x - S1) / x)
		// where f = FocalLength, N = FNumber, S1 = focusInfo.focusDepthInM, x = pixelDepthInM. In-lined to save on registers. 
		float cocInMM = (((FocalLength*FocalLength) / FNumber) / ((focusInfo.focusDepthInM/1000.0) -FocalLength)) * 
						(abs(pixelDepthInM - focusInfo.focusDepthInM) / pixelDepthInM);
		float toReturn = saturate(abs(cocInMM) * SENSOR_SIZE); // divide by sensor size to get coc in % of screen (or better: in sampler units)
		return (pixelDepth < focusInfo.focusDepth) ? 0 - toReturn : toReturn;
	}


	// Same as PerformDiscBlur but this time for the near plane. It's in a separate function to avoid a lot of if/switch statements as
	// the near plane blur requires different semantics. For comments on the code, see PerformDiscBlur.
	// Based on [Hammon2007] and [Nilsson2012]: D1 = 2 * max(D0, Db) - D0, where D1 is the blur disc radius to use, D0 is the original blur disc 
	// radius and Db is the blurred variant. 
	// In:	blurInfo, the pre-calculated disc blur information from the vertex shader.
	// 		source, the source to read RGBA fragments from
	// Out: RGBA fragment for the pixel at texcoord in source, which is the blurred variant of it if it's in the near plane.
	float4 PerformNearPlaneDiscBlur(VSDISCBLURINFO blurInfo, sampler2D source)
	{
		float numberOfRings = blurInfo.numberOfRings + 1;		// use one extra ring as undersampling is really prominent in near-camera objects.
		float pointsFirstRing = 7; 	// each ring has a multiple of this value of sample points. Use a couple more than far plane to battle undersampling here.
		float4 fragment = tex2Dlod(source, float4(blurInfo.texcoord, 0, 0));
		float4 fragmentCoords = float4(blurInfo.texcoord, 0, 0);
		// x contains blurred CoC, y contains original CoC
		float2 fragmentRadii = tex2Dlod(SamplerCDFocusBlurred, fragmentCoords).xy;

		if(fragmentRadii.x <=0)
		{
			// the blurred CoC value is still 0, we'll never end up with a pixel that has a different value than fragment, so abort now by
			// returning the fragment we already read.
			return fragment;
		}
		
		float radiusInPixels = lerp(0.0, blurInfo.nearPlaneMaxBlurInPixels, fragmentRadii.x);
		float threshold = max((dot(fragment.xyz, float3(0.3, 0.59, 0.11)) - HighlightThresholdNearPlane) * HighlightGainNearPlane, 0);
		float4 average = float4((fragment.xyz + lerp(0, fragment.xyz, threshold * fragmentRadii.x * 0.1)) * saturate(1-HighlightEdgeBias), saturate(1.0-HighlightEdgeBias));
		float2 pointOffset = float2(0,0);
		float ringRadiusDeltaInPixels = radiusInPixels / (numberOfRings-1);
		float2 ringRadiusDeltaCoords = ReShade::PixelSize * ringRadiusDeltaInPixels;
		for(float ringIndex = 1; ringIndex <= numberOfRings; ringIndex++)
		{
			float pointsOnRing = ringIndex * pointsFirstRing;
			float2 currentRingRadiusCoords = ringRadiusDeltaCoords * ringIndex;
			float anglePerPoint = 6.28318530717958 / pointsOnRing;
			float ringWeight = (numberOfRings-ringIndex);
			float ringHighlightMax = ringIndex/blurInfo.numberOfRings;
			for(float pointNumber = 1; pointNumber <= pointsOnRing; pointNumber++)
			{
				sincos(anglePerPoint * pointNumber, pointOffset.y, pointOffset.x);
				float4 tapCoords = float4(blurInfo.texcoord + (pointOffset * currentRingRadiusCoords), 0, 0);
				float4 tap = tex2Dlod(source, tapCoords);
				
				// x contains blurred CoC, y contains original CoC
				float2 sampleRadii = tex2Dlod(SamplerCDFocusBlurred, tapCoords).xy;
				float absoluteSampleRadius = sampleRadii.x + (sampleRadii.y > 0 ? fragmentRadii.x : 0);
				float weight = lerp(1, ringHighlightMax, HighlightEdgeBias) * saturate(absoluteSampleRadius * fragmentRadii.x);
				threshold = max((dot(tap.xyz, float3(0.3, 0.59, 0.11)) - HighlightThresholdNearPlane) * HighlightGainNearPlane, 0);
				average.xyz += (tap.xyz + lerp(0, tap.xyz, threshold * absoluteSampleRadius)) * weight;
				average.w += weight;
			}
		}
		fragment.xyz = lerp(fragment.xyz, average.xyz/average.w, saturate(3*(fragmentRadii.y < 0 ? 1.0 : fragmentRadii.x)));
		return fragment;
	}

	
	// Calculates the new RGBA fragment for a pixel at texcoord in source using a disc based blur technique described in [Jimenez2014] (Though without using tiles)
	// Function is used in main blur phase, the pre-blur phase (where here a multi-disc pass is used and where Jimenez uses a single disc pass) which 
	// blurs only the far plane. 
	// Performance only depends on # of rings, controlled by the BlurQuality UI option.
	// In:	blurInfo, the pre-calculated disc blur information from the vertex shader.
	//		radiusFactor, the factor to apply to the disc radii for the samples read. Used in pre-blur which uses a smaller radius
	// 		source, the source buffer to read RGBA data from
	// Out: RGBA fragment that's the result of the disc-blur on the pixel at texcoord in source.
	float4 PerformDiscBlur(VSDISCBLURINFO blurInfo, float radiusFactor, sampler2D source)
	{
		float pointsFirstRing = 7; 	// each ring has a multiple of this value of sample points. 
		float4 fragment = tex2Dlod(source, float4(blurInfo.texcoord, 0, 0));
		float signedFragmentRadius = tex2Dlod(SamplerCDFocus, float4(blurInfo.texcoord, 0, 0)).x * radiusFactor;
		float absoluteFragmentRadius = abs(signedFragmentRadius);
		// we'll not process near plane fragments as they're processed in a separate pass. 
		if(signedFragmentRadius <= 0)
		{
			// near plane fragment, will be done in near plane pass 
			return fragment;
		}
		
		// as the disc radii are [-1, 1] we can't use them directly as radii for discs to gather with. We have to make a mapping between [0-1]
		// and the max blur range we want to support. Say we want to have a max blur range of 5% of the screen (so 0.05). 
		// which is on a 1080p screen 96 pixels. So we lerp between 0 and 0.05 with the disc size (which can be max 1.0)
		// Value is factor 100 too high in the UI to give the user better control over the value, so we divide by 100.
		// We need it in pixels as we need to take into account the pixel size to keep the aspect ratio correct for the disc blur sampling
		float radiusInPixels = lerp(0.0, blurInfo.farPlaneMaxBlurInPixels, absoluteFragmentRadius);
		float threshold = max((dot(fragment.xyz, float3(0.3, 0.59, 0.11)) - HighlightThresholdFarPlane) * HighlightGainFarPlane, 0);
		float4 average = float4((fragment.xyz + lerp(0, fragment.xyz, threshold * absoluteFragmentRadius * 0.1)) * saturate(1-HighlightEdgeBias), saturate(1.0-HighlightEdgeBias));
		float2 pointOffset = float2(0,0);
		float ringRadiusDeltaInPixels = radiusInPixels / (blurInfo.numberOfRings-1);
		float2 ringRadiusDeltaCoords = ReShade::PixelSize * ringRadiusDeltaInPixels;
		for(float ringIndex = 1; ringIndex <= blurInfo.numberOfRings; ringIndex++)
		{
			float pointsOnRing = ringIndex * pointsFirstRing;
			float2 currentRingRadiusCoords = ringRadiusDeltaCoords * ringIndex;
			float anglePerPoint = 6.28318530717958 / pointsOnRing;
			float ringWeight = (blurInfo.numberOfRings-ringIndex);
			float ringHighlightMax = ringIndex/blurInfo.numberOfRings;
			for(float pointNumber = 1; pointNumber <= pointsOnRing; pointNumber++)
			{
				sincos(anglePerPoint * pointNumber, pointOffset.y, pointOffset.x);
				// adjust with radius of ring and pixel size to get back to sampler units and to get circular bokeh on every aspect ratio
				float4 tapCoords = float4(blurInfo.texcoord + (pointOffset * currentRingRadiusCoords), 0, 0);
				float signedSampleRadius = tex2Dlod(SamplerCDFocus, tapCoords).x * radiusFactor;
				// an if statement here which skips the tap read altogether is slower than doing the read and multiplying with 1 or 0 depending on the boolean expression.
				float4 tap = tex2Dlod(source, tapCoords);
				float absoluteSampleRadius = abs(signedSampleRadius);
				// this weight is the 'best' I could find against bleed of 'almost in focus' pixels. It's not ideal, but after a lot of 
				// different setups, I can only conclude: nothing is. 
				float weight = lerp(1, ringHighlightMax, HighlightEdgeBias) * saturate(absoluteSampleRadius * absoluteFragmentRadius) * (signedSampleRadius < 0 ? 0 : 1);
				threshold = max((dot(tap.xyz, float3(0.3, 0.59, 0.11)) - HighlightThresholdFarPlane) * HighlightGainFarPlane, 0);
				average.xyz += (tap.xyz + lerp(0, tap.xyz, threshold * absoluteSampleRadius)) * weight;
				average.w += weight;
			}
		}
		fragment.xyz = average.xyz/(average.w + (average.w==0));
		return fragment;
	}


	// Same as PerformDiscBlur but this version is for the pre-blur. It's factored out to have a more streamlined function instead of a lot of if()
	// expressions in the code. 
	// Performance only depends on # of rings, controlled by the BlurQuality UI option.
	// In:	blurInfo, the pre-calculated disc blur information from the vertex shader.
	//		radiusFactor, the factor to apply to the disc radii for the samples read. Used in pre-blur which uses a smaller radius
	// 		source, the source buffer to read RGBA data from
	// Out: RGBA fragment that's the result of the disc-blur on the pixel at texcoord in source.
	float4 PerformPreDiscBlur(VSDISCBLURINFO blurInfo, float radiusFactor, sampler2D source)
	{
		float pointsFirstRing = 7; 	// each ring has a multiple of this value of sample points. 
		float4 fragment = tex2Dlod(source, float4(blurInfo.texcoord, 0, 0));
		float signedFragmentRadius = tex2Dlod(SamplerCDFocus, float4(blurInfo.texcoord, 0, 0)).x * radiusFactor;
		float absoluteFragmentRadius = abs(signedFragmentRadius);
		bool isNearPlaneFragment = signedFragmentRadius < 0;

		// pre blur blurs near plane fragments with near plane samples and far plane fragments with far plane samples [Jimenez2014].
		float radiusInPixels = lerp(0.0, isNearPlaneFragment ? blurInfo.nearPlaneMaxBlurInPixels : blurInfo.farPlaneMaxBlurInPixels, absoluteFragmentRadius);
		float4 average = float4(fragment.xyz, 1.0);
		float2 pointOffset = float2(0,0);
		float ringRadiusDeltaInPixels = radiusInPixels / ((blurInfo.numberOfRings-1) + (blurInfo.numberOfRings==1));
		float2 ringRadiusDeltaCoords = ReShade::PixelSize * ringRadiusDeltaInPixels;
		for(float ringIndex = 1; ringIndex <= blurInfo.numberOfRings-1; ringIndex++)
		{
			float pointsOnRing = ringIndex * pointsFirstRing;
			float2 currentRingRadiusCoords = ringRadiusDeltaCoords * ringIndex;
			float anglePerPoint = 6.28318530717958 / pointsOnRing;
			float ringWeight = (blurInfo.numberOfRings-ringIndex);
			for(float pointNumber = 1; pointNumber <= pointsOnRing; pointNumber++)
			{
				sincos(anglePerPoint * pointNumber, pointOffset.y, pointOffset.x);
				// adjust with radius of ring and pixel size to get back to sampler units and to get circular bokeh on every aspect ratio
				float4 tapCoords = float4(blurInfo.texcoord + (pointOffset * currentRingRadiusCoords), 0, 0);
				float signedSampleRadius = tex2Dlod(SamplerCDFocus, tapCoords).x * radiusFactor;
				float4 tap = tex2Dlod(source, tapCoords);
				// this weight is the 'best' I could find against bleed of 'almost in focus' pixels. It's not ideal, but after a lot of 
				// different setups, I can only conclude: nothing is. 
				float weight = ringWeight * saturate(abs(signedSampleRadius)*absoluteFragmentRadius) * (((signedSampleRadius > 0 && !isNearPlaneFragment) || (signedSampleRadius < 0 && isNearPlaneFragment)) ? 1 : 0);
				average.xyz += tap.xyz * weight;
				average.w += weight;
			}
		}
		fragment.xyz = average.xyz/average.w;
		return fragment;
	}

	
	// Function to obtain the blur disc radius from the source sampler specified and optionally flatten it to zero. Used to blur the blur disc radii using a 
	// separated gaussian blur function.
	// In:	source, the source to read the blur disc radius value to process from
	//		texcoord, the coordinate of the pixel which blur disc radius value we have to process
	//		flattenToZero, flag which if true will make this function convert a blur disc radius value bigger than 0 to 0. 
	//		Radii bigger than 0 are in the far plane and we only want near plane radii in our blurred buffer.
	// Out: processed blur disc radius for the pixel at texcoord in source.
	float GetBlurDiscRadiusFromSource(sampler2D source, float2 texcoord, bool flattenToZero)
	{
		float coc = tex2Dlod(source, float4(texcoord, 0, 0)).x;
		// we're only interested in negative coc's (near plane). All coc's in focus/far plane are flattened to 0. Return the
		// absolute value of the coc as we're working with positive blurred CoCs (as the sign is no longer needed)
		return (flattenToZero && coc >= 0) ? 0 : abs(coc);
	}

	// Performs a single value gaussian blur pass in 1 direction (18 taps). Based on Ioxa's Gaussian blur shader.
	// In:	source, the source sampler to read blur disc radius values to blur from
	//		texcoord, the coordinate of the pixel to blur the blur disc radius for
	// 		offsetWeight, a weight to multiple the coordinate with, containing typically the x or y value of the pixel size
	//		flattenToZero, a flag to pass on to the actual blur disc radius read function to make sure in this pass the positive values are squashed to 0.
	// 					   This flag is needed as the gaussian blur is used separably here so the second pass should not look for positive blur disc radii
	//					   as all values are already positive (due to the first pass).
	// Out: the blurred value for the blur disc radius of the pixel at texcoord. Greater than 0 if the original CoC is in the near plane, 0 otherwise.
	float PerformSingleValueGaussianBlur(sampler2D source, float2 texcoord, float2 offsetWeight, bool flattenToZero)
	{
		float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
		float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };

		float coc = GetBlurDiscRadiusFromSource(source, texcoord, flattenToZero);
		coc *= weight[0];
		
		float2 factorToUse = offsetWeight * NearPlaneMaxBlur;
		for(int i = 1; i < 18; ++i)
		{
			float2 coordOffset = factorToUse * offset[i];
			coc += GetBlurDiscRadiusFromSource(source, texcoord + coordOffset, flattenToZero) * weight[i];
			coc += GetBlurDiscRadiusFromSource(source, texcoord - coordOffset, flattenToZero) * weight[i];
		}
		
		return saturate(coc);
	}

	// Performs a full fragment (RGBA) gaussian blur pass in 1 direction (18 taps). Based on Ioxa's Gaussian blur shader.
	// Will skip any pixels which are in-focus. It will also apply the pixel's blur disc radius to further limit the blur range for near-focused pixels.
	// In:	source, the source sampler to read RGBA values to blur from
	//		texcoord, the coordinate of the pixel to blur. 
	// 		offsetWeight, a weight to multiple the coordinate with, containing typically the x or y value of the pixel size
	// Out: the blurred fragment(RGBA) for the pixel at texcoord. 
	float4 PerformFullFragmentGaussianBlur(sampler2D source, float2 texcoord, float2 offsetWeight)
	{
		float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
		float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };

		float coc = tex2Dlod(SamplerCDFocus, float4(texcoord, 0, 0)).x;
		float4 fragment = tex2Dlod(source, float4(texcoord, 0, 0));
		if(abs(coc) < length(ReShade::PixelSize))
		{
			// in focus, ignore
			return fragment;
		}
		fragment.rgb *= weight[0];
		float2 factorToUse = offsetWeight * PostBlurSmoothing;
		for(int i = 1; i < 18; ++i)
		{
			float2 coordOffset = factorToUse * offset[i];
			fragment.rgb += tex2Dlod(source, float4(texcoord + coordOffset, 0, 0)).rgb * weight[i];
			fragment.rgb += tex2Dlod(source, float4(texcoord - coordOffset, 0, 0)).rgb * weight[i];
		}
		return saturate(fragment);
	}

	// Functions which fills the passed in struct with focus data. This code is factored out to be able to call it either from a vertex shader
	// (in d3d10+) or from a pixel shader (d3d9) to work around compilation issues in reshade.
	void FillFocusInfoData(inout VSFOCUSINFO toFill)
	{
		// Reshade depth buffer ranges from 0.0->1.0, where 1.0 is 1000 in world units. All camera element sizes are in mm, so we state 1 in world units is 
		// 1 meter. This means to calculate from the linearized depth buffer value to meter we have to multiply by 1000.
		// Manual focus value is already in meter (well, sort of. This differs per game so we silently assume it's meter), so we first divide it by
		// 1000 to make it equal to a depth value read from the depth linearized depth buffer.
		float2 autoFocusPointToUse = UseMouseDrivenAutoFocus ? MouseCoords * ReShade::PixelSize : AutoFocusPoint;
		toFill.focusDepth = UseAutoFocus ? ReShade::GetLinearizedDepth(autoFocusPointToUse) : (ManualFocusPlane / 1000);
		toFill.focusDepthInM = toFill.focusDepth * 1000.0; 		// km to m
		toFill.focusDepthInMM = toFill.focusDepthInM * 1000.0; 	// m to mm
		toFill.pixelSizeLength = length(ReShade::PixelSize);
		
		// HyperFocal calculation, see https://photo.stackexchange.com/a/33898. Useful to calculate the edges of the depth of field area
		float hyperFocal = (FocalLength * FocalLength) / (FNumber * SENSOR_SIZE);
		float hyperFocalFocusDepthFocus = (hyperFocal * toFill.focusDepthInMM);
		toFill.nearPlaneInMM = hyperFocalFocusDepthFocus / (hyperFocal + (toFill.focusDepthInMM - FocalLength));	// in mm
		toFill.farPlaneInMM = hyperFocalFocusDepthFocus / (hyperFocal - (toFill.focusDepthInMM - FocalLength));		// in mm
	}

	//////////////////////////////////////////////////
	//
	// Vertex Shaders
	//
	//////////////////////////////////////////////////

	
	// Vertex shader which is used to calculate per-frame static focus info so it's not done per pixel, but only per vertex. 
	VSFOCUSINFO VS_Focus(in uint id : SV_VertexID)
	{
		VSFOCUSINFO focusInfo;
		
		focusInfo.texcoord.x = (id == 2) ? 2.0 : 0.0;
		focusInfo.texcoord.y = (id == 1) ? 2.0 : 0.0;
		focusInfo.vpos = float4(focusInfo.texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

#if __RENDERER__ <= 0x9300 	// doing focusing in vertex shaders in dx9 doesn't work for auto-focus, so we'll just do it in the pixel shader instead
		// fill in dummies, will be filled in pixel shader. Less fast but it is what it is...
		focusInfo.focusDepth = 0;
		focusInfo.focusDepthInM = 0;
		focusInfo.focusDepthInMM = 0;
		focusInfo.pixelSizeLength = 0;
		focusInfo.nearPlaneInMM = 0;
		focusInfo.farPlaneInMM = 0;
#else
		FillFocusInfoData(focusInfo);
#endif
		return focusInfo;
	}

	// Vertex shader which is used to calculate per-frame static info for the disc blur passes so it's not done per pixel, but only per vertex. 
	VSDISCBLURINFO VS_DiscBlur(in uint id : SV_VertexID)
	{
		VSDISCBLURINFO blurInfo;

		blurInfo.texcoord.x = (id == 2) ? 2.0 : 0.0;
		blurInfo.texcoord.y = (id == 1) ? 2.0 : 0.0;
		blurInfo.vpos = float4(blurInfo.texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		
		blurInfo.numberOfRings = round(BlurQuality);
		float pixelSizeLength = length(ReShade::PixelSize);
		blurInfo.farPlaneMaxBlurInPixels = (FarPlaneMaxBlur / 100.0) / pixelSizeLength;
		blurInfo.nearPlaneMaxBlurInPixels = (NearPlaneMaxBlur / 100.0) / pixelSizeLength;
		return blurInfo;
	}

	//////////////////////////////////////////////////
	//
	// Pixel Shaders
	//
	//////////////////////////////////////////////////

	// Pixel shader which produces a blur disc radius for each pixel and returns the calculated value. 
	void PS_Focus(VSFOCUSINFO focusInfo, out float fragment : SV_Target0)
	{
#if __RENDERER__ <= 0x9300 	// doing focusing in vertex shaders in dx9 doesn't work for auto-focus, so we'll just do it in the pixel shader instead
		FillFocusInfoData(focusInfo);
#endif
		fragment = CalculateBlurDiscSize(focusInfo);
	}

	// Pixel shader which will perform a pre-blur on the frame buffer using a blur disc 1/3rd of the size of the original blur disc of the pixel. 
	// This is done to overcome the undersampling gaps we have in the main blur disc sampler [Jimenez2014].
	void PS_PreBlur(VSDISCBLURINFO blurInfo, out float4 fragment : SV_Target0)
	{
		// using radius of 1/3rd gives best overal distribution of samples.
		fragment = PerformPreDiscBlur(blurInfo, 1.0/3.0, ReShade::BackBuffer);
	}

	// Pixel shader which performs the far plane blur pass.
	void PS_BokehBlur(VSDISCBLURINFO blurInfo, out float4 fragment : SV_Target0)
	{
		fragment = PerformDiscBlur(blurInfo, 1.0, SamplerCDBuffer1);
	}

	// Pixel shader which performs the near plane blur pass. Uses a blurred buffer of blur disc radii, based on [Hammon2007] and [Nilsson2012].
	void PS_NearBokehBlur(VSDISCBLURINFO blurInfo, out float4 fragment : SV_Target0)
	{
		fragment = PerformNearPlaneDiscBlur(blurInfo, SamplerCDBuffer2);
	}

	// Pixel shader which performs the first part of the gaussian blur on the blur disc values
	void PS_CoCGaussian1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float fragment : SV_Target0)
	{
		// from source CoC to tmp1
		fragment = PerformSingleValueGaussianBlur(SamplerCDFocus, texcoord, float2(ReShade::PixelSize.x, 0.0), true);
	}

	// Pixel shader which performs the second part of the gaussian blur on the blur disc values
	void PS_CoCGaussian2(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float2 fragment : SV_Target0)
	{
		// from tmp1 to tmp2. Merge original CoC into g.
		fragment = float2(PerformSingleValueGaussianBlur(SamplerCDFocusTmp1, texcoord, float2(0.0, ReShade::PixelSize.y), false), tex2D(SamplerCDFocus, texcoord).x);
	}

	// Pixel shader which performs the first part of the gaussian post-blur smoothing pass, to iron out undersampling issues with the disc blur
	void PS_PostSmoothing1(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target0)
	{
		fragment = PerformFullFragmentGaussianBlur(SamplerCDBuffer1, texcoord, float2(ReShade::PixelSize.x, 0.0));
	}

	// Pixel shader which performs the second part of the gaussian post-blur smoothing pass, to iron out undersampling issues with the disc blur
	void PS_PostSmoothing2(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target0)
	{
		if(ShowDebugInfo)
		{
			if(ShowNearCoCBlur)
			{
				fragment = GetDebugFragment(abs(tex2D(SamplerCDFocusBlurred, texcoord).x), false);
			}
			else
			{
				fragment = GetDebugFragment(abs(tex2D(SamplerCDFocus, texcoord).x), true);
			}
			return;
		}
		fragment = PerformFullFragmentGaussianBlur(SamplerCDBuffer2, texcoord, float2(0.0, ReShade::PixelSize.y));
		float4 originalFragment = tex2D(SamplerCDBuffer1, texcoord);
		float coc = tex2Dlod(SamplerCDFocus, float4(texcoord, 0, 0)).x;
		fragment.rgb = lerp(originalFragment.rgb, fragment.rgb, saturate(6 * coc));		// weight based on coc radius combined with a magic value that fell out of the magic hatter's hat. Magic!
		fragment.w = 1.0;
	}

	// Pixel shader which displays the focusing overlay helpers if the mouse button is down and the user enabled ShowOutOfFocusPlaneOnMouseDown.
	// it displays the near and far plane at the hyperfocal planes (calculated in vertex shader) with the overlay color and the in-focus area in between
	// as normal. It then also blends the focus plane as a separate color to make focusing really easy. 
	void PS_FocusHelper(in VSFOCUSINFO focusInfo, out float4 fragment : SV_Target0)
	{
#if __RENDERER__ <= 0x9300 	// doing focusing in vertex shaders in dx9 doesn't work for auto-focus, so we'll just do it in the pixel shader instead
		FillFocusInfoData(focusInfo);
#endif
		fragment = tex2D(SamplerCDBuffer3, focusInfo.texcoord);
		if(ShowOutOfFocusPlaneOnMouseDown && LeftMouseDown)
		{
			float depthPixelInMM = ReShade::GetLinearizedDepth(focusInfo.texcoord) * 1000.0 * 1000.0;
			float coc = tex2D(SamplerCDFocus, focusInfo.texcoord).x;
			float4 colorToBlend = fragment;
			if(depthPixelInMM < focusInfo.nearPlaneInMM || (focusInfo.farPlaneInMM > 0 && depthPixelInMM > focusInfo.farPlaneInMM))
			{
				colorToBlend = float4(OutOfFocusPlaneColor, 1.0);
			}
			else
			{
				if(abs(coc) < focusInfo.pixelSizeLength)
				{
					colorToBlend = float4(FocusPlaneColor, 1.0);
				}
			}
			fragment = lerp(fragment, colorToBlend, OutOfFocusPlaneColorTransparency);
			if(UseAutoFocus)
			{
				float2 focusPointCoords = UseMouseDrivenAutoFocus ? MouseCoords * ReShade::PixelSize : AutoFocusPoint;
				fragment = lerp(fragment, FocusCrosshairColor, FocusCrosshairColor.w * saturate(exp(-BUFFER_WIDTH * length(focusInfo.texcoord - float2(focusPointCoords.x, focusInfo.texcoord.y)))));
				fragment = lerp(fragment, FocusCrosshairColor, FocusCrosshairColor.w * saturate(exp(-BUFFER_HEIGHT * length(focusInfo.texcoord - float2(focusInfo.texcoord.x, focusPointCoords.y)))));
			}
		}
	}

	//////////////////////////////////////////////////
	//
	// Techniques
	//
	//////////////////////////////////////////////////

	technique CinematicDOF
	{
		pass Focus { VertexShader = VS_Focus; PixelShader = PS_Focus; RenderTarget = texCDFocus; }
		pass CoCBlur1 { VertexShader = PostProcessVS; PixelShader = PS_CoCGaussian1; RenderTarget = texCDFocusTmp1; }
		pass CoCBlur2 { VertexShader = PostProcessVS; PixelShader = PS_CoCGaussian2; RenderTarget = texCDFocusBlurred; }
		pass PreBlur { VertexShader = VS_DiscBlur; PixelShader = PS_PreBlur; RenderTarget = texCDBuffer1; }
		pass BokehBlur { VertexShader = VS_DiscBlur; PixelShader = PS_BokehBlur; RenderTarget = texCDBuffer2; }
		pass NearBokehBlur { VertexShader = VS_DiscBlur; PixelShader = PS_NearBokehBlur; RenderTarget = texCDBuffer1; }
		pass PostSmoothing1 { VertexShader = PostProcessVS; PixelShader = PS_PostSmoothing1; RenderTarget = texCDBuffer2; }
		pass PostSmoothing2 { VertexShader = PostProcessVS; PixelShader = PS_PostSmoothing2; RenderTarget = texCDBuffer3; }
		pass FocusHelper { VertexShader = VS_Focus; PixelShader = PS_FocusHelper; }
	}

}