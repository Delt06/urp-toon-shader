using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using Debug = UnityEngine.Debug;

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
					BuildKeywordsLine("FOG_LINEAR", "_ADDITIONAL_LIGHTS", "_ADDITIONAL_LIGHTS_ENABLED",
						"_ADDITIONAL_LIGHT_SHADOWS", "_ENVIRONMENT_LIGHTING_ENABLED", "_FOG", "_FRESNEL",
						"_MAIN_LIGHT_SHADOWS_CASCADE", "_RAMP_TRIPLE", "_SHADOWS_SOFT", "_SPECULAR"
					)
				);

			if (GUILayout.Button("Analyze Toon (Lite)"))
				Analyze(
					Shader.Find("DELTation/Toon Shader (Lite)"),
					"Compiled-DELTation-Toon Shader (Lite).shader",
					"Global Keywords: FOG_LINEAR _MAIN_LIGHT_SHADOWS_CASCADE"
				);

			if (GUILayout.Button("Analyze Lit"))
				Analyze(
					Shader.Find(ShaderUtils.GetShaderPath(ShaderPathID.Lit)),
					"Compiled-Universal Render Pipeline-Lit.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT"
				);

			if (GUILayout.Button("Analyze Simple Lit"))
				Analyze(
					Shader.Find(ShaderUtils.GetShaderPath(ShaderPathID.SimpleLit)),
					"Compiled-Universal Render Pipeline-Simple Lit.shader",
					"Global Keywords: FOG_LINEAR _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT"
				);

			if (GUILayout.Button("Analyze TCP2 Hybrid"))
				Analyze(
					Shader.Find("Toony Colors Pro 2/Hybrid Shader"),
					"Compiled-Toony Colors Pro 2-Hybrid Shader.shader",
					"Global Keywords: FOG_LINEAR TCP2_HYBRID_URP _ADDITIONAL_LIGHTS _ADDITIONAL_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _SHADOWS_SOFT"
				);
		}

		private string BuildKeywordsLine(params string[] keywords) => "Keywords: " + string.Join(" ", keywords);

		private static void Analyze(Shader shader, string compiledShaderName, string keywords)
		{
			OpenCompiledShader(shader);

			var allText = File.ReadAllLines(Path.Combine(Application.dataPath, "..", "Temp", compiledShaderName));

			for (var index = 0; index < allText.Length; index++)
			{
				var thisLine = allText[index];

				if (thisLine.Trim() !=
				    keywords)
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

				Debug.Log(keywords);
				return;
			}

			Debug.LogWarning("Did not find a shader variant with keywords:");
			Debug.LogWarning(keywords);
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

		[MenuItem("Window/Analysis/Shader Benchmark")]
		public static void Open() => CreateInstance<BenchmarkWindow>().Show();
	}
}