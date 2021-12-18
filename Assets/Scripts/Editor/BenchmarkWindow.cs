using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace Editor
{
	public class BenchmarkWindow : EditorWindow
	{
		private const string IfDefFragment = "#ifdef FRAGMENT";
		private const string IfDefVertex = "#ifdef VERTEX";

		private void OnGUI()
		{
			if (GUILayout.Button("Analyze Toon"))
				Analyze("Compiled-DELTation-Toon Shader.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT",
					"Local Keywords: _ADDITIONAL_LIGHTS_ENABLED _ENVIRONMENT_LIGHTING_ENABLED _FOG _FRESNEL _RAMP_TRIPLE _SPECULAR"
				);

			if (GUILayout.Button("Analyze Lit"))
			{
				Analyze("Compiled-Universal Render Pipeline-Lit.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT",
					"Local Keywords: <none>"
				);
			}
			
			if (GUILayout.Button("Analyze Simple Lit"))
			{
				Analyze("Compiled-Universal Render Pipeline-Simple Lit.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT",
					"Local Keywords: <none>"
				);
			}
		}

		private void Analyze(string compiledShaderName, string globalKeywords, string localKeywords)
		{
			var allText = File.ReadAllLines(Path.Combine(Application.dataPath, "..", "Temp", compiledShaderName));

			for (var index = 0; index < allText.Length - 1; index++)
			{
				var thisLine = allText[index];
				var nextLine = allText[index + 1];

				if (thisLine.Trim() !=
				    globalKeywords)
					continue;
				if (nextLine.Trim() !=
				    localKeywords)
					continue;

				var vertexIndex = Array.IndexOf(allText, IfDefVertex, index);
				var fragmentIndex = Array.IndexOf(allText, IfDefFragment, index);

				var vertexShaderLines = allText.Skip(vertexIndex + 1)
					.TakeUntilFirstUnbalancedIf()
					.Select(FixEsVersion)
					.ToArray();
				AnalyzeShader(vertexShaderLines, "temp_shader.vert");

				var fragmentShaderLines = allText.Skip(fragmentIndex + 1)
					.TakeUntilFirstUnbalancedIf()
					.Select(FixEsVersion)
					.ToArray();
				AnalyzeShader(fragmentShaderLines, "temp_shader.frag");

				break;
			}
		}

		private static string FixEsVersion(string l) => l == "#version 300 es" ? l.Replace("300", "310") : l;

		private void AnalyzeShader(string[] lines, string fileName)
		{
			var shaderFilePath = Path.Combine(Application.dataPath, "..", "Temp", fileName);
			File.WriteAllLines(shaderFilePath, lines);

			var process = new Process
			{
				StartInfo = new ProcessStartInfo
				{
					Arguments =
						$"/K \"C:\\Program Files\\Arm\\Arm Mobile Studio 2021.1\\mali_offline_compiler\\malioc.exe\" {shaderFilePath}",
					FileName = "cmd.exe",
				},
			};
			process.Start();
		}

		[MenuItem("Window/Analysis/Shader Performance")]
		public static void Open() => CreateInstance<BenchmarkWindow>().Show();
	}
}