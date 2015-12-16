/**
 * Copyright (C) 2015 Ganossa (mediehawk@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software with restriction, including without limitation the rights to
 * use and/or sell copies of the Software, and to permit persons to whom the Software 
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and below) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "Software"), to deal in the Software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the Software, and subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#if Depth_HeatHazeControle
	float depth = tex2D(RFX_depthColor, float2(texcoord.x,min(1.0f,texcoord.y+0.15f))).r;
	depth = 2.0 / (-99.0 * depth + 101.0);
#else
	float depth = 0.0f;
#endif

float4 high = tex2D(alInColor, float2(texcoord.x,min(1.0f,texcoord.y+0.15f)))*(25.0f-(max(0.0f,texcoord.y+0.15f-1.0f)*10.0f));

#if AL_Adaptation && USE_AMBIENT_LIGHT
//DetectLow
#if AL_HQAdapt
	float4 detectLow = tex2D(detectLowColor, float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT));
#else
	float4 detectLow = tex2D(detectLowColor, float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT))/4;
#endif
	float low = sqrt(0.641*detectLow.r*detectLow.r+0.291*detectLow.g*detectLow.g+0.068*detectLow.b*detectLow.b);
	low *= min(1.0f,1.641*detectLow.r/(1.719*detectLow.g+1.932*detectLow.b));
//.DetectLow

	float adapt = low*(low+1.0f)*alAdapt*alInt*5.0f;
	high.xyz *= max(0.0f,(1.0f - adapt*0.1f*alAdaptHeatMult));
#endif

float highMul = sqrt(0.641*high.r*high.r+0.291*high.g*high.g+0.068*high.b*high.b);
highMul *= min(1.0f,1.641*high.r/(1.719*high.g+1.932*high.b))*min(1.0f,1.75f-depth)*(1.5f-texcoord.y);

heathazecolor.y = tex2D(RFX_backbufferColor, texcoord.xy + heatoffset.xy * 0.001 * fHeatHazeOffset *min(1.0f,max(0.0f,(highMul-0.2f))*10f)).y;
heathazecolor.x = tex2D(RFX_backbufferColor, texcoord.xy + heatoffset.xy * 0.001 * fHeatHazeOffset * (1.0+fHeatHazeChromaAmount) *min(1.0f,max(0.0f,(highMul-0.2f))*10f)).x;
heathazecolor.z = tex2D(RFX_backbufferColor, texcoord.xy + heatoffset.xy * 0.001 * fHeatHazeOffset * (1.0-fHeatHazeChromaAmount) *min(1.0f,max(0.0f,(highMul-0.2f))*10f)).z;
