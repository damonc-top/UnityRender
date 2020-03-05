Shader "Customer/MyMultiLightShader"
{
	Properties
	{
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Metallic ("Metallic", Range(0,1)) = 0.5
		_Smoothness ("Smoothness", Range(0,1)) = 0.5
	}
	 
	//multi Direction light
	
	/*SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma target 3.0
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "MyLighting.cginc"

			ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "MyLighting.cginc"

			ENDCG
		}
	}*/
	
	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma target 3.0
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
			//#define FORWARD_BASE_PASE
			#include "MyLighting.cginc"

			ENDCG
		}
		
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_fwdadd
			//#pragma multi_compile DIRECTION DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "MyLighting.cginc"

			ENDCG
		}
	}
}
