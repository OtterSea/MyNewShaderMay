Shader "Unlit/BlinnPhone"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss ("Gloss", Range(1.0, 256.0)) = 10.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        CGINCLUDE

        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        fixed4 _DiffuseColor;
        float _Gloss;

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float3 normal : TEXCOORD0;
            float3 lightDir : TEXCOORD1;
            float3 viewDir : TEXCOORD2;
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
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.lightDir = WorldSpaceLightDir(v.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldNormal = normalize(i.normal);
                float3 worldLightDir = normalize(i.lightDir);
                float3 worldViewDir = normalize(i.viewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _DiffuseColor.rgb * (dot(worldLightDir, worldNormal) * 0.5 + 0.5);

                //float3 worldReflectDir = normalize(reflect(-worldLightDir, worldNormal));
                //fixed3 specular = _LightColor0.xyz * pow(max(0, dot(worldReflectDir, worldViewDir)), _Gloss);
                float3 halfLight = normalize(worldLightDir + worldViewDir);
                fixed3 blinnPhong = _LightColor0.xyz * pow(max(0, dot(worldNormal, halfLight)), _Gloss);

                fixed4 col = fixed4(blinnPhong + diffuse, 1.0);  //ambient +  
                return col;
            }
            ENDCG
        }
    }
}