Shader "Unlit/NormalTexture"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _MainColor ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _NormalTex ("Normal Texture", 2D) = "white" {}
        _BumpScale ("Bump Scale", float) = 1.0
        _Gloss ("Gloss", Range(1.0, 256.0)) = 10.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        sampler2D _MainTex;
        float4 _MainTex_ST;
        fixed4 _MainColor;
        sampler2D _NormalTex;
        float4 _NormalTex_ST;
        float _BumpScale;
        float _Gloss;

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float4 uv : TEXCOORD0;
            float3 lightDir : TEXCOORD1;
            float4 TtoW0 : TEXCOORD2;
            float4 TtoW1 : TEXCOORD3;
            float4 TtoW2 : TEXCOORD4;
        };

        ENDCG

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _NormalTex);
                o.lightDir = WorldSpaceLightDir(v.vertex);

                float3 worldViewDir = ObjSpaceViewDir(v.vertex);
                //计算TtoW
                float3 worldNormal = UnityObjectToWorldNormal(v.vertex);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldViewDir.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldViewDir.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldViewDir.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldLightDir = normalize(i.lightDir);
                float3 worldViewDir = normalize(float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w));
                
                //计算法线
                float3 worldNormal = UnpackNormal(tex2D(_NormalTex, i.uv.zw)).xyz;
                worldNormal.xy *= _BumpScale;
                worldNormal.z = sqrt(1.0 - saturate(dot(worldNormal.xy, worldNormal.xy)));  //
                worldNormal = normalize(float3(dot(i.TtoW0.xyz, worldNormal), 
                                        dot(i.TtoW1.xyz, worldNormal),
                                        dot(i.TtoW2.xyz, worldNormal)));

                fixed3 albedo = tex2D(_MainTex, i.uv.xy) * _MainColor;

                //漫反射
                fixed3 diffuse = albedo * (dot(worldNormal, worldLightDir) * 0.5 + 0.5);
                //fixed3 diffuse = albedo * max(0, dot(worldNormal, worldLightDir));

                //高光
                float3 halfDir = normalize(worldLightDir + worldViewDir);
                fixed3 specular = pow(max(0, dot(halfDir, worldNormal)), _Gloss) * _LightColor0.rgb;

                fixed4 col = fixed4(diffuse + specular, 1.0);          //specular
                return col;
            }
            ENDCG
        }
    }
}
