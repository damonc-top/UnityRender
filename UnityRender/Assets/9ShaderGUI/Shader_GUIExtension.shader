Shader "Custom/Shader_GUIExtension" {
	
	Properties{
		_MainTex("Albedo", 2D) = "white" {}
		_Tint("Tint", Color) = (1, 1, 1, 1)

		[NoScaleOffset] _NormalMap("Normals", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		[NoScaleOffset]_MetallicMap("MetallicMap", 2D) = "white"{}
		[Gamma] _Metallic("Metallic", Range(0, 1)) = 0
		_Smoothness("Smoothness", Range(0, 1)) = 0.1

		_DetailTex("Detail Texture", 2D) = "gray" {}
		[NoScaleOffset] _DetailNormalMap("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale("Detail Bump Scale", Float) = 1
	}

	CGINCLUDE

	#define BINORMAL_PER_FRAGMENT

	ENDCG
			
	SubShader{

		Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON
			//#pragma multi_compile _ _MATALLIC_MAP
			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#define FORWARD_BASE_PASS

			#include "MyLighting_GUIExtension.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_fwdadd_fullshadows

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "MyLighting_GUIExtension.cginc"

			ENDCG
		}

		Pass{
			Tags{"LightMode" = "ShadowCaster"}

			CGPROGRAM

			#pragma multi_compile_shadowcaster

			#pragma target 3.0
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "MyShadow_GUIExtension.cginc"

			ENDCG
		}
	}
	CustomEditor "GUIExtension.MyCustomShaderGUI"
}