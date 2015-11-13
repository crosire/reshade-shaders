   /*-----------------------------------------------------------.
  /                           Custom                            /
  '-----------------------------------------------------------*/

#define lutSize 512.0

float3 ColorLUT(float4 position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
  float3 colorInput = tex2D(s0, texcoord).rgb;

  half3 scale = (lutSize - 1.0) / lutSize;

  half3 offset = 1.0 / (2.0 * lutSize);

  float3 color = tex3D(lut, scale * rawColor + offset);

  color = lerp(colorInput, color, custom_strength); //Adjust the strength of the effect

  return saturate(color);
}

#undef lutSize