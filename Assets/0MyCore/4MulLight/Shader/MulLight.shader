Shader "Unlit/BRDFLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SpecularColor ("SpecularColor", Color) = (1, 1, 1, 1)
        _Metallic ("Metallic", Range(0.0, 1.0)) = 1.0
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 1.0

    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "MyLight.cginc"

            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            ZWrite Off
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "MyLight.cginc"

            ENDCG
        }
    }
}