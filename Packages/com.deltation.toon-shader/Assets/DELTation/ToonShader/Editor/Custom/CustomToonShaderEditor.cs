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
		private static readonly string HookIndent = new(' ', 12);
		private static readonly string PropertyIndent = new(' ', 8);

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
			var lines = GetSourceShaderCode(customToonShader.SourceShader).ToList();
			SetShaderName(lines, shaderName);

			AddProperties(customToonShader, lines);
			AddHooks(customToonShader, lines);

			var sourceShaderCode = string.Join(Environment.NewLine, lines);
			return sourceShaderCode;
		}

		private static void SetShaderName(List<string> lines, string shaderName)
		{
			lines[0] = $"Shader \"DELTation/Custom/{shaderName}\"";
		}

		private static void AddProperties(CustomToonShader customToonShader, List<string> lines)
		{
			var indexOfStart = lines.FindIndex(line => line.Contains("// Custom Properties Begin"));
			if (indexOfStart == -1) return;
			var indexOfEnd = lines.FindIndex(indexOfStart, line => line.Contains("// Custom Properties End"));
			if (indexOfEnd == -1) return;

			var propertyLines = new List<string>();

			foreach (var shaderProperty in customToonShader.Properties)
			{
				var attributes = string.Join(' ',
					shaderProperty.Attributes.Append("CustomProperty").Select(a => $"[{a}]")
				);
				propertyLines.Add(
					$"{PropertyIndent}{attributes} {shaderProperty.Name} (\"{shaderProperty.DisplayName}\", {shaderProperty.Type}) = {shaderProperty.DefaultValue}"
				);
			}

			lines.InsertRange(indexOfStart + 1, propertyLines);
		}

		private static void AddHooks(CustomToonShader customToonShader, List<string> lines)
		{
			foreach (var hook in customToonShader.Hooks)
			{
				var hookComment = $"// {hook.Name.ToString()}";
				var found = false;

				for (var index = 0; index < lines.Count; index++)
				{
					var line = lines[index];
					if (!line.Contains(hookComment)) continue;

					found = true;
					var hookLines = new List<string> { $"{HookIndent} #define {hook.Name} \\" };

					var hookCodeLines = hook.Code.Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
					foreach (var hookCodeLine in hookCodeLines)
					{
						hookLines.Add(hookCodeLine + " \\");
					}

					hookLines.Add(string.Empty);
					lines.InsertRange(index + 1, hookLines);
				}

				if (!found)
					Debug.LogWarning($"Hook comments for {hook.Name} not found.");
			}
		}

		private static string[] GetSourceShaderCode(Shader sourceShader)
		{
			var path = AssetDatabase.GetAssetPath(sourceShader);
			var fullPath = Path.GetFullPath(path);
			return File.ReadAllLines(fullPath);
		}
	}
}