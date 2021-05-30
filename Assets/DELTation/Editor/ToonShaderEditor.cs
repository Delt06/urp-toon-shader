﻿using UnityEditor;
using UnityEngine;

namespace DELTation.Editor
{
	public class ToonShaderEditor : ShaderGUI
	{
		private GUIStyle _headerStyle;

		public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			var material = materialEditor.target as Material;
			if (material == null) return;

			_headerStyle = new GUIStyle
			{
				normal = new GUIStyleState
				{
					textColor = Color.white,
				},
				richText = true,
			};

			DrawColorProperties(materialEditor, properties);
			Label("Ramp");
			DrawRampProperties(materialEditor, properties, material);
			Label("Emission");
			DrawEmissionProperties(materialEditor, properties, material);
			Label("Rim");
			DrawRimProperties(materialEditor, properties, material);
			Label("Specular");
			DrawSpecularProperties(materialEditor, properties, material);
			Label("Misc");
			DrawMiscProperties(materialEditor, properties, material);
		}

		private void Label(string text)
		{
			GUILayout.Label($"<b>{text}</b>", _headerStyle);
		}

		private static void DrawColorProperties(MaterialEditor materialEditor, MaterialProperty[] properties)
		{
			DrawProperty(materialEditor, properties, "_BaseMap");
			DrawProperty(materialEditor, properties, "_BaseColor");
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
				DrawProperty(materialEditor, properties, "_ShadowTint");
				DrawProperty(materialEditor, properties, "_RampTriple");
				DrawProperty(materialEditor, properties, "_Ramp0");

				if (material.IsKeywordEnabled("_RAMP_TRIPLE"))
					DrawProperty(materialEditor, properties, "_Ramp1");

				DrawProperty(materialEditor, properties, "_RampSmoothness");
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
			DrawProperty(materialEditor, properties, "_Fog");

			DrawProperty(materialEditor, properties, "_AdditionalLights");
			if (material.IsKeywordEnabled("_ADDITIONAL_LIGHTS_ENABLED"))
				DrawProperty(materialEditor, properties, "_AdditionalLightsMultiplier");

			DrawProperty(materialEditor, properties, "_EnvironmentLightingEnabled");
			if (material.IsKeywordEnabled("_ENVIRONMENT_LIGHTING_ENABLED"))
				DrawProperty(materialEditor, properties, "_EnvironmentLightingMultiplier");
		}

		private static void DrawProperty(MaterialEditor materialEditor, MaterialProperty[] properties, string name)
		{
			var property = FindProperty(name, properties);
			materialEditor.ShaderProperty(property, property.displayName);
		}
	}
}