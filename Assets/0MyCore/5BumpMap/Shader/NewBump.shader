Shader "Unlit/BumpTexture"
{
    ///
    ///非常失败 他使用的法线贴图似乎和我之前用的不一样，不过这不重要，他的文章从
    ///高度贴图开始优化，还是能学到东西的，但是我们要写法线贴图还是用自己之前学到的来写吧
    ///收获一个可以看所有mesh的法线和切线的脚本
    ///请去我之前学到的法线贴图的写法那里了解，并做一个总结，总结出一个方便的函数计算法线
    ///
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _MainColor ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)

        _NormalTex ("Normal Texture", 2D) = "white" {}
        _BumpScale ("Bump Scale", float) = 1.0
        // _Gloss ("Gloss", Range(1.0, 256.0)) = 10.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGINCLUDE

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        sampler2D _MainTex;
        float4 _MainTex_ST;
        fixed4 _MainColor;

        sampler2D _NormalTex;
        float4 _NormalTex_ST;
        float _BumpScale;
        // float _Gloss;

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 position : SV_POSITION;
            float4 uv : TEXCOORD0;
            float3 normal : TEXCOORD1;
            float4 tangent : TEXCOORD2;
            float3 worldPos : TEXCOORD3;

            #if defined(VERTEXLIGHT_ON)
                float3 vertexLightColor : TEXCOORD4;
            #endif
        };

        ENDCG

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            void ComputeNormal(inout v2f v)
            {
                //使用 UnpackScaleNormal(来自：) 可以让Unity自动依据编码方式来计算法线
                v.normal = UnpackScaleNormal(tex2D(_NormalTex, v.uv.xy), _BumpScale);
                v.normal = v.normal.xzy;
                v.normal = normalize(v.normal);
            }

            v2f vert (appdata a)
            {
                v2f v;              
                v.position = UnityObjectToClipPos(a.vertex);
                v.worldPos = mul(unity_ObjectToWorld, a.vertex);
                v.normal = UnityObjectToWorldNormal(a.normal);
                v.tangent = float4(UnityObjectToWorldDir(a.tangent.xyz), a.tangent.w);
                v.uv.xy = TRANSFORM_TEX(a.uv, _MainTex);
                v.uv.zw = TRANSFORM_TEX(a.uv, _NormalTex);
                return v;
            }

            fixed4 frag (v2f v) : SV_Target
            {
                ComputeNormal(v);
                fixed3 albedo = tex2D(_MainTex, v.uv.xy) * _MainColor;

                //漫反射
                fixed3 diffuse = albedo * (dot(v.normal, v.lightDir) * 0.5 + 0.5);

                fixed4 col = fixed4(diffuse, 1.0);
                // fixed4 col = fixed4(1.0, 1.0, 1.0, 1.0);
                return col;
            }
            ENDCG
        }
    }
}
