#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

float4		_Tint;
sampler2D	_MainTex;
float4		_MainTex_ST;

float		_Metallic;
float		_Smoothness;

struct VertexData {
	float4 position : POSITION;
	float3 normal	: Normal;
	float2 uv		: TEXCOORD0;
};

struct Interpolators {
	float4 position : SV_POSITION;
	float2 uv		: TEXCOORD0;
	float3 normal	: TEXCOORD1;
	float3 worldPos : TEXCOORD2;
	
	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightCoolr : TEXCOORD3;
	#endif
};

void CreateVertexLightColor(inout Interpolators i){
	#if defined(VERTEXLIGHT_ON)
		/*
		float3 lightPos = (unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
		float3 lightVec = lightPos - i.worldPos;
		float3 lightDir = normalize(lightVec);
		float ndotl = DotClamped(i.normal, lightDir);
		float attenuation = 1 / (1 + dot(lightVec, lightVec) * unity_4LightAtten0.x);
		i.vertexLightCoolr = unity_LightColor[0].rgb * ndotl * attenuation;
		*/
		i.vertexLightCoolr = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[4].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal
		);
	#endif
}

UnityIndirect CreateIndirect(Interpolators i){
	UnityIndirect indirectLight;
	indirectLight.diffuse  = 0;
	indirectLight.specular = 0;
	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightCoolr;
	#endif
	#if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
	#endif
	return indirectLight;
}

UnityLight CreateLight(Interpolators i){
	UnityLight light;
	
	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif
	
	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	light.color 		= _LightColor0.rgb * attenuation;
	light.ndotl 		= DotClamped(i.normal, light.dir);
	return light;
}

Interpolators MyVertexProgram (VertexData v) {
	//统一在世界空间计算
	Interpolators i;
	//i.position = mul(UNITY_MATRIX_MVP, v.position);
	i.position	= UnityObjectToClipPos(v.position);
	i.uv		= TRANSFORM_TEX(v.uv, _MainTex);

	//i.normal  = mul(unity_ObjectToWorld, v.normal);
	//i.normal  = mul(transpose((float3x3)unity_WorldToObject), v.normal);
	i.normal	= UnityObjectToWorldNormal(v.normal);

	i.worldPos	= mul(unity_ObjectToWorld, v.position);

	CreateVertexLightColor(i);
	return i;
}

float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
	i.normal = normalize(i.normal);
	
	//float3 lightDir = _WorldSpaceLightPos0.xyz;
	//float3 lightColor = _LightColor0.rgb;
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

	float3 specularTint;
	float oneMinusReflectivity;

	albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
	);

	// UnityLight light;
	// light.color = lightColor;
	// light.dir = lightDir;
	// light.ndotl = DotClamped(i.normal, lightDir);

	//UnityIndirect indirectLight;
	//indirectLight.diffuse 	= 0;
	//indirectLight.specular	= 0;
	
	//float3 shColor = ShadeSH9(float4(i.normal, 1));
	//return float4(shColor, 0);

	return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		CreateLight(i),  CreateIndirect(i)
	);
}

#endif