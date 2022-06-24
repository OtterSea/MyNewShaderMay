/// 这个文件封装一些用于最基础的光照（兰伯特、半兰伯特、高光等）
/// 可以不是封装，而是一种操作指引参考
/// 以及用于前向渲染的一些光照计算
/// 并阐释正确使用的话，外面应该如何定义特定的Unity宏

//传给顶点着色器结构体推荐：
//UnityCG.cginc - appdata_base: 点、法线、第一组纹理坐标
//UnityCG.cginc - appdata_tan: 点、切线、法线、第一组纹理坐标

//模型顶点必定要做的操作：从模型空间转化到裁剪空间并传递给v2f的 vertex:SV_POSITION
//模型空间法线转世界空间法线
//获得摄像机视线
//获得世界空间的模型顶点
// appdata.vertex = UnityObjectToClipPos(app.vertex);
// appdata.normal = UnityObjectToWorldNormal(app.normal);
// appdata.viewDir = WorldSpaceViewDir(app.vertex);
// float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
// o.worldPos = mul(unity_ObjectToWorld, app.vertex);

//兰伯特光照公式（效果不是很好，一般少用
//dot(归一化的法线， 归一化的光向量) * 光的颜色

//半兰伯特光照公式
//(dot(归一化的法线， 归一化的光向量) * 0.5 + 0.5) * 光的颜色

//uv偏移计算函数
// v2f app;
// app.uv.xy = TRANSFORM_TEX(appdata.texcoord, _MainTex);
//只需要传入 模型的uv纹理， 以及对应贴图即可 注意依然需要定义对应贴图的ST
// float4 _MainTex_ST;

//图片采样函数tex2D(只能在片元着色器使用)
// fixed4 col = tex2D(_MainTex, app.uv.xy);
// tex2D第一个参数是对应图片纹理，第二个参数是float2，表示要采样的目标点uv

//图片采样函数tex2Dlod（可以在顶点着色器中使用）
// o.normal = UnpackNormal(tex2Dlod(_NormalTex, float4(o.uv.zw, 0, 0))).xyz;
//但第二个参数是float4

//获得环境光的颜色：
// fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

//反射公式计算高光
//reflect 函数第一个参数是 反过来的光方向（反射公式要求），第二个参数是法线
//记住Unity官方的向量都是从模型顶点出发的
// float3 worldReflectDir = normalize(reflect(-worldLightDir, worldNormal));
//接着用 worldReflectDir 与 归一化viewDir 进行 dot 即可

//blinnPhong高光反射
//将光照方向（不用取反）和 视线方向相加得到半向量，再与法线进行点击，这是一种生活模拟算法

//高光反射需要定义float变量 _Gloss 并对高光反射变化量（即最后的dot进行：
//pow(max(0, dot(worldNormal, halfLight)), _Gloss);
//pow(max(0, dot(worldReflectDir, worldViewDir)), _Gloss);




///////////////////////////////
////////// 前向光照部分 ////////
///////////////////////////////

//基础前向光照-Tag
// Tags { "LightMode" = "ForwardBase" }

//获得第一个平行光照射到模型空间的向量
// appdata.lightDir = WorldSpaceLightDir(app.vertex);

//获得第一个平行光的颜色（ForwardBase）
// float3 light = _LightColor0.xyz;

#ifndef SUM_FORWARD_LIGHT
    #define SUM_FORWARD_LIGHT
    #include "UnityPBSLighting.cginc"
    #include "AutoLight.cginc"
#endif

// 前向光照基本光部分
// Tags { "LightMode"="ForwardBase" }
// #define VERTEXLIGHT_ON
struct base_interpolator
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;

    //AutoLight包含三个有用的宏定义：SHADOW_COORDS TRANSFER_SHADOW SHADOW_ATTENUATION
    //但是！要使用这些宏的话，你必须！把你的appdata里的顶点名叫： vertex : POSITION; 而v2f则为 pos ：SV_POSITION
    // #if defined(SHADOWS_SCREEN)
    //     float4 shadowCoordinates : TEXCOORD3;
    // #endif
    //所以上面这个定义，可以改为：
    SHADOW_COORDS(5)

    #if defined(VERTEXLIGHT_ON)
        float3 vertexLightColor : TEXCOORD4;
    #endif
};

//正确计算任何光照情况下（最多支持四点光源）用于 Base 的顶点光的颜色
//仅用于点光源，VERTEXLIGHT_ON 关键字生效的情况是 有点光源无平行光
//Shade4PointLights公式的原理：https://zhuanlan.zhihu.com/p/27842876
void ComputeVertexLightColor(inout base_interpolator i)
{
    #if defined(VERTEXLIGHT_ON)
        //这个公式的作用是正确计算用于 ForwardBase 的漫反射光照，最多接受4个光源，使得 ForwardBase 光照
        //在平行光、点光、聚光灯的照射下都能正常工作，而不是仅仅只能使用平行光
        i.vertexLightColor = Shade4PointLights(
            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
            unity_LightColor[0].rgb, unity_LightColor[1].rgb,
            unity_LightColor[2].rgb, unity_LightColor[3].rgb,
            unity_4LightAtten0, i.worldPos, i.normal
        );
    #endif
}

