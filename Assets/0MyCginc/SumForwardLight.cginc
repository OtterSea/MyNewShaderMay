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

//计算盒投影：当反射的物体不是单纯的球体，而是平面的时候，就需要考虑盒投影的问题：
//这是一套公式
//盒投影确实会带来额外的消耗，我们对是否开启盒投影是可选的，在 ReflectionProbe 投影探针里有一个BoxProjection
//开关，Unity将开关的信息存储在立方体贴图位置的第四分量w中，如果w分量大于0，我们就启用盒投影，用if在代码解决
float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition,
    float3 boxMin, float3 boxMax)
{
    //这部分的原理有空研究，总之目的明确：就是要找出
    // boxMin -= position;
    // boxMax -= position;
    // float x = (direction.x > 0 ? boxMax.x : boxMin.x) / direction.x;
    // float y = (direction.y > 0 ? boxMax.y : boxMin.y) / direction.y;
    // float z = (direction.z > 0 ? boxMax.z : boxMin.z) / direction.z;
    // float scalar = min(min(x, y), z);
    //盒投影的w分量代表是否在组件里勾选了BoxProjection选项

    //仅当当前环境支持盒投影的时候才能使用盒投影，使用关键字：
    #if UNITY_SPECCUBE_BOX_PROJECTION
    //这个关键字是为了解决：使用了if语句，Unity编译为OpenGL或Direct3D的时候
    //未必会包含if语句 所以写入此关键字请求分支，虽然不建议太多分支，但是还行
        UNITY_BRANCH
        if(cubemapPosition.w > 0)
        {
            float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
            float scalar = min(min(factors.x, factors.y), factors.z);
            direction = direction * scalar + (position - cubemapPosition);
        }
    #endif
    return direction;

    //盒投影是有Unity官方函数的：UnityStandardUtils的BoxProjectedCubemapDirection函数，做的内容一模一样
    //但是他会归一化反射方向函数（这是没必要的，因为CUBE采样的时候，自动归一化采样向量）所以我们少写一个归一化
    //省下了性能。
}

