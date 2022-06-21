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

            //多光源，前向渲染，每一个光 就会多加一次 DC 非常浪费，而且重要的是 比如设计Unity同时
            //只能渲染 4 个光源，那么Unity依据光的优先级和光强弱来决定渲染哪个光
            //运动的物体可能突然对某个光失去渲染，所以很突兀
            //为了解决问题，我们使用顶点光照而不是逐像素光照，Unity将依据关键字VERTEXLIGHT_ON 来判断有没有开启
            //Unity处理的顶点光照只能给 ForwardBase 用，且只能给点光源使用
            #pragma multi_compile _ VERTEXLIGHT_ON

            #pragma vertex vert
            #pragma fragment frag2

            #define FORWARD_BASE_PASS

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

            //定义shader变体 这个 #pragma multi_compile 会让本PASS变成多个版本
            //以下的定义是：直射光的时候使用对应版本的Pass
            //点光源的时候，使用对应版本的Pass
            //因此使用了这个多编译变体命令之后，就不需要手动写死定义 POINT 了
            //新加入！ 聚光灯：SPOT
            // #pragma multi_compile DIRECTIONAL POINT SPOT
 
            //新改变：聚光灯可以使用 cookie 遮罩，非常方便
            //实际上，点光源也可以使用（不过你得提供给点光源一个 CUBE 贴图，类似天空盒的贴图
            //如果使用了点光源COOKIE遮罩，那么代码需要定制特定的宏
            //（因为衰减计算公式 UNITY_LIGHT_ATTENUATION 会不同（他需要计算CUBE采样得到的 alpha 值
            #pragma multi_compile_fwdadd
            //上面这个命令会产生 5 个变体 属于是囊括了所有的多光源处理了
            //POINT DIRECTIONAL SPOT POINT_COOKIE DIRECTIONAL_COOKIE
            //DIRECTIONAL_COOKIE是聚光灯cookie的意思

            #pragma vertex vert
            #pragma fragment frag

            // #define POINT
            
            #include "MyLight.cginc"

            ENDCG
        }
    }
}