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
// appdata.vertex = UnityObjectToClipPos(v.vertex);
// appdata.normal = UnityObjectToWorldNormal(v.normal);
// appdata.viewDir = WorldSpaceViewDir(v.vertex);
// o.worldPos = mul(unity_ObjectToWorld, v.vertex);

//兰伯特光照公式（效果不是很好，一般少用
//dot(归一化的法线， 归一化的光向量) * 光的颜色

//半兰伯特光照公式
//(dot(归一化的法线， 归一化的光向量) * 0.5 + 0.5) * 光的颜色

//uv偏移计算函数
// v2f v;
// v.uv.xy = TRANSFORM_TEX(appdata.texcoord, _MainTex);
//只需要传入 模型的uv纹理， 以及对应贴图即可 注意依然需要定义对应贴图的ST
// float4 _MainTex_ST;

//图片采样函数tex2D(只能在片元着色器使用)
// fixed4 col = tex2D(_MainTex, v.uv.xy);
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
// appdata.lightDir = WorldSpaceLightDir(v.vertex);

//获得第一个平行光的颜色（ForwardBase）
// float3 light = _LightColor0.xyz;





///////////////////////////////
////////// 法线计算部分 ////////
///////////////////////////////
// UnpackNormal
