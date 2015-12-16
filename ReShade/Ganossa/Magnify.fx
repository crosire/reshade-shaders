NAMESPACE_ENTER(Ganossa)

#include Ganossa_SETTINGS_DEF

#if (USE_Magnify == 1)

float4 PS_Magnify(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	bool ok = magnifyStartPixelWidth < magnifyEndPixelWidth && magnifyStartPixelHeight < magnifyEndPixelHeight && magnifyStartPixelWidth >= 0 && magnifyStartPixelHeight >= 0
	&& int(magnifyEndPixelWidth) <= BUFFER_WIDTH && int(magnifyEndPixelHeight) <= BUFFER_HEIGHT;

	float2 res = float2(float(magnifyEndPixelWidth - magnifyStartPixelWidth)/BUFFER_WIDTH, float(magnifyEndPixelHeight - magnifyStartPixelHeight)/BUFFER_HEIGHT);
	
	if(ok) return tex2D(RFX_backbufferColor, float2(texcoord.x*res.x+BUFFER_RCP_WIDTH*magnifyStartPixelWidth, texcoord.y*res.y+BUFFER_RCP_HEIGHT*magnifyStartPixelHeight));
	else return tex2D(RFX_backbufferColor, texcoord);
}

technique Magnify_Tech <bool enabled = RFX_Start_Enabled; int toggle = Magnify_ToggleKey; >
{
	pass MagnifyPass
	{
		VertexShader = RFX_VS_PostProcess;
		PixelShader = PS_Magnify;
	}
}

#endif

#include Ganossa_SETTINGS_UNDEF

NAMESPACE_LEAVE()
