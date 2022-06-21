//这是一个顶点、片元模板shader，拥有基本的功能
Shader "Unlit/ModelShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _Int ("Int", Int) = 1
        _Float ("Float", Float) = 1.5
        _Range ("Range", Range(0.0, 5.0)) = 3.0
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Vector ("Vector", Vector) = (1, 2, 3, 4)       
        _2D ("2D", 2D) = "" {}
        _Cube ("Cube", Cube) = "white" {}
        _3D ("3D", 3D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //属性
        CGINCLUDE
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            int _Int;
            float _Float;
            float _Range;
            fixed4 _Color;
            float4 _Vector;
            
            sampler2D _2D;
            float4 _2D_ST;
            samplerCUBE _Cube;
            sampler3D _3D;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD0;
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
                o.normal = v.normal;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }

            ENDCG
        }
    }
    Fallback Off        //"VertexLit"
}
