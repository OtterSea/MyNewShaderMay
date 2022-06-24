
//为了使用Unity官方的宏定义，应该对一些变量的名字进行一个约定：
//vertex2frag 的 SV_POSITION 变量，也就是裁剪空间的顶点应该命名为 pos
//顶点着色器获得appdata变量，应该命名为 v

Shader "Unlit/Shadow"
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

            //为什么中间有个下划线？意思是定义两个变体 一个是没有关键字的变体 _
            //另一个是带有 VERTEXLIGHT_ON 关键字的变体，Unity会根据当前材质的环境
            //（有无平行光，有无点光源，仅当在无平行光，存在点光源的时候，才使用 VERTEXLIGHT_ON
            #pragma multi_compile _ VERTEXLIGHT_ON

            //改造，我们已拥有阴影投射器的功能，现在将此多光源着色器改造为可接受阴影的着色器
            //注意： SHADOWS_SCREEN 只是用在 Base 光照（主光照平行光）里的阴影定义而已
            //多个阴影（除了主灯光平行光之外的阴影定义得去 Add 里处理
            #pragma multi_compile _ SHADOWS_SCREEN

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

            //这个定义并不支持多阴影
            // #pragma multi_compile_fwdadd
            //使用此定义支持多个阴影（除了主光源平行光之外的其他点光平行光投影灯等
            #pragma multi_compile_fwdadd_fullshadows

            #include "../../../0MyCginc/SumForwardLight.cginc"

            ENDCG
        }

        //开始写入阴影！
        //可以理解为 ShadowCaster 这个Pass 是用来告诉Unity启用阴影纹理渲染处理的
        Pass
        {
            Tags { "LightMode"="ShadowCaster" }

            CGPROGRAM

            #pragma vertex ForwardShadowVert
            #pragma fragment ForwardShadowFrag

            //处理点光源投射阴影
            #pragma multi_compile_shadowcaster
            
            #include "../../../0MyCginc/SumForwardShadow.cginc"

            ENDCG
        }
    }
}
