Shader "DELTation/Custom/Toon Shader (Fur)"
{
    Properties
    {
        [MainTexture]
        _BaseMap ("Texture", 2D) = "white" {}
        [MainColor]
        _BaseColor ("Tint", Color) = (1.0, 1.0, 1.0)
        _ShadowTint ("Shadow Tint", Color) = (0.0, 0.0, 0.0, 1.0)
        [Toggle(_PURE_SHADOW_COLOR)]
        _PureShadowColor ("Pure Shadow Color", Float) = 0
        
        [Toggle(_RAMP_MAP)]
        _UseRampMap("Use Ramp Texture", Float) = 0
        [NoScaleOffset]
        _RampMap ("Ramp Texture", 2D) = "white" {}
        [Toggle(_RAMP_TRIPLE)] _RampTriple ("Triple Ramp", Float) = 0
        _Ramp0 ("Ramp Threshold 0", Range(-1, 1)) = 0
        _Ramp1 ("Ramp Threshold 1", Range(-1, 1)) = 0.5
        _RampSmoothness ("Ramp Smoothness", Range(0, 2)) = 0.005
        
        [NoScaleOffset]
        _BumpMap("Normal Map", 2D) = "bump" {}
        
        [Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (0.0, 0.0, 0.0, 0.0)
        
        [Toggle(_FRESNEL)] _Fresnel ("Rim", Float) = 0
        _FresnelThickness ("Rim Thickness", Range(0, 1)) = 0.45
        _FresnelSmoothness ("Rim Smoothness", Range(0, 1)) = 0.1
        [HDR] _FresnelColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Toggle(_SPECULAR)] _Specular ("Specular", Float) = 0
        [Toggle(_ANISO_SPECULAR)] _AnisoSpecular("Anisotropic Specular", Float) = 0
        _SpecularThreshold ("Specular Threshold", Range(0, 1)) = 0.8
        _SpecularExponent ("Specular Exponent", Range(0, 1000)) = 200
        _SpecularSmoothness ("Specular Smoothness", Range(0, 1)) = 0.025
        [HDR] _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        
        [Toggle(_FOG)] _Fog ("Fog", Float) = 1
        [Toggle(_ADDITIONAL_LIGHTS_ENABLED)] _AdditionalLights ("Additonal Lights", Float) = 1
        [Toggle(_ADDITIONAL_LIGHTS_SPECULAR)] _AdditionalLightsSpecular ("Additonal Lights Specular", Float) = 0
        [Toggle(_ENVIRONMENT_LIGHTING_ENABLED)] _EnvironmentLightingEnabled ("Environment Lighting", Float) = 1
        [Toggle(_SHADOW_MASK)] _ShadowMask ("Baked Shadows", Float) = 0
        [Toggle(_VERTEX_COLOR)] _VertexColor ("Vertex Color", Float) = 0
        
        [Slider(0, 1)]
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        // Blending state
        [Toggle] _ZWrite("Z Write", Float) = 1.0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Float) = 0
        
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [Toggle] _AlphaClip("Alpha Clipping", Float) = 0.0
        
        // Editmode props
        [HideInInspector] _QueueOffset("Queue Offset", Float) = 0.0
        
        [Toggle(_REFLECTIONS)] _Reflections("Reflections", Float) = 0.0
        [Toggle(_REFLECTION_PROBES)] _ReflectionProbes("Reflection Probes", Float) = 0.0
        _ReflectionSmoothness ("Smoothness", Range(0, 1)) = 0.5
        _ReflectionBlend ("Blend", Range(0, 1)) = 0.5
        
        // Custom Properties Begin
        [CustomProperty] _FurLength ("Fur Length", Range(0,1)) = 0.1
        [CustomProperty] _FurStep ("Fur Step", Range(0,1)) = 0.1
        [CustomProperty] _FurNoise ("Fur Noise", 2D) = "white" {}
        [NoScaleOffset] [CustomProperty] _FurMask ("Fur Mask", 2D) = "white" {}
        // Custom Properties End
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _FOG
            #pragma shader_feature_local _VERTEX_COLOR
            #pragma shader_feature_local _ADDITIONAL_LIGHTS_ENABLED
            #pragma shader_feature_local _SPECULAR
            #pragma shader_feature_local _ANISO_SPECULAR
            #pragma shader_feature_local _ADDITIONAL_LIGHTS_SPECULAR
            #pragma shader_feature_local _ENVIRONMENT_LIGHTING_ENABLED
            #pragma shader_feature_local _SHADOW_MASK
            
            #pragma shader_feature_local_fragment _FRESNEL
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _RAMP_TRIPLE
            #pragma shader_feature_local_fragment _RAMP_MAP
            #pragma shader_feature_local_fragment _PURE_SHADOW_COLOR

            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            #pragma shader_feature_local_fragment _REFLECTIONS
            #pragma shader_feature_local_fragment _REFLECTION_PROBES
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            
            
            // Unity
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

			#pragma multi_compile_instancing
            

            #if defined(_ADDITIONAL_LIGHTS) && defined(_ADDITIONAL_LIGHTS_ENABLED) 
            #define TOON_ADDITIONAL_LIGHTS
            #endif

            #if defined(_ADDITIONAL_LIGHTS_VERTEX) && defined(_ADDITIONAL_LIGHTS_ENABLED)
            #define TOON_ADDITIONAL_LIGHTS_VERTEX
            #endif

            #if defined(_ADDITIONAL_LIGHTS_SPECULAR) && defined(_SPECULAR)
            #define TOON_ADDITIONAL_LIGHTS_SPECULAR
            #endif

            #define TOON_SHADER_FORWARD_PASS

            // TOON_SHADER_HOOK_INPUT_BUFFER
             #define TOON_SHADER_HOOK_INPUT_BUFFER \
half _FurLength; \
half _FurStep; \
float4 _FurNoise_ST;  \

            // TOON_SHADER_HOOK_INPUT_TEXTURES
             #define TOON_SHADER_HOOK_INPUT_TEXTURES \
TEXTURE2D(_FurNoise); \
SAMPLER(sampler_FurNoise); \
TEXTURE2D(_FurMask);  \
SAMPLER(sampler_FurMask); \

            // TOON_SHADER_CUSTOM_INSTANCING_BUFFER
            // TOON_SHADER_CUSTOM_CBUFFER

            // TOON_SHADER_HOOK_APP_DATA

            // TOON_SHADER_HOOK_VERTEX_INPUT
#if defined(TOON_SHADER_FORWARD_PASS)
             #define TOON_SHADER_HOOK_VERTEX_INPUT \
const half fur_length = _FurLength; \
const half fur_step = _FurStep; \
input.positionOS.xyz += input.normalOS * fur_length * fur_step; \

#endif
            // TOON_SHADER_HOOK_FRAGMENT_ALBEDO
             #define TOON_SHADER_HOOK_FRAGMENT_ALBEDO \
const half mask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, input.uv).r; \
clip(mask - 1); \
const float4 fur_noise_st = _FurNoise_ST; \
const half2 noise_uv = apply_tiling_offset(input.uv, fur_noise_st); \
albedo.a *= SAMPLE_TEXTURE2D(_FurNoise, sampler_FurNoise, noise_uv).r;  \

            
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderForwardPass_AppData.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderForwardPass.hlsl"
            
            ENDHLSL
        }
                
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing

            #define TOON_SHADER_SHADOW_CASTER_PASS

            // TOON_SHADER_HOOK_INPUT_BUFFER
             #define TOON_SHADER_HOOK_INPUT_BUFFER \
