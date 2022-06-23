Shader "Unlit/Shadow"
{
    Properties
    {
        _MainColor ("MainColor", Color) = (1, 1, 1, 1)
        _MainTex ("MainTex", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
                float3 lightDir : TEXCOORD4;
            };

            float4 _MainColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.lightDir = WorldSpaceLightDir(v.vertex);

                return o;
            }

            fixed4 frag (v2f o) : SV_Target
            {
                float3 worldNormal = normalize(o.normal);
                float3 worldLightDir = normalize(o.lightDir);

                //采样贴图
                fixed4 diffuse = tex2D(_MainTex, o.uv.xy) * _MainColor;

                float3 worldLightColor = _LightColor0.xyz;
                // float3 lightColor = worldLightColor * (dot(worldNormal, worldLightDir) * 0.5) + 0.5;
                float3 lightColor = worldLightColor * saturate(dot(worldNormal, worldLightDir));

                return float4(diffuse.xyz * lightColor, 1);
                // return float4(lightColor, 1);

            }
            ENDCG
        }
    }
}
