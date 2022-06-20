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

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
};

v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.normal = normalize(o.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    return o;
}

float4 frag (v2f i) : SV_Target
{
    float3 lightDir = _WorldSpaceLightPos0.xyz;
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
    UnityLight light;
    light.color = _LightColor0.rgb;
    light.dir = lightDir;
    light.ndotl = DotClamped(i.normal, lightDir);

    //间接光
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;
    
    return UNITY_BRDF_PBS(
        albedo, _SpecularColor,
        oneMinusReflectivity, _Smoothness,
        i.normal, viewDir,
        light, indirectLight
    );
}