// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#if !defined(MY_LIGHTING_NORMAL_INCLUDED)
#define MY_LIGHTING_NORMAL_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"


float4 _Tint;
sampler2D _MainTex, _DetailTex;
float4 _MainTex_ST, _DetailTex_ST;

sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

float _Metallic;
float _Smoothness;

struct VertexData {
	float4 position : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

struct Interpolators {
	float4 position : SV_POSITION;
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
};

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
	i.position = UnityObjectToClipPos(v.position);
	i.worldPos = mul(unity_ObjectToWorld, v.position);
	i.normal = UnityObjectToWorldNormal(v.normal);

#if defined(BINORMAL_PER_FRAGMENT)
	i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
#else
	i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
	i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
#endif

	i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
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

	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

UnityIndirect CreateIndirectLight(Interpolators i) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

#if defined(VERTEXLIGHT_ON)
	indirectLight.diffuse = i.vertexLightColor;
#endif

#if defined(FORWARD_BASE_PASS)
	indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
#endif

	return indirectLight;
}
/*
//1 uv有限差分
void FiniteCalculateNormal1(Interpolators i) {
	float2 delta = float2(_HeightMap_TexelSize.x, 0);//u轴
	float u1 = tex2D(_HeightMap, i.uv);//模型uv在高度图采样
	float u2 = tex2D(_HeightMap, i.uv + delta);//二次采样

	delta = float2(0, _HeightMap_TexelSize.y);//v轴
	float v1 = tex2D(_HeightMap, i.uv);//模型uv在高度图采样
	float v2 = tex2D(_HeightMap, i.uv + delta);//二次采样

	i.normal = normalize(float3(u1 - u2, 1, v1 - v2));
}
//2 中心差分
void CetralCalculateNormal(Interpolators i) {
	float2 du = float2(_HeightMap_TexelSize.x * 0.5, 0);
	float u1 = tex2D(_HeightMap, i.uv - du);
	float u2 = tex2D(_HeightMap, i.uv + du);
	//	float3 tu = float3(1, u2 - u1, 0);

	float2 dv = float2(0, _HeightMap_TexelSize.y * 0.5);
	float v1 = tex2D(_HeightMap, i.uv - dv);
	float v2 = tex2D(_HeightMap, i.uv + dv);
	//	float3 tv = float3(0, v2 - v1, 1);

	//	i.normal = cross(tv, tu);
	i.normal = float3(u1 - u2, 1, v1 - v2);
	i.normal = normalize(i.normal);
}

//decode dxt5
void DecodeDXT5NormalMap(Interpolators i) {
	
	//i.normal.xy = tex2D(_NormalMap, i.uv).wy * 2 - 1;
	//i.normal.xy *= _BumpScale;
	//i.normal.z = sqrt(1 - dot(i.normal.xy, i.normal.xy));
	//完全相等
	i.normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv), _BumpScale);
	i.normal = i.normal.xzy;
}
*/
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

	float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
	albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;

	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
	);

	return UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		CreateLight(i), CreateIndirectLight(i)
	);
}

#endif