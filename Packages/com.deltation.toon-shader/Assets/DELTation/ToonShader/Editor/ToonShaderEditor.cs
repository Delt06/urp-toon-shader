using UnityEditor;
using UnityEngine;

namespace DELTation.ToonShader.Editor
{
	public class ToonShaderEditor : ToonShaderEditorBase
	{
		protected override void DrawProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawColorProperties(materialEditor, properties);
			RampLabel();
			DrawRampProperties(materialEditor, properties, material);
			Label("Emission");
			DrawEmissionProperties(materialEditor, properties, material);
			Label("Rim");
			DrawRimProperties(materialEditor, properties, material);
			Label("Specular");
			DrawSpecularProperties(materialEditor, properties, material);
			MiscLabel();
			DrawMiscProperties(materialEditor, properties, material);
		}

		private static void DrawRampProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawProperty(materialEditor, properties, "_UseRampMap");

			if (material.IsKeywordEnabled("_RAMP_MAP"))
			{
				DrawProperty(materialEditor, properties, "_RampMap");
			}
			else
			{
				DrawShadowTintProperty(materialEditor, properties);
				DrawProperty(materialEditor, properties, "_RampTriple");
				DrawRampProperty0(materialEditor, properties);

				if (material.IsKeywordEnabled("_RAMP_TRIPLE"))
					DrawProperty(materialEditor, properties, "_Ramp1");

				DrawRampSmoothnessProperty(materialEditor, properties);
			}
		}

		private static void DrawEmissionProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			EditorGUILayout.BeginHorizontal();
			DrawProperty(materialEditor, properties, "_Emission");

			if (material.IsKeywordEnabled("_EMISSION"))
				DrawProperty(materialEditor, properties, "_EmissionColor");

			EditorGUILayout.EndHorizontal();
		}

		private static void DrawRimProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawProperty(materialEditor, properties, "_Fresnel");

			if (material.IsKeywordEnabled("_FRESNEL"))
			{
				DrawProperty(materialEditor, properties, "_FresnelColor");
				DrawProperty(materialEditor, properties, "_FresnelThickness");
				DrawProperty(materialEditor, properties, "_FresnelSmoothness");
			}
		}

		private static void DrawSpecularProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawProperty(materialEditor, properties, "_Specular");

			if (material.IsKeywordEnabled("_SPECULAR"))
			{
				DrawProperty(materialEditor, properties, "_SpecularColor");
				DrawProperty(materialEditor, properties, "_SpecularThreshold");
				DrawProperty(materialEditor, properties, "_SpecularExponent");
				DrawProperty(materialEditor, properties, "_SpecularSmoothness");
			}
		}

		private static void DrawMiscProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			DrawFogProperty(materialEditor, properties);

			DrawProperty(materialEditor, properties, "_AdditionalLights");
			if (material.IsKeywordEnabled("_ADDITIONAL_LIGHTS_ENABLED"))
				DrawProperty(materialEditor, properties, "_AdditionalLightsMultiplier");

			DrawProperty(materialEditor, properties, "_EnvironmentLightingEnabled");
			if (material.IsKeywordEnabled("_ENVIRONMENT_LIGHTING_ENABLED"))
				DrawProperty(materialEditor, properties, "_EnvironmentLightingMultiplier");
		}
	}
}