half _FurLength; \
half _FurStep; \
float4 _FurNoise_ST;  \

            // TOON_SHADER_HOOK_INPUT_TEXTURES
             #define TOON_SHADER_HOOK_INPUT_TEXTURES \
TEXTURE2D(_FurNoise); \
SAMPLER(sampler_FurNoise); \
TEXTURE2D(_FurMask);  \
SAMPLER(sampler_FurMask); \

            // TOON_SHADER_CUSTOM_INSTANCING_BUFFER
            // TOON_SHADER_CUSTOM_CBUFFER

            // TOON_SHADER_HOOK_APP_DATA

            // TOON_SHADER_HOOK_VERTEX_INPUT
#if defined(TOON_SHADER_FORWARD_PASS)
             #define TOON_SHADER_HOOK_VERTEX_INPUT \
const half fur_length = _FurLength; \
const half fur_step = _FurStep; \
input.positionOS.xyz += input.normalOS * fur_length * fur_step; \

#endif
            // TOON_SHADER_HOOK_FRAGMENT_ALBEDO
             #define TOON_SHADER_HOOK_FRAGMENT_ALBEDO \
const half mask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, input.uv).r; \
clip(mask - 1); \
const float4 fur_noise_st = _FurNoise_ST; \
const half2 noise_uv = apply_tiling_offset(input.uv, fur_noise_st); \
albedo.a *= SAMPLE_TEXTURE2D(_FurNoise, sampler_FurNoise, noise_uv).r;  \


            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderShadowCasterPass.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM

            #pragma vertex MetaPassVertex
            #pragma fragment MetaPassFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _VERTEX_COLOR
            #pragma shader_feature_local _ADDITIONAL_LIGHTS_ENABLED
            #pragma shader_feature_local _SPECULAR
            #pragma shader_feature_local _ANISO_SPECULAR
            #pragma shader_feature_local _ADDITIONAL_LIGHTS_SPECULAR
            #pragma shader_feature_local _ENVIRONMENT_LIGHTING_ENABLED

            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _FRESNEL
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _RAMP_TRIPLE
            #pragma multi_compile_local_fragment _ _RAMP_MAP _PURE_SHADOW_COLOR

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            // TOON_SHADER_HOOK_INPUT_BUFFER
             #define TOON_SHADER_HOOK_INPUT_BUFFER \
half _FurLength; \
half _FurStep; \
float4 _FurNoise_ST;  \

            // TOON_SHADER_HOOK_INPUT_TEXTURES
             #define TOON_SHADER_HOOK_INPUT_TEXTURES \
