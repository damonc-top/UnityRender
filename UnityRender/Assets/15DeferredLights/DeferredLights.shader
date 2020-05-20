Shader "Custom/DeferredLights"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always
		
		Pass
		{
			CGPROGRAM

			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers nomrt

			#pragma multi_compile_lightpass
			#pragma multi_compile _ UNITY_HDR_ON

			#include "DeferredShading_Lighting.cginc"
			 
			ENDCG
		}

		Pass
		{
			Stencil
			{
				Ref[_StencilNonBackground]
				ReadMask[_StencilNonBackground]
				CompBack Equal
				CompFront Equal
			}
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _LightBuffer;

			fixed4 frag(v2f i) : SV_Target
			{
				return -log2(tex2D(_LightBuffer, i.uv));
			}

			ENDCG
		}
	}
}
