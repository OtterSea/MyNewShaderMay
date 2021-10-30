//兰伯特光照
Shader "Unlit/Lambert"
{
    Properties
    {
        _MainColor("MainColor", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }
        LOD 100

        //属性
        CGINCLUDE
            #include "UnityCG.cginc"

            fixed4 _MainColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
            };

        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.lightDir = WorldSpaceLightDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldNormal = normalize(i.normal);
                float3 worldLightDir = normalize(i.lightDir);
                fixed4 diffuse = dot(worldNormal, worldLightDir) * _MainColor;

                fixed4 col = diffuse;
                //fixed4 col = fixed4(_WorldSpaceLightPos0.xyz, 1.0);

                return col;
            }

            ENDCG
        }
    }
}
