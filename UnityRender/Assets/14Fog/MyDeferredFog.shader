Shader "Custom/MyDeferredFog"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader
	{
		// No culling or depth
		Cull Off
		ZWrite Off
		ZTest Always

		Pass
		{
			CGPROGRAM

			#pragma vertex   VertexProgram
			#pragma fragment FragmentProgram

			#pragma multi_compile_fog
			#define FOG_DISTANCE
			#define FOG_SKYBOX

			#include "UnityCG.cginc"

			sampler2D _MainTex, _CameraDepthTexture;
			float3 _FustumCorners[4];

			struct modelData
			{
				float4 vertex : POSITION;
				float2 uv	  : TEXCOORD0;
			};
			
			struct Interpolators
			{
				float4 position : SV_POSITION;
				float2 uv	    : TEXCOORD0;
			#if defined(FOG_DISTANCE)
				float3 ray : TEXCOORD1;
			#endif
			};

			Interpolators VertexProgram(modelData m)
			{
				Interpolators i;
				i.position = UnityObjectToClipPos(m.vertex);
				i.uv = m.uv;
			#if defined(FOG_DISTANCE)
				i.ray = _FustumCorners[m.uv.x + 2 * m.uv.y];
			#endif
				return i;
			}
			
			/* init _CameraDepthTexture */
			//UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			float4 FragmentProgram(Interpolators i) : SV_Target
			{
				/* HLSLSupport: get raw data from depth buffer */
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
				/* so, need to convert pos from homogeneous to clip-space */
				depth = Linear01Depth(depth);
				
				float viewDistance = 0;
#if defined(FOG_DISTANCE)
				viewDistance = length(i.ray * depth);
#else
				/* scaled by the far clip plane`s distance , z is far clip dis */
				viewDistance = depth * _ProjectionParams.z - _ProjectionParams.y;
#endif
				UNITY_CALC_FOG_FACTOR_RAW(viewDistance);

				unityFogFactor = saturate(unityFogFactor);
#ifdef FOG_SKYBOX
				if (depth > 0.999) 
				{
					unityFogFactor = 1;
				}
#endif
				/* this is turn off fog. none of fog keyword are defined.   */
				/* Actually better way is deactive or remove this component */
#if !defined(FOG_LINEAR) || !defined(FOG_EXP) || !defined(FOG_EXP2)
				unityFogFactor = 1;
#endif
				float3 sourceColor  = tex2D(_MainTex, i.uv).rgb;
				float3 color = lerp(unity_FogColor.rgb, sourceColor, unityFogFactor);
				return float4(color, 1);
			}
			ENDCG
		}
	}
}