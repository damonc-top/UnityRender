Shader "Self-Illum/dly"
{
	Properties
	{
		_MainColor("Main Color",Color) = (1,1,1,1)
		_MainTex("Main Texture",2D) = "white"{}
	_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(0,255)) = 20.0
		_FlowTex("Flow Tex (A)",2D) = "black"{}
	_FlowColor("Flow Color (RGBA)",Color) = (1,1,1,1)
		_FlowIdleTime("FlowInternal",Range(0,10)) = 1.0
		_FlowDuring("FlowDuring",Range(0,10)) = 1.0
		_FlowMaskTex("FlowMasking (A)",2D) = "white"{}
	_FlowDirection("FlowDirection",Int) = 0
		_FlowBeginTime("Flow Begin Time",Float) = 0
		FlowFactor("FlashFactor", Vector) = (0, -0.5, 1, 0.05)

		//发光颜色 || Rim Color  
		_RimColor("【发光颜色】Rim Color", Color) = (0.5,0.5,0.5,1)
		//发光强度 ||Rim Power  
		_RimPower("【发光强度】Rim Power", Range(0.0, 36)) = 0.1
		//发光强度系数 || Rim Intensity Factor  
		_RimIntensity("【发光强度系数】Rim Intensity", Range(0.0, 100)) = 3
	}

		SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }

		Pass
	{
		Tags{ "LightMode" = "ForwardBase" }
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM

#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"
#include "Lighting.cginc"

		sampler2D _MainTex;     //颜色贴图
	half4 _MainTex_ST;      //颜色UV 缩放和偏移
	fixed3 _MainColor;      //漫反射颜色
	fixed3 _Specular;       //高光颜色
	fixed _Gloss;           //高光度
	sampler2D _FlowTex;     //数据流图片
	fixed4 _FlowColor;      //数据流颜色叠加
	half4 _FlowTex_ST;      //数据流贴图UV的缩放和偏移
	fixed _FlowIdleTime;    //流动动画间歇时间
	fixed _FlowDuring;      //流动动画播放时间
	sampler2D _FlowMaskTex; //流动遮罩
	fixed _FlowDirection;   //流动方向
	float _FlowBeginTime;   //流动效果开始的时间
	fixed3 _Color1;
	fixed3 _Color2;
	fixed4 FlowFactor;

	struct a2v
	{
		half4 pos: POSITION;
		half3 normal :NORMAL;
		half4 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		half4 position : SV_POSITION;
		half2 uv : TEXCOORD0;
		half3 worldNormal : TEXCOORD1;
		half3 worldPos : TEXCOORD2;
		half2 flowUV : TEXCOORD3;
	};

	v2f vert(a2v i)
	{
		v2f v;
		v.position = UnityObjectToClipPos(i.pos);
		v.uv = i.texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
		v.worldNormal = mul(unity_ObjectToWorld,i.normal);
		v.worldPos = mul(unity_ObjectToWorld,i.pos);
		v.flowUV = i.texcoord * _FlowTex_ST.xy + _FlowTex_ST.zw;
		return v;
	}

	//uv - vert的uv坐标
	//scale - 贴图缩放
	//idleTime - 每次循环开始后多长时间，开始流动
	//loopTime - 单次流动时间
	fixed4 getFlowColor(v2f v,int scale,fixed idleTime,fixed loopTime)
	{
		half2 flashuv = v.worldPos.xy * FlowFactor.zw + FlowFactor.xy * _Time.y;
		return tex2D(_FlowTex, flashuv);

		//当前运行时间
		half flowTime_ = _Time.y - _FlowBeginTime;

		//上一次循环开始，到本次循环开始的时间间隔
		half internal = idleTime + loopTime;

		//当前循环执行时间
		half curLoopTime = fmod(flowTime_,internal);

		//每次开始流动之前，有个停止间隔，检测是否可以流动了
		if (curLoopTime > idleTime)
		{
			//已经流动时间
			half actionTime = curLoopTime - idleTime;

			//流动进度百分比
			half actionPercentage = actionTime / loopTime;

			half length = 1.0 / scale;

			//从下往上流动
			//计算方式：设：y = ax + b，其中y为下边界值，x为流动进度
			//根据我们要求可以，x=0时y=-length；x=1时y=1；带入解方程
			half bottomBorder = actionPercentage * (1 + length) - length;
			half topBorder = bottomBorder + length;

			//从上往下流动
			//求解方法与上面类似
			if (_FlowDirection < 0)
			{
				topBorder = (-1 - length) * actionPercentage + 1 + length;
				bottomBorder = topBorder - length;
			}

			if (v.uv.y < topBorder && v.uv.y > bottomBorder)
			{
				FlowFactor.y = _FlowDirection;
				half2 flashuv = v.worldPos.xy * FlowFactor.zw + FlowFactor.xy * curLoopTime;
				return tex2D(_FlowTex, flashuv);
			}
		}

		return fixed4(1,1,1,0);
	}

	fixed4 frag(v2f v) :SV_Target
	{
		//计算漫反射系数
		fixed3 albedo = tex2D(_MainTex,v.uv) * _MainColor;

	//计算环境光
	fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;


	fixed3 worldNormal = normalize(v.worldNormal);                              //世界坐标的法线方向
	fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(v.worldPos));      //世界坐标的光照方向
	fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(v.worldPos));        //世界坐标的视角方向

																				//计算漫反射颜色,采用Half-Lambert模型
	fixed3 lightColor = _LightColor0.rgb;
	fixed3 diffuse = lightColor * albedo * max(0,0.5*dot(worldNormal,worldLightDir) + 0.5);

	//计算高光,采用Blinn-Phone高光模型
	fixed3 halfDir = normalize(worldViewDir + worldLightDir);
	fixed3 specColor = _Specular * lightColor * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

	//叠加流动贴图                
	fixed4 flowColor = getFlowColor(v,_FlowTex_ST.y,_FlowIdleTime,_FlowDuring);
	fixed4 flowMaskColor = tex2D(_FlowMaskTex,v.uv);

	//与遮罩贴图进行混合，只显示遮罩贴图不透明的部分
	flowColor.a = flowMaskColor.a * flowColor.a * _FlowColor.a;

	fixed3 finalDiffuse = lerp(diffuse,_FlowColor,flowColor.a);






	//return fixed4(ambient + finalColor + specColor,1);
	return fixed4(ambient + finalDiffuse + specColor, 1);
	}

		ENDCG
	}
	}
		Fallback "Diffuse"
}
