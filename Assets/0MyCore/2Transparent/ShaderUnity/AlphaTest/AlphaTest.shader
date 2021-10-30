Shader "Unlit/AlphaTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AlphaTest ("Alpha", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
            "Queue" = "Transparent"
        }
        LOD 100

        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float4 _MainTex_ST;
        float _AlphaTest;

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
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.w - _AlphaTest);
                return col;
            }
            ENDCG
        }
    }
}
