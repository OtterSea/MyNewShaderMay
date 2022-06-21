//防止重定义include文件用
#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

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
};

Interpolators vert (appdata v)
{
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.normal = normalize(o.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    return o;
}

//计算正确的点光源方向和亮度
UnityLight CreateLight (Interpolators i)
{
    UnityLight light;
    //_WorldSpaceLightPos0.xyz在平行光的情况下是代表平行光的方向（从模型指向光源-无穷远
    //而在点光源的照射下，_WorldSpaceLightPos0.xyz代表的是点光源的光源（一个出发点）
    //所以我们需要通过减去世界坐标点来获得他的方向（模型指向光源
    float3 lightDir = _WorldSpaceLightPos0.xyz - i.worldPos;
    light.dir = normalize(lightDir);
    //计算一下点光源的衰减公式，因为Unity会无论光源的远近都会给物体进行渲染（前向渲染）
    //所以为了正确真实的效果，我们应该计算一下点光源的距离衰减公式，并*上color得到正确的颜色
    //衰减公式： 1 / d*d 其中 d 是距离点光源的距离
    //那么当 d 无限趋于0的时候，attenuation 会指数级暴涨，非常亮，导致能量不守恒，因此分母应该+1
    float attenuation = 1 / 1 + dot(lightDir, lightDir);
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
        CreateLight(i), indirectLight
    );
}