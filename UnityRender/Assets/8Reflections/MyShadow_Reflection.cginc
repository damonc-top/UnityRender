// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MY_SHADOW_REFLECTION_INCLUDE)
	#define MY_SHADOW_REFLECTION_INCLUDE

	#include "UnityCG.cginc"

	struct InputData {
		float4 position : POSITION;
		float3 normal :	NORMAL;
	};


	#if defined(SHADOWS_CUBE)
		struct Interplotars {
			float4 position : SV_POSITION;
			float3 lightVec : TEXCOORD0;
		};

		Interplotars MyVertexProgram(InputData v){
			Interplotars i;
			i.position = UnityObjectToClipPos(v.position);
			i.lightVec = mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
			//float4 position = UnityClipSpaceShadowCasterPos(i.position, i.normal);//方向光源：简单的裁剪空间顶点坐标
			return	i;
		}

		half4 MyFragmentProgram(Interplotars i) : SV_TARGET{
			float depth = length(i.lightVec) + unity_LightShadowBias.x;
			depth *= _LightPositionRange.w;
			return UnityEncodeCubeShadowDepth(depth);
		}

	#else
		float4 MyVertexProgram(InputData i) : SV_POSITION{
			//float4 position = UnityObjectToClipPos(i.position);
			float4 position = UnityClipSpaceShadowCasterPos(i.position, i.normal);
			return	UnityApplyLinearShadowBias(position);
		}

		half4 MyFragmentProgram() : SV_TARGET{
			return 0;
		}
	#endif

#endif