Shader "DELTation/Inverted Hull Outline"
{
	Properties
	{
		_Color ("Color", Color) = (0, 0, 0, 0)
		_Scale ("Scale", Range(0, 10)) = 0.05
		_DepthOffsetFactor ("Offset Factor", Float) = 0
		_DepthOffsetUnits ("Offset Units", Float) = 0
		[Toggle(CLIP_SPACE)]
		_ClipSpace ("Clip Space", Float) = 1
	}
	SubShader
	{
		Cull Front ZWrite On ZTest LEqual
		Offset [_DepthOffsetFactor], [_DepthOffsetUnits]

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature_vertex CLIP_SPACE
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct appdata
			{
				float3 vertex : POSITION;
				float3 normal : NORMAL;
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _Color;
			half _Scale;
			CBUFFER_END

			float4 vert (const appdata v) : SV_POSITION
			{
#ifdef CLIP_SPACE
				float4 vertex_hclip = TransformObjectToHClip(v.vertex);
				float3 normal_hclip = TransformWorldToHClipDir(TransformObjectToWorldNormal(v.normal, true));
				return vertex_hclip + float4(normal_hclip * _Scale, 0);
#else
				return TransformObjectToHClip(v.vertex + normalize(v.normal) * _Scale);
#endif
			}

			half4 frag() : SV_Target
			{
				return _Color;
			}
			ENDHLSL
		}
	}
}