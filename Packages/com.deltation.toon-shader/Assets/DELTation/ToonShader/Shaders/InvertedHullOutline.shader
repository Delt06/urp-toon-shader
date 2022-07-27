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
		[Toggle(CUSTOM_NORMALS)]
		_CustomNormals ("Custom Normals (UV2)", Float) = 0
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
			#pragma shader_feature_vertex CUSTOM_NORMALS
			#pragma shader_feature_vertex FALLBACK_TO_DEFAULT_NORMALS

			#pragma multi_compile_fog
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct appdata
			{
				float3 vertex : POSITION;
				#ifdef CUSTOM_NORMALS
				float3 normal : TEXCOORD2;
				#else
				float3 normal : NORMAL;
				#endif
			};

			struct v2f
			{
				float4 position_cs : SV_POSITION;
				float fog_factor : FOG_FACTOR;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float _Scale;
			CBUFFER_END

			v2f vert (const appdata input)
			{
				v2f output;
				
#ifdef CLIP_SPACE
				float4 vertex_hclip = TransformObjectToHClip(input.vertex);
				float3 normal_hclip = TransformWorldToHClipDir(TransformObjectToWorldNormal(input.normal, true));
				output.position_cs = vertex_hclip + float4(normal_hclip * _Scale, 0);
#else
				output.position_cs = TransformObjectToHClip(input.vertex + normalize(input.normal) * _Scale);
#endif

				output.fog_factor = ComputeFogFactor(output.position_cs.z);

				return output;

			}

			float4 frag(const v2f input) : SV_Target
			{
				float4 output = _Color;
				output.rgb = MixFog(output.rgb, input.fog_factor);
				return output;
			}
			ENDHLSL
		}
	}
}