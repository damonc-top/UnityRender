// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MY_LIGHTING_TRANSPARENCY_INCLUDED)
#define MY_LIGHTING_TRANSPARENCY_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _MainTex, _MetallicMap, _NormalMap;
float4 _MainTex_ST, _DetailTex_ST;
float4 _Tint;

sampler2D _DetailTex, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

sampler2D _OcclusionMap, _EmissionMap, _DetailMask;

float _Metallic, _Smoothness, _OcclusionStrength, _AlphaCutOff;
float3 _Emission;


struct VertexData {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

struct Interpolators {
	float4 pos : SV_POSITION;
	float4 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;

#if defined(BINORMAL_PER_FRAGMENT)
	float4 tangent : TEXCOORD2;
#else
	float3 tangent : TEXCOORD2;
	float3 binormal : TEXCOORD3;
#endif

	float3 worldPos : TEXCOORD4;

#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor : TEXCOORD5;
#endif

	SHADOW_COORDS(6)
};

//采样金属纹理(灰度图)r
float GetMetallic(Interpolators i) {
#if defined(_METALLIC_MAP)
	return tex2D(_MetallicMap, i.uv.xy).r;
#else
	return _Metallic;
#endif
}
//采样遮挡纹理
float GetOcclusion(Interpolators i) {
#ifdef _OCCLUSION_MAP
	return tex2D(_OcclusionMap, i.uv).g * _OcclusionStrength;
#endif
	return 1;
}
//采样光滑纹理a
float GetSmoothness(Interpolators i) {
	float smoothness = 1;
#if defined(_SMOOTHNESS_ALBEDO)
	smoothness = tex2D(_MainTex, i.uv.xy).a;
#elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
	smoothness = tex2D(_MetallicMap, i.uv.xy).a ;
#endif
	return smoothness * _Smoothness;
}
//采样自发光
float3 GetEmission(Interpolators i) {
#ifdef FORWARD_BASE_PASS
	#ifdef _EMISSION_MAP
		return tex2D(_EmissionMap, i.uv.xy).rgb * _Emission;
	#else
		return _Emission;
	#endif
#else
	return 0;
#endif
}
//采样细节遮罩
float GetDetailMask(Interpolators i) {
#if defined(_DETAIL_MASK)
	return tex2D(_DetailMask, i.uv.xy).a;
#else
	return 1;
#endif
}
//采样Detail Albedo
float3 GetAlbedo(Interpolators i) {
	float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
	float3 detail = tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;
	albedo = lerp(albedo, albedo * detail, GetDetailMask(i));
	return albedo;
}
//采样alpha
float GetAlpha(Interpolators i){
	float alpha = _Tint.a;
#if !defined(_SMOOTHNESS_ALBEDO)
	alpha *= tex2D(_MainTex, i.uv.xy).a;
#endif
	return alpha;
}

void ComputeVertexLightColor(inout Interpolators i) {
#if defined(VERTEXLIGHT_ON)
	i.vertexLightColor = Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb,
		unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, i.worldPos, i.normal
	);
#endif
}

float3 CreateBinormal(float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

Interpolators MyVertexProgram(VertexData v) {
	Interpolators i;
	i.pos = UnityObjectToClipPos(v.vertex);
	i.worldPos = mul(unity_ObjectToWorld, v.vertex);
	i.normal = UnityObjectToWorldNormal(v.normal);

#if defined(BINORMAL_PER_FRAGMENT)
	i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
#else
	i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
	i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
#endif

	i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

	TRANSFER_SHADOW(i);

	ComputeVertexLightColor(i);
	return i;
}

UnityLight CreateLight(Interpolators i) {
	UnityLight light;

#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
	light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
#else
	light.dir = _WorldSpaceLightPos0.xyz;
#endif

	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
	//attenuation *= GetOcclusion(i);
	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

float3 BoxProjection(float3 direction, float3 position, float4 cubeMapPosition, float3 boxMin, float3 boxMax) {
	boxMin -= position;
	boxMax -= position;
	
	#if UNITY_SPECCUBE_BOX_PROJECTION
		UNITY_BRANCH
		if (cubeMapPosition.w > 0) {
			float3 scalarVec = (direction > 0 ? boxMax : boxMin) / direction;
			float scalar = min(min(scalarVec.x, scalarVec.y), scalarVec.z);
			direction = direction * scalar + (position - cubeMapPosition);
		}
	#endif
	return direction;
}

UnityIndirect CreateIndirectLight(Interpolators i, float3 viewDir) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

#if defined(VERTEXLIGHT_ON)
	indirectLight.diffuse = i.vertexLightColor;
#endif

#if defined(FORWARD_BASE_PASS)
	indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));

	float3 reflectDir = reflect(-viewDir, i.normal);
	Unity_GlossyEnvironmentData envData;
	envData.roughness = GetSmoothness(i);

	envData.reflUVW = BoxProjection(reflectDir, i.worldPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);//reflectDir;
	float3 probe0 = Unity_GlossyEnvironment(
		UNITY_PASS_TEXCUBE(unity_SpecCube0),
		unity_SpecCube0_HDR,
		envData
	);
	
	#if UNITY_SPECCUBE_BLENDING
		UNITY_BRANCH
		if (unity_SpecCube0_BoxMin.w < 0.9999) {
			envData.reflUVW = BoxProjection(reflectDir, i.worldPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
			float3 probe1 = Unity_GlossyEnvironment(
				UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
				unity_SpecCube1_HDR,
				envData
			);

			indirectLight.specular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);
		}
		else {
			indirectLight.specular = probe0;
		}
	#else
			indirectLight.specular = probe0;
	#endif

	float occlusion = GetOcclusion(i);
	indirectLight.diffuse *= occlusion;
	indirectLight.specular *= occlusion;
#endif

	return indirectLight;
}

void InitializeFragmentNormal(inout Interpolators i) {
	float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
	float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
	detailNormal = lerp(float3(0, 0, 1), detailNormal, GetDetailMask(i));
	float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);

#if defined(BINORMAL_PER_FRAGMENT)
	float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
#else
	float3 binormal = i.binormal;
#endif

	i.normal = normalize(
		tangentSpaceNormal.x * i.tangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * i.normal
	);
}

float4 MyFragmentProgram(Interpolators i) : SV_TARGET{
	float alpha = GetAlpha(i);
#ifdef _RENDERING_CUTOUT
	clip(alpha - _AlphaCutOff);
#endif
	InitializeFragmentNormal(i);

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

	//float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
	//albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

	float3 specularTint;
	float oneMinusReflectivity;
	float3 albedo = DiffuseAndSpecularFromMetallic(
		GetAlbedo(i), GetMetallic(i), specularTint, oneMinusReflectivity
	);

	float4 final = UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, GetSmoothness(i),
		i.normal, viewDir,
		CreateLight(i), CreateIndirectLight(i, viewDir)
	);
	final.rgb += GetEmission(i);
#ifdef _RENDERING_FADE
	final.a = alpha;
#endif
	return final;
}

#endif