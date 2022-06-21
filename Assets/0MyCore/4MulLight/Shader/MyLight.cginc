//防止重定义include文件用
#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"   //PBS包含上述两个光照文件

#endif

sampler2D _MainTex;
float4 _MainTex_ST;
fixed4 _SpecularColor;
float _Metallic;
float _Smoothness;

struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;

    //新加入：顶点光：
    #if defined(VERTEXLIGHT_ON)
        float3 vertexLightColor : TEXCOORD3;
    #endif
};

//计算顶点光的颜色：
void ComputeVertexLightColor(inout Interpolators i)
{
    #if defined(VERTEXLIGHT_ON)
        //实际上可以使用UnityCG定义的 Shade4PointLights 函数，提供：矢量、光色、衰减因子顶点位置法线
        // i.vertexLightColor = Shade4PointLights(
        //     unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
        //     unity_LightColor[0].rgb, unity_LightColor[1].rgb,
        //     unity_LightColor[2].rgb, unity_LightColor[3].rgb,
        //     unity_4LightAtten0, i.worldPos, i.normal
        // );

        //以下是原理
        //Unity用这种方式最多支持四个顶点灯，并存储到4个float4变量中（这里没明白，具体得百度
        float3 lightPos = float3(unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x);
        float3 lightVec = lightPos - i.worldPos
        float3 lightDir = normalize(lightVec);
        float ndotl = DotClamped(i.normal, lightDir);
        //Unity提供的：unity_4LightAttenuation 有助于近似估算像素光衰减的因素
        float attenuation = 1 / (1+dot(lightVec, lightVec) * unity_4LightAtten0);
        i.vertexLightColor = unity_LightColor[0].rgb;
    #endif
}

Interpolators vert (appdata v)
{
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.normal = normalize(o.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);

    //新加入：顶点光
    ComputeVertexLightColor(o);
    return o;
}

//计算正确的点光源方向和亮度
UnityLight CreateLight (Interpolators i)
{
    UnityLight light;
    //_WorldSpaceLightPos0.xyz在平行光的情况下是代表平行光的方向（从模型指向光源-无穷远
    //而在点光源的照射下，_WorldSpaceLightPos0.xyz代表的是点光源的光源（一个出发点）
    //所以我们需要通过减去世界坐标点来获得他的方向（模型指向光源
    // float3 lightDir = _WorldSpaceLightPos0.xyz - i.worldPos;
    // light.dir = normalize(lightDir);

    //点光源和平行光的计算公式是不同的，因此我们应该用define来区分他们
    //新加入！聚光灯！聚光灯和点光源一样， worldSpaceLightPos0 代表的是光源的位置，所以：
    //新加入 聚光灯和点光源COOKIE
    #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE)
        light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #else
        light.dir = _WorldSpaceLightPos0.xyz;
    #endif


    //计算一下点光源的衰减公式，因为Unity会无论光源的远近都会给物体进行渲染（前向渲染）
    //所以为了正确真实的效果，我们应该计算一下点光源的距离衰减公式，并*上color得到正确的颜色
    //衰减公式： 1 / d*d 其中 d 是距离点光源的距离
    //那么当 d 无限趋于0的时候，attenuation 会指数级暴涨，非常亮，导致能量不守恒，因此分母应该+1
    // float attenuation = 1 / 1 + dot(light.dir, light.dir);

    //但是，上面的这个 attenuation 的计算有个问题：没有考虑光照的范围，导致一离开指定的距离，就会立即消失
    //非常突兀，所以应该让光是慢慢消退的
    //头文件 AutoLight.cginc 已经帮我们定义了公式，这样写：
    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    //这个宏定义的正确使用前提是 必须定义 POINT 表示使用了点光源，因此你应该在 #include AutoLight.cginc
    //之前 写一个 #define POINT

    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}


float4 frag (Interpolators i) : SV_Target
{
    // float3 lightDir = _WorldSpaceLightPos0.xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    //漫反射
    float3 albedo = tex2D(_MainTex, i.uv).rgb;
    
    //高光反射颜色
    // _SpecularColor

    //漫反射系数
    float oneMinusReflectivity = 1 - _Metallic;

    //光滑度
    // _Smoothness

    //世界空间法线
    //i.normal

    //视线方向
    //viewDir

    //光量UnityLight
    // UnityLight light;
    // light.color = _LightColor0.rgb;
    // light.dir = lightDir;
    // light.ndotl = DotClamped(i.normal, lightDir);

    //间接光
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;
    
    return UNITY_BRDF_PBS(
        albedo, _SpecularColor,
        oneMinusReflectivity, _Smoothness,
        i.normal, viewDir,
        CreateLight(i), indirectLight//CreateIndirectLight(i)
    );

    //使用球谐函数：
    // float3 shColor = ShadeSH9(float4(i.normal, 1));
    // return float4(shColor, 1);
}

//新加入 如果使用了点光源：
UnityIndirect CreateIndirectLight(Interpolators i)
{
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


float4 frag2 (Interpolators i) : SV_Target
{
    float3 lightDir = _WorldSpaceLightPos0.xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    //漫反射
    float3 albedo = tex2D(_MainTex, i.uv).rgb;
    float oneMinusReflectivity = 1 - _Metallic;
    
    // return float4(albedo * (dot(lightDir, i.normal)*0.5+0.5), 1);
    // return float4(albedo * DotClamped(lightDir, i.normal), 1);

    return UNITY_BRDF_PBS(
        albedo, _SpecularColor,
        oneMinusReflectivity, _Smoothness,
        i.normal, viewDir,
        CreateLight(i), CreateIndirectLight(i)
    );

    // float3 shColor = ShadeSH9(float4(i.normal, 1));
    // return float4(shColor, 1);
}