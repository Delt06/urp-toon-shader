using System;
using System.IO;
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
			var sourceShaderCodeLines = GetSourceShaderCode(customToonShader.SourceShader);
			sourceShaderCodeLines[0] = $"Shader \"DELTation/Custom/{shaderName}\"";
			var sourceShaderCode = string.Join(Environment.NewLine, sourceShaderCodeLines);
			return sourceShaderCode;
		}

		private static string[] GetSourceShaderCode(Shader sourceShader)
		{
			var path = AssetDatabase.GetAssetPath(sourceShader);
			var fullPath = Path.GetFullPath(path);
			return File.ReadAllLines(fullPath);
		}
	}
}