//创建间接灯光 用于BRDF函数
UnityIndirect CreateIndirectLight (base_interpolator i, float3 viewDir) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
        //如果把反射考虑进去的话
        // indirectLight.specular = float3(1, 0, 0);
        //应该对天空盒进行采样(反射周围环境，天空盒是最直接的)，在Unity拥有默认的参数指向当前的天空盒：unity_SpecCube0
        //CUBE贴图采样在不同平台上会有所不同，因此用UNITY_SAMPLE_TEXCUBE来处理差异

        //直接采样颜色 float3 的话，结果非常地亮 因为立方体贴图包含了HDR颜色十七包含的来年高度值可以超过1
        //我们必须将HDR（高动态范围）颜色转换为RGB
        // float3 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.normal);
        // indirectLight.specular = envSample;

        //因此应该使用 UnityCG 的 DecodeHDR函数 输入HDR，转化为RGB
        // float4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, i.normal);
        // indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);

        //用法线采样非常地方便，但是有个问题，采样的结果并不取决于视线方向，结果就像球体画上了颜色，这并不是反射
        //真正的反射是光线打到物体上，物体进行反射，刚好射进眼睛里的光就是看到的
        //进行反推，所以使用reflect：把 viewDir 看成是入射光，让他进行reflect看能采样到什么东西
        float3 reflectDir = reflect(-viewDir, i.normal);
        // float4 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
        // indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);

        //我们更希望获得物品周围的环境而不是天空盒，采样周围的环境得使用 反射探针
        //GameObject/Light/Reflection Probe添加
        //关于反射探针：他存在一个CUBE范围，进入范围的任何物体如果想使用 SpecCUBE 的话，必定会使用反射探针里烘焙的CUBE
        //调节好范围后，点击下方的Bake，将开启渲染，烘焙非常耗时，实时渲染一般耗不起（可以开启每隔一段时间就实时渲染）
        //CUBE贴图自带mipmapLOD层级，但我们可以用下面的函数主动采样LOD层级，而不是自动采样，通过Smoothness来控制粗糙度
        //利用粗糙度来控制采样的结果是否模糊

        // float roughness = 1 - _Smoothness;
        // //实际上，粗糙度和mipmap层级的关系不是线性的，他们之间的公式是：
        // roughness *= 1.7 - 0.7 * roughness;
        // float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,
        //     reflectDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
        // indirectLight.specular = DecodeHDR(envSample, unity_SpecCube0_HDR);

        //当然了 老规矩，上面这些代码Unity内置肯定有相应的函数进行处理（包括对不同平台的处理）
        Unity_GlossyEnvironmentData envData;
        envData.roughness = 1 - _Smoothness;
        // envData.reflUVW = reflectDir;        //使用反射向量是不对的 得考虑盒投影
        envData.reflUVW = BoxProjection(reflectDir, i.worldPos, unity_SpecCube0_ProbePosition,
            unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);

        //在实际的应用场景中，一旦物体离开了反射探针盒，就会立刻丢失反射CUBE，回归默认天空盒，这就非常突兀
        //为了解决突兀，一般是在反射探针盒周围再放其他的反射探针，但是这样一来，在两个盒子的边界进行过度的时候
        //就会立即转换，非常突兀，为了解决问题，我们得在两个探针（如果有）之间进行插值：
        // indirectLight.specular = Unity_GlossyEnvironment(
        //     UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
        // );
        //上面是不考虑探针插值直接采样 unity_SpecCube0 的结果。
        //unity会把第二个反射探针盒存放在：unity_SpecCube1里，相关参数只需要把0改成1即可
        float3 probe0 = Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), 
            unity_SpecCube0_HDR, envData);
        //上面已经计算出第一个反射探针数据
        //重新计算envData的反射采样角度，用 SpecCube1 来计算
        envData.reflUVW = BoxProjection(reflectDir, i.worldPos, unity_SpecCube1_ProbePosition,
            unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
        //UNITY_PASS_TEXCUBE_SAMPLER 这个宏是用在当不存在 SpecCube1 的时候就不进行采样而是采样 0 
        //此时两个探针盒子应该重叠，并且组件也可以设置探针盒子的混合模式和优先级
        //当物体在两个探针之间移动的时候，对应的探针组件也会出现提示正在混合，如果想要无敌的混合效果
        //那就在两个盒子之间放第三个探针盒，然后继续过渡
        //任何探针盒都可以设置与天空盒进行混合，只需要将组件里的 ReflectionProbes 模式从 Blend Probes 改为：
        //Blend Probes and Skybox 即可，这时就会在物体超出盒，去到没有另一个盒的地方的时候，进行天空盒混合
        //还有其他模式：off不用探针，使用天空盒
        //Simple禁用混合，只执行自己的探针或天空盒
        // float3 probe1 = Unity_GlossyEnvironment(
        //     UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
        //     unity_SpecCube0_HDR, envData
        // );
        //Unity会自动为我们计算，两个探针盒应该使用哪个插值，将此插值优势数据存放在 BoxMin.w 中
        //不使用插值，则 =1，如果使用，就设置为更小的数值里（所以Cube0应该填在第二个参数里
        // indirectLight.specular = lerp(probe1, probe0, unity_SpecCube0_BoxMin.w);

        //上面这种操作，太浪费性能了，万一有些电脑无法承受怎么办，所以必须优化：
        //当电脑无法使用混合探针的时候，禁用混合：
        #if UNITY_SPECCUBE_BLENDING
            //利用插值器：interpolator也就是 Min的w分量，仅当物体在边界（w分量!=1的时候，才使用插值lerp
            //否则就不使用，要不然每天都lerp会非常要命
            float interpolator = unity_SpecCube0_BoxMin.w;
            UNITY_BRANCH
            if(interpolator < 0.99999)
            {
                float3 probe1 = Unity_GlossyEnvironment(
                    UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1, unity_SpecCube0),
                    unity_SpecCube0_HDR, envData
                );
                indirectLight.specular = lerp(probe1, probe0, interpolator);
            }
            else
            {
                indirectLight.specular = probe0;
            }
        #else
            indirectLight.specular = probe0;
        #endif
        //类似的思想，盒投影也有一样的考虑，是否支持盒投影才使用盒投影
        //UNITY_SPECCUBE_BOX_PROJECTION
        //UNITY_SPECCUBE_BLENDING
        //这两个关键字，是在编辑器依据目标平台而定义的，1表示定义 0表示不定义 着色器版本小于3.0时，
        //则UnityStandardConfig会把他们设置为0
	#endif

    //tips:我想让镜子反射别的镜子，让镜子反射自己，怎么做：
    //只需要把镜子本身设置为static，这样在bake的时候就会把镜子考虑进去，但是这么做的时候，是黑色的？
    //因为在探针反射自己的时候，他自身的环境贴图还没生成呢，所以是黑色的
    //Unity默认环境贴图里不包含反射，但是可以改：Lighting Setting - Environment - 有个Reflection Bounces模块
    //默认情况下是1，我们设置为2，即可看到自己
    //原理：设置为2，意味着Unity会正常进行第一遍环境贴图渲染，然后再进行第二遍（为了反射自己）
    //设置为多少就意味着渲染多少次，最多支持5次，但是不会有人想在运行的时候执行这种东西

    //反射总结：完美的镜子，不存在，利用反射探针，可以很方便实现反射的功能，但是并不是实现反射的唯一方法
    //（我记得Shader入门书里就有另一种方法），但是反射探针还是有他的通用性，当然也有局限性
    //了解他的用途和缺点，
    //之后会介绍 屏幕空间反射（延迟渲染里介绍）

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
		CreateLight(i), CreateIndirectLight(i, viewDir)
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
