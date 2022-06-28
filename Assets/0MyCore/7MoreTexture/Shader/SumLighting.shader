Shader "Sum/MyUtilsLightingShader" {

	Properties {
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}

		[NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1

		[NoScaleOffset] _MetallicMap ("Metallic", 2D) = "white" {}
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.1

		[NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		_Emission ("Emission", Color) = (0, 0, 0)

		_DetailTex ("Detail Albedo", 2D) = "gray" {}
		[NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
		_DetailBumpScale ("Detail Bump Scale", Float) = 1
	}

	CGINCLUDE

	#define BINORMAL_PER_FRAGMENT

    float4 _Tint;
    sampler2D _MainTex, _DetailTex;
    float4 _MainTex_ST, _DetailTex_ST;

    sampler2D _NormalMap, _DetailNormalMap;
    float _BumpScale, _DetailBumpScale;

    sampler2D _MetallicMap;
    float _Metallic;
    float _Smoothness;

    sampler2D _EmissionMap;
    float3 _Emission;

    #pragma target 3.0

	ENDCG

	SubShader {

		Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP

			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma multi_compile _ VERTEXLIGHT_ON

            #pragma vertex ForwardVert
            #pragma fragment ForwardFrag

			#define FORWARD_BASE_PASS

            #include "../../../0MyCginc/SumForwardLight.cginc"


			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC

			#pragma multi_compile_fwdadd_fullshadows
			
            #pragma vertex ForwardVert
            #pragma fragment ForwardFrag

            #include "../../../0MyCginc/SumForwardLight.cginc"

			ENDCG
		}

		Pass {
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_shadowcaster

            #pragma vertex ForwardShadowVert
            #pragma fragment ForwardShadowFrag

            #include "../../../0MyCginc/SumForwardShadow.cginc"

			ENDCG
		}
	}

	CustomEditor "SumLightingShaderGUI"
}