//通用多光照顶点着色器 可用于 Base 和 Add
//想ComputeVertexLightColor函数生效，请在Base上：
//#pragma multi_compile _ VERTEXLIGHT_ON
base_interpolator ForwardVert (appdata_base v)
{
    base_interpolator i;
    i.pos = UnityObjectToClipPos(v.vertex);
    i.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
    i.normal = UnityObjectToWorldNormal(v.normal);
    i.worldPos = mul(unity_ObjectToWorld, v.vertex);

    //进行阴影采样 阴影图是和屏幕空间相匹配的图片纹理，Unity内部已经帮我们处理好
    //我们要让我们的物体接受阴影，就应该像普通纹理采样一样：获取采样坐标，而这个坐标
    //需要通过vertex（剪辑空间坐标）来推出屏幕空间坐标
    // #if defined(SHADOWS_SCREEN)
        //推算方式：剪辑空间XY坐标[-1,1]，而屏幕空间坐标[0,1]，因此：（copy
        // 第一步是将XY减半。接下来，我们还必须偏移坐标，以使它们在屏幕的左下角为零。
        // 因为我们正在处理透视变换，所以必须偏移坐标，多少则取决于坐标距离。这时，
        // 在减半之前，偏移量等于第四齐次坐标

        // 不同API（DIrect3D、OpenGL的屏幕空间坐标系是不一样的，如果阴影错了，请反转y轴
        // i.shadowCoordinates.xy = (i.pos.xy + i.pos.w) * 0.5;
        // 试着反转y轴看看是否能适配你的屏幕空间
        // i.shadowCoordinates.xy = (float2(i.pos.x, -i.pos.y) + i.pos.w) * 0.5;
        // i.shadowCoordinates.zw = i.pos.zw;

        //以上是背后的代码原理，有空得研究下裁剪空间转屏幕空间的详细细节（之前肯定研究过）
        //Unity为我们提供了API计算屏幕空间的坐标，并且包含了对不同图形API的适配：
        // i.shadowCoordinates = ComputeScreenPos(i.pos);
    // #endif
    TRANSFER_SHADOW(i);

    ComputeVertexLightColor(i);
    return i;
}

//创建间接灯光 用于BRDF函数
UnityIndirect CreateIndirectLight (base_interpolator i) {
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

//创角Unity灯光 用于BRDF 函数
//本函数包含了对屏幕阴影纹理的采样，采样的结果将传递给attenuation，从而影响直接光照（而不是环境光
//可以通过 _ShadowMapTexture 访问屏幕阴影纹理
UnityLight CreateLight (base_interpolator i) {
	UnityLight light;

	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif

    //播放阴影时，UNITY_LIGHT_ATTENUATION的行为会不一样，需要执行采样阴影的处理
    // #if defined(SHADOWS_SCREEN)
    //     //用屏幕空间坐标的xy进行采样即可
    //     //除以 w 获得正确的坐标

    //     // float attenuation = tex2D(_ShadowMapTexture,
    //         // i.shadowCoordinates.xy / i.shadowCoordinates.w);

    //     //使用Unity定义好的宏：
    //     float attenuation = SHADOW_ATTENUATION(i);
    // #else
    //     UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    // #endif
    //说句大实话（血压上升）其实 UNITY_LIGHT_ATTENUATION 的第二个参数就是给你用来处理阴影的，
    //所以上面的 defined 根本不用写，直接这样即可：
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
	
	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

//使用BRDF公式的片段着色器 可用于Base 和 Add
//需要参数：
//_Smoothness ("Smoothness", Range(0, 1)) = 0.1
//[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
// _Tint ("Tint", Color) = (1, 1, 1, 1)
// _MainTex ("Albedo", 2D) = "white" {}
float4 ForwardFrag (base_interpolator i) : SV_Target {
	i.normal = normalize(i.normal);

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

	float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;

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

//可以考虑将上面的公式替换成自己想要的公式，未必一定要用BRDF
//要完全理解上面的代码为什么要这么写


//这里讲一下点光源阴影，这个阴影消耗特别大，因为他不是单纯的直射光，
// 平行光阴影贴图的渲染是用一个摄像头从平行光的方向拍摄场景算出的
//那么点光源就得用一个摄像头去拍摄他四周360度的环境（生成一个 Cube贴图
//仅在此上有点不同，但后续的纹理采样、阴影采样依然是一样的，所以只需要去修改阴影投射器即可
//让阴影投射器能支持CUBE阴影贴图（或者模拟CUBE贴图，正确渲染阴影纹理即可）

///////////////////////////////
////////// 法线计算部分 ////////
///////////////////////////////
// UnpackNormal
