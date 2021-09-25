//兰伯特光照
Shader "Unlit/CartoonLambert"
{
    Properties
    {
        _MainColor ("MainColor", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //属性
        CGINCLUDE
            #include "UnityCG.cginc"

            fixed4 _MainColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
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
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldNormal = normalize(i.normal);
                float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed lightValue = (dot(worldNormal, worldLightDir) * 0.5 + 0.5);
                //fixed lightValue = dot(worldNormal, worldLightDir);
                fixed3 diffuse = tex2D(_MainTex, fixed2(lightValue, 0.5)).rgb * _MainColor.rgb;

                fixed4 col = fixed4(diffuse, 1);
                return col;
            }

            ENDCG
        }
    }
}
