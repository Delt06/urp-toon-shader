using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using DELTation.ToonShader.Custom;
using UnityEditor;
using UnityEngine;

namespace DELTation.ToonShader.Editor.Custom
{
	[CustomEditor(typeof(CustomToonShader))]
	public class CustomToonShaderEditor : UnityEditor.Editor
	{
		public override void OnInspectorGUI()
		{
			base.OnInspectorGUI();

			var customToonShader = (CustomToonShader)target;

			EditorGUI.BeginDisabledGroup(true);
			EditorGUILayout.ObjectField(nameof(customToonShader.Shader), customToonShader.Shader, typeof(Shader), false
			);
			EditorGUI.EndDisabledGroup();


			if (GUILayout.Button("Generate"))
				GenerateShaderFile(customToonShader);
		}

		private void GenerateShaderFile(CustomToonShader customToonShader)
		{
			if (string.IsNullOrWhiteSpace(customToonShader.ShaderName))
			{
				Debug.LogError("Shader name is empty.");
				return;
			}

			var path = AssetDatabase.GetAssetPath(customToonShader);
			var assetName = Path.GetFileNameWithoutExtension(path);
			var directoryName = Path.GetDirectoryName(path)!;

			var sourceShaderCode =
				GenerateShaderSource(customToonShader, customToonShader.ShaderName);
			var shaderAssetPath = customToonShader.Shader != null
				? AssetDatabase.GetAssetPath(customToonShader.Shader)
				: Path.Combine(directoryName, assetName + ".shader");
			File.WriteAllText(Path.GetFullPath(shaderAssetPath), sourceShaderCode);
			AssetDatabase.ImportAsset(shaderAssetPath);

			var newShader = AssetDatabase.LoadAssetAtPath<Shader>(shaderAssetPath);
			customToonShader.Shader = newShader;
			EditorUtility.SetDirty(newShader);
			EditorUtility.SetDirty(customToonShader);
			AssetDatabase.SaveAssets();
		}

		private static string GenerateShaderSource(CustomToonShader customToonShader, string shaderName)
		{
			var lines = GetSourceShaderCode(customToonShader.SourceShader);
			SetShaderName(lines, shaderName);

			AddProperties(customToonShader, ref lines);

			var sourceShaderCode = string.Join(Environment.NewLine, lines);
			return sourceShaderCode;
		}

		private static void SetShaderName(string[] lines, string shaderName)
		{
			lines[0] = $"Shader \"DELTation/Custom/{shaderName}\"";
		}

		private static void AddProperties(CustomToonShader customToonShader, ref string[] lines)
		{
			var linesList = lines.ToList();
			var indexOfStart = linesList.FindIndex(line => line.Contains("// Custom Properties Begin"));
			if (indexOfStart == -1) return;
			var indexOfEnd = linesList.FindIndex(indexOfStart, line => line.Contains("// Custom Properties End"));
			if (indexOfEnd == -1) return;

			var propertyIndent = new string(' ', 8);
			var propertyLines = new List<string>();

			foreach (var shaderProperty in customToonShader.Properties)
			{
				propertyLines.Add(
					$"{propertyIndent}{shaderProperty.Name} (\"{shaderProperty.DisplayName}\", {shaderProperty.Type}) = {shaderProperty.DefaultValue}"
				);
			}

			linesList.InsertRange(indexOfStart + 1, propertyLines);
			lines = linesList.ToArray();
		}

		private static string[] GetSourceShaderCode(Shader sourceShader)
		{
			var path = AssetDatabase.GetAssetPath(sourceShader);
			var fullPath = Path.GetFullPath(path);
			return File.ReadAllLines(fullPath);
		}
	}
}