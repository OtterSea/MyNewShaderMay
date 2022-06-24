#ifndef SUM_FORWARD_SHADOW

    #define SUM_FORWARD_SHADOW
    #include "UnityCG.cginc"

    struct shadow_appdata
    {
        float4 vertex : POSITION;
        float4 normal : NORMAL;
    };

    //SHADOW_CUBE 用于点光源投影
    #if defined(SHADOW_CUBE)
        struct shadow_cube_interpolators
        {
            float4 pos : SV_POSITION;
            float3 lightVec : TEXCOORD0;
        };

        shadow_cube_interpolators ForwardShadowVert (shadow_appdata v)
        {
            shadow_cube_interpolators i;
            i.position = UnityObjectToClipPos(v.vertex);
            i.lightVec = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;

            return i;
        }

        float4 ForwardShadowFrag(shadow_cube_interpolators i) : SV_Target
        {
            float depth = length(i.lightVec) + unity_LightShadowBias.x;
            depth *= _LightPositionRange.w;
            return UnityEncodeCubeShadowDepth(depth);
        }

    #else
        //UnityApplyLinearShadowBias 存在于UnityCG用于计算阴影偏差
        //使用了UnityClipSpaceShadowCasterPos后，以下代码就是功能齐全（投射、支持阴影偏差）的投射器了
        float4 ForwardShadowVert(shadow_appdata v) : SV_POSITION
        {
            // float4 position = UnityObjectToClipPos(v.vertex);//为了支持法线偏差，使用：
            float4 position = UnityClipSpaceShadowCasterPos(v.vertex.xyz, v.normal);
            return UnityApplyLinearShadowBias(position);
        }

        float4 ForwardShadowFrag() : SV_Target
        {
            return 0;
        }
    #endif
#endif