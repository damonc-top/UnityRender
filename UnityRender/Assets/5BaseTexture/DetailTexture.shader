Shader "Unlit/DetailTexture"
{
	Properties
	{
		_Tint ("Tine", color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_DetailTex ("Detail", 2D) = "white" {}
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float2 detailUV : TEXCOORD1;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float2 detailUV : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D	_MainTex, _DetailTex;
			fixed4		_MainTex_ST, _DetailTex_ST;
			fixed4		_Tint;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.detailUV = TRANSFORM_TEX(v.detailUV, _DetailTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample sigle texture
				fixed4 col = tex2D(_MainTex, i.uv) * _Tint;
				col *= tex2D(_MainTex, i.detailUV * 10) * unity_ColorSpaceDouble;
				return col;
			}
			ENDCG
		}
	}
}
