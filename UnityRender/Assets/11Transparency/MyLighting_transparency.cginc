// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MY_LIGHTING_TRANSPARENCY_INCLUDED)
#define MY_LIGHTING_TRANSPARENCY_INCLUDED

#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"

sampler2D _MainTex, _DetailTex, _NormalMap, _DetailNormalMap;
float4 _Tint, _MainTex_ST, _DetailTex_ST;
float _BumpScale, _DetailBumpScale, _Metallic, _Smoothness, _CutoutVal;

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
	float3 vertexLightColor : TEXCOORD6;
#endif

//#if defined(SHADOWS_SCREEN)
//	float4 shadowCoordinate : TEXCOORD6;
//#endif
	SHADOW_COORDS(6)
};

float GetTexAlph(sampler2D tex, float2 uv) {
	return tex2D(tex, uv).a;
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
//#if defined(SHADOWS_SCREEN)
//	i.shadowCoordinate.xy = (float2(i.pos.x, -i.pos.y) + i.pos.w);// (i.pos.xy + i.pos.w) * 0.5;
//	i.shadowCoordinate.zw = i.pos.zw;
//#endif
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

//#if defined(SHADOWS_SCREEN)
//	float attenuation = tex2D(_ShadowMapTexture, i.shadowCoordinate.xy / i.shadowCoordinate.w);
//#else
	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
//#endif

	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

/*init box projection directio*/
float3 BoxProjection(float3 direction, float3 position, float4 cubeMapPosition, float3 boxMin, float3 boxMax) {
	boxMin -= position;
	boxMax -= position;
/*	float x = (direction.x > 0 ? boxMax.x : boxMin.x) / direction.x;
	float y = (direction.y > 0 ? boxMax.y : boxMin.y) / direction.y;
	float z = (direction.z > 0 ? boxMax.z : boxMin.z) / direction.z;
	float scalar = min(min(x, y), z);*/
	
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
	/*1 simplest sampling*/
	/*float3 reflectDir = reflect(-viewDir, i.normal);
	half4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
	indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);*/
	
	/*2 Lod sample*/
	/*float3 reflectDir = reflect(-viewDir, i.normal);
	float roughness = 1 - _Smoothness;
	roughness *= 1.7 - 0.7 * roughness;
	half4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
	indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);*/
	/*3 Unity macro*/
	float3 reflectDir = reflect(-viewDir, i.normal);
	Unity_GlossyEnvironmentData envData;
	envData.roughness = 1 - _Smoothness;

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
				//UNITY_PASS_TEXCUBE(unity_SpecCube1),
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
#endif

	return indirectLight;
}

void InitializeFragmentNormal(inout Interpolators i) {
	float3 mainNormal =
		UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
	float3 detailNormal =
		UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
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
	InitializeFragmentNormal(i);

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

	float4 albedoTex = tex2D(_MainTex, i.uv.xy);
	albedoTex.a *= _Tint.a;

	float3 albedo = albedoTex.rgb * _Tint.rgb;
	albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
	);
	float4 val = UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		CreateLight(i), CreateIndirectLight(i, viewDir)
	);
	val.a = albedoTex.a * _CutoutVal;
	return val;
}

#endif