TEXTURE2D(_FurNoise); \
SAMPLER(sampler_FurNoise); \
TEXTURE2D(_FurMask);  \
SAMPLER(sampler_FurMask); \

            // TOON_SHADER_CUSTOM_INSTANCING_BUFFER
            // TOON_SHADER_CUSTOM_CBUFFER

            // TOON_SHADER_HOOK_APP_DATA

            // TOON_SHADER_HOOK_VERTEX_INPUT
#if defined(TOON_SHADER_FORWARD_PASS)
             #define TOON_SHADER_HOOK_VERTEX_INPUT \
const half fur_length = _FurLength; \
const half fur_step = _FurStep; \
input.positionOS.xyz += input.normalOS * fur_length * fur_step; \

#endif
            // TOON_SHADER_HOOK_FRAGMENT_ALBEDO
             #define TOON_SHADER_HOOK_FRAGMENT_ALBEDO \
const half mask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, input.uv).r; \
clip(mask - 1); \
const float4 fur_noise_st = _FurNoise_ST; \
const half2 noise_uv = apply_tiling_offset(input.uv, fur_noise_st); \
albedo.a *= SAMPLE_TEXTURE2D(_FurNoise, sampler_FurNoise, noise_uv).r;  \


            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderMetaPass.hlsl"

            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            
            #pragma target 2.0

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing

            #define TOON_SHADER_DEPTH_ONLY_PASS

            // TOON_SHADER_HOOK_INPUT_BUFFER
             #define TOON_SHADER_HOOK_INPUT_BUFFER \
half _FurLength; \
half _FurStep; \
float4 _FurNoise_ST;  \

            // TOON_SHADER_HOOK_INPUT_TEXTURES
             #define TOON_SHADER_HOOK_INPUT_TEXTURES \
TEXTURE2D(_FurNoise); \
SAMPLER(sampler_FurNoise); \
TEXTURE2D(_FurMask);  \
SAMPLER(sampler_FurMask); \

            // TOON_SHADER_CUSTOM_INSTANCING_BUFFER
            // TOON_SHADER_CUSTOM_CBUFFER

            // TOON_SHADER_HOOK_APP_DATA

            // TOON_SHADER_HOOK_VERTEX_INPUT
#if defined(TOON_SHADER_FORWARD_PASS)
             #define TOON_SHADER_HOOK_VERTEX_INPUT \
const half fur_length = _FurLength; \
const half fur_step = _FurStep; \
input.positionOS.xyz += input.normalOS * fur_length * fur_step; \

#endif
            // TOON_SHADER_HOOK_FRAGMENT_ALBEDO
             #define TOON_SHADER_HOOK_FRAGMENT_ALBEDO \
const half mask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, input.uv).r; \
clip(mask - 1); \
const float4 fur_noise_st = _FurNoise_ST; \
const half2 noise_uv = apply_tiling_offset(input.uv, fur_noise_st); \
albedo.a *= SAMPLE_TEXTURE2D(_FurNoise, sampler_FurNoise, noise_uv).r;  \


            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderDepthOnlyPass.hlsl"
            
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            #pragma multi_compile_instancing

            #define TOON_SHADER_DEPTH_NORMALS_PASS

            // TOON_SHADER_HOOK_INPUT_BUFFER
             #define TOON_SHADER_HOOK_INPUT_BUFFER \
half _FurLength; \
half _FurStep; \
float4 _FurNoise_ST;  \

            // TOON_SHADER_HOOK_INPUT_TEXTURES
             #define TOON_SHADER_HOOK_INPUT_TEXTURES \
TEXTURE2D(_FurNoise); \
SAMPLER(sampler_FurNoise); \
TEXTURE2D(_FurMask);  \
SAMPLER(sampler_FurMask); \

            // TOON_SHADER_CUSTOM_INSTANCING_BUFFER
            // TOON_SHADER_CUSTOM_CBUFFER

            // TOON_SHADER_HOOK_APP_DATA

            // TOON_SHADER_HOOK_VERTEX_INPUT
#if defined(TOON_SHADER_FORWARD_PASS)
             #define TOON_SHADER_HOOK_VERTEX_INPUT \
const half fur_length = _FurLength; \
const half fur_step = _FurStep; \
input.positionOS.xyz += input.normalOS * fur_length * fur_step; \

#endif
            // TOON_SHADER_HOOK_FRAGMENT_ALBEDO
             #define TOON_SHADER_HOOK_FRAGMENT_ALBEDO \
const half mask = SAMPLE_TEXTURE2D(_FurMask, sampler_FurMask, input.uv).r; \
clip(mask - 1); \
const float4 fur_noise_st = _FurNoise_ST; \
const half2 noise_uv = apply_tiling_offset(input.uv, fur_noise_st); \
albedo.a *= SAMPLE_TEXTURE2D(_FurNoise, sampler_FurNoise, noise_uv).r;  \


            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderInput.hlsl"
            #include "Packages/com.deltation.toon-shader/Assets/DELTation/ToonShader/Shaders/ToonShaderDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
    
    CustomEditor "DELTation.ToonShader.Editor.ToonShaderEditor"
}