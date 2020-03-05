Shader "Unlit/MyTransparency"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_AlphScale("AlphaCutout", Range(0,1)) = 0
	}

	SubShader
	{
		Tags { "Queue" = "AlphaTest" "RenderType"="Opaque" "IgnoreProjector"="True"}
		Pass
		{
			Tags { "LightMode"="ForwardBase"}
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha

			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AlphScale;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return fixed4(col.rgb, col.a*_AlphScale);
			}
			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ForwardBase"}
			ZWrite On
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AlphScale;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return fixed4(col.rgb, col.a*_AlphScale);
			}
			ENDCG
		}
	}
}
