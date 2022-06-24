
//这个Shader是对MulLight的一个翻新和备份，可以视为是完整版的
//我已经完全理解了的多光照的shader

Shader "Unlit/FinishMulLight"
{
    Properties
    {
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("MainTex", 2D) = "white" {}
        [Gamma] _Metallic("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1
    }
    SubShader
    {
        CGINCLUDE

        float4 _Tint;
        sampler2D _MainTex;
        float4 _MainTex_ST;
        float _Metallic;
        float _Smoothness;

        #pragma target 3.0

        ENDCG

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            
            #pragma vertex ForwardVert
            #pragma fragment ForwardFrag

            #pragma multi_compile _ VERTEXLIGHT_ON
			#define FORWARD_BASE_PASS

            #include "../../../0MyCginc/SumForwardLight.cginc"

            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }

            //使用正确的颜色混合模式，避免Add的颜色覆盖Base
            Blend One One
            //这是一种优化，Add模式不需要写入深度，仅添加颜色
            ZWrite Off
            CGPROGRAM

            #pragma vertex ForwardVert
            #pragma fragment ForwardFrag

            #pragma multi_compile_fwdadd

            #include "../../../0MyCginc/SumForwardLight.cginc"

            ENDCG
        }
    }
}
