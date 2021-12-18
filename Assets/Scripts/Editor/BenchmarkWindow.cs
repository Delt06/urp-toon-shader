using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace Editor
{
	public class BenchmarkWindow : EditorWindow
	{
		private const string IfDefFragment = "#ifdef FRAGMENT";
		private const string IfDefVertex = "#ifdef VERTEX";
		private const int PlatformMask = 1 << (int)ShaderCompilerPlatform.GLES3x;

		private const string MaliocPath =
			"C:\\Program Files\\Arm\\Arm Mobile Studio 2021.1\\mali_offline_compiler\\malioc.exe";

		private void OnGUI()
		{
			if (GUILayout.Button("Analyze Toon"))
				Analyze(
					Shader.Find("DELTation/Toon Shader"),
					"Compiled-DELTation-Toon Shader.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT",
					"Local Keywords: _ADDITIONAL_LIGHTS_ENABLED _ENVIRONMENT_LIGHTING_ENABLED _FOG _FRESNEL _RAMP_TRIPLE _SPECULAR"
				);

			if (GUILayout.Button("Analyze Lit"))
				Analyze(
					Shader.Find(ShaderUtils.GetShaderPath(ShaderPathID.Lit)),
					"Compiled-Universal Render Pipeline-Lit.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT",
					"Local Keywords: <none>"
				);

			if (GUILayout.Button("Analyze Simple Lit"))
				Analyze(
					Shader.Find(ShaderUtils.GetShaderPath(ShaderPathID.SimpleLit)),
					"Compiled-Universal Render Pipeline-Simple Lit.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT",
					"Local Keywords: <none>"
				);

			if (GUILayout.Button("Analyze TCP2 Hybrid"))
				Analyze(
					Shader.Find("Toony Colors Pro 2/Hybrid Shader"),
					"Compiled-Toony Colors Pro 2-Hybrid Shader.shader",
					"Global Keywords: FOG_LINEAR TCP2_HYBRID_URP _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT",
					"Local Keywords: TCP2_REFLECTIONS_FRESNEL TCP2_RIM_LIGHTING_LIGHTMASK TCP2_SHADOW_LIGHT_COLOR"
				);
		}

		private void Analyze(Shader shader, string compiledShaderName, string globalKeywords, string localKeywords)
		{
			OpenCompiledShader(shader);

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

		private static void OpenCompiledShader(Shader shader)
		{
			var shaderUtilType = typeof(ShaderUtil);
			var openCompiledShaderMethod =
				shaderUtilType.GetMethod("OpenCompiledShader", BindingFlags.NonPublic | BindingFlags.Static);
			const int mode = 3; // custom platform
			const bool includeAllVariants = false;
			const bool preprocessOnly = false;
			const bool stripLineDirectives = false;
			openCompiledShaderMethod?.Invoke(null, new object[]
				{
					shader,
					mode,
					PlatformMask,
					includeAllVariants,
					preprocessOnly,
					stripLineDirectives,
				}
			);
		}

		private static string FixEsVersion(string l) => l == "#version 300 es" ? l.Replace("300", "310") : l;

		private static void AnalyzeShader(string[] lines, string fileName)
		{
			var shaderFilePath = Path.Combine(Application.dataPath, "..", "Temp", fileName);
			File.WriteAllLines(shaderFilePath, lines);

			var process = new Process
			{
				StartInfo = new ProcessStartInfo
				{
					Arguments =
						$"/K \"{MaliocPath}\" {shaderFilePath}",
					FileName = "cmd.exe",
				},
			};
			process.Start();
		}

		[MenuItem("Window/Analysis/Shader Performance")]
		public static void Open() => CreateInstance<BenchmarkWindow>().Show();
	}
}