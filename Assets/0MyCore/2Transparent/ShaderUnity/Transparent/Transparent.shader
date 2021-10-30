Shader "Unlit/Transparent"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Alpha ("Alpha", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
            "Queue" = "Transparent"            //正确设置渲染队列
        }
        LOD 100
        ZWrite Off                             //否则不透明物体无法在背后显示
        Cull Off                               //不要剔除更正确显示不透明

        CGINCLUDE
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        float4 _MainTex_ST;
        float _Alpha;

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

        //开启一个Pass仅进行深度写入，而不输出颜色 ColorMask是放弃输出颜色的写法
        Pass
        {
            ZWrite On
            ColorMask 0
        }

        Pass
        {
            //开启颜色混合达到正确的效果 否则会覆盖物体背后的颜色 透明度错误
            Blend SrcAlpha OneMinusSrcAlpha  
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
                col.w = _Alpha;
                //clip(col.w - _AlphaTest);
                return col;
            }
            ENDCG
        }
    }
}
