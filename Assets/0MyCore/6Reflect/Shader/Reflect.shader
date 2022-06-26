Shader "Unlit/Reflect"
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
        Tags { "RenderType"="Opaque" }

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
            #pragma multi_compile _ SHADOWS_SCREEN

			#define FORWARD_BASE_PASS

            #include "UnityCG.cginc"

            #include "../../../0MyCginc/SumForwardLight.cginc"

            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }

            Blend One One
            ZWrite Off

            CGPROGRAM

            #pragma vertex ForwardVert
            #pragma fragment ForwardFrag

            #pragma multi_compile_fwdadd_fullshadows

            #include "../../../0MyCginc/SumForwardLight.cginc"

            ENDCG
        }

        Pass
        {
            Tags { "LightMode"="ShadowCaster" }

            CGPROGRAM

            #pragma vertex ForwardShadowVert
            #pragma fragment ForwardShadowFrag

            #pragma multi_compile_shadowcaster
            
            #include "../../../0MyCginc/SumForwardShadow.cginc"

            ENDCG
        }
    }
}
