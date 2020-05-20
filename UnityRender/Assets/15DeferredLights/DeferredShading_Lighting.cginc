#if !defined(DEFERRED_SHADING_LIGHTING)
#define DEFERRED_SHADING_LIGHTING

#include "UnityCG.cginc"



struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
};

struct v2f
{
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
	float3 ray : TEXCOORD1;
};

v2f vert(appdata v)
{
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = ComputeScreenPos(o.pos);
	o.ray = v.normal;
	return o;
}

sampler2D _MainTex;

fixed4 frag(v2f i) : SV_Target
{
	float2 uv = i.uv.xy / i.uv.w;
	//...
	return 0;
}

#endif