Shader "Unlit/BaseLighting"
{
	Properties{
		_Tint("Tint", Color) = (1, 1, 1, 1)
		//_SpecularTint("Specular",Color) = (1,1,1,1)
		_Metallic("Metallic", Range(0,1)) = 0.5
		_MainTex("Albedo",2D) = "white" {}
		_Smoothness("Smoothness",Range(0,1)) = 0.5
	}

	SubShader{

		Pass{

			Tags{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma target 3.0

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			/*#include "UnityStandardBRDF.cginc"
			#include "UnityStandardUtils.cginc"*/
			#include "UnityPBSLighting.cginc"

			float4		_Tint;
			//float4		_SpecularTint;
			float		_Metallic;
			sampler2D	_MainTex;
			float4		_MainTex_ST;
			float		_Smoothness;
		
			struct VertexData {
				float4 position	: POSITION;
				float3 normal	: NORMAL;
				float2 uv		: TEXCOORD0;
			};

			struct Interpolators {
				float4 position : SV_POSITION;
				float2 uv		: TEXCOORD0;
				float3 normal	: TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			Interpolators MyVertexProgram(VertexData v) {
				Interpolators i;
				i.position = UnityObjectToClipPos(v.position);
				i.normal   = UnityObjectToWorldNormal(v.normal);
				i.uv	   = v.uv * _MainTex_ST.xy + _MainTex_ST.zw;
				i.worldPos = mul(unity_ObjectToWorld, v.position);//UnityObjectToWorldPos(v.position);
				return i;
			}

			float4 MyFragmentProgram(Interpolators i) : SV_TARGET
			{
				i.normal = normalize(i.normal);

				float3 lightDir   = _WorldSpaceLightPos0.xyz;
				float3 lightColor = _LightColor0.rgb;
				float3 albedo	  = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
				
				//单色能量守恒 3
				//albedo		  *= 1 - _SpecularTint.rgb;
				//albedo		  *= 1 - max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));

				//使用内置函数计算单色能量守恒 4
				/*float oneMinusReflectivity;
				albedo			  = EnergyConservationBetweenDiffuseAndSpecular(
					albedo, _SpecularTint.rgb, oneMinusReflectivity
				);*/

				//float3 diffuse    = albedo * lightColor * DotClamped(lightDir, i.normal);

				//diffuse 1
				//return  float4(diffuse, 1);

				//specular 2
				float3 viewDirect = normalize(_WorldSpaceCameraPos - i.worldPos);
				
				/*float3 reflection = reflect(-lightDir, i.normal);
				return pow(
					DotClamped(viewDirect, reflection),
					_Smoothness * 100
				);*/
				
				//specular 3
				//float3 halfDirect = normalize(lightDir + viewDirect);
				/*float3 specular   = _SpecularTint.rgb * lightColor * pow(
					DotClamped(i.normal, halfDirect),
					_Smoothness * 100
				);*/

				//金属工作流 5
				//float3 specularTint			= albedo * _Metallic;
				//float oneMinusReflectivity	= 1 - _Metallic;
				//albedo						*= oneMinusReflectivity;
				//6
				float3 specularTint;
				float oneMinusReflectivity;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);

				/*float3 diffuse				= albedo * lightColor * DotClamped(lightDir, i.normal);
				float3 specular				= specularTint.rgb * lightColor * pow(
					DotClamped(i.normal, halfDirect),
					_Smoothness * 100
				);
				return float4(diffuse+specular, 1);*/
				
				//直接光
				UnityLight light;
				light.color = lightColor;
				light.dir   = lightDir;
				light.ndotl = DotClamped(lightDir, i.normal);
				//间接光
				UnityIndirect indirect;
				indirect.diffuse  = 0;
				indirect.specular = 0;

				//PBS
				return UNITY_BRDF_PBS(
					albedo,
					specularTint,
					oneMinusReflectivity,
					_Smoothness,
					i.normal,
					viewDirect,
					light,
					indirect
				);
			}

			ENDCG
		}
	}
}
