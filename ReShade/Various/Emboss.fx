NAMESPACE_ENTER(Various)

#include Various_SETTINGS_DEF

#if USE_EMBOSS

float4 PS_Emboss(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 res = 0;
	float4 origcolor = tex2D(RFX_backbufferColor, texcoord);

        float2 offset;
	sincos(radians( iEmbossAngle), offset.y, offset.x);
	float3 col1 = tex2D(RFX_backbufferColor, texcoord - RFX_PixelSize*fEmbossOffset*offset).rgb;
	float3 col2 = origcolor.rgb;
	float3 col3 = tex2D(RFX_backbufferColor, texcoord + RFX_PixelSize*fEmbossOffset*offset).rgb;

#if(bEmbossDoDepthCheck != 0)
	float depth1 = tex2D(RFX_depthColor,texcoord - RFX_PixelSize*fEmbossOffset).r;
	float depth2 = tex2D(RFX_depthColor,texcoord).r;
	float depth3 = tex2D(RFX_depthColor,texcoord + RFX_PixelSize*fEmbossOffset).r;
#endif
	
	float3 colEmboss = col1 * 2.0 - col2 - col3;

	float colDot = max(0,dot(colEmboss, 0.333))*fEmbossPower;

	float3 colFinal = col2 - colDot;

	float luminance = dot( col2, float3( 0.6, 0.2, 0.2 ) );

	res.xyz = lerp( colFinal, col2, luminance * luminance ).xyz;
#if(bEmbossDoDepthCheck != 0)
        if(max(abs(depth1-depth2),abs(depth3-depth2)) > fEmbossDepthCutoff) res = origcolor;
#endif
	return res;

}

technique Emboss_Tech <bool enabled = RFX_Start_Enabled; int toggle = Emboss_ToggleKey; >
{
	pass Emboss
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_Emboss;
	}
}

#endif

#include Various_SETTINGS_UNDEF

NAMESPACE_LEAVE()
