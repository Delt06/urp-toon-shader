using System;
using System.Collections.Generic;
using UnityEngine;

namespace DELTation.ToonShader.Custom
{
	[CreateAssetMenu(menuName = "DELTation/Custom Toon Shader")]
	public class CustomToonShader : ScriptableObject
	{
		[HideInInspector]
		public Shader SourceShader;
		[HideInInspector]
		public Shader Shader;
		public string ShaderName;
		public List<CustomToonShaderProperty> Properties = new();
		public List<CustomToonShaderHook> Hooks = new();

		private void Reset()
		{
			if (string.IsNullOrEmpty(ShaderName))
				ShaderName = name;
		}

		[Serializable]
		public class CustomToonShaderProperty
		{
			public string Name = "_Property";
			public string DisplayName = "Property";
			public CustomToonShaderPropertyTypedValue TypedValue;
			public List<string> Attributes = new();
		}

		[Serializable]
		public class CustomToonShaderHook
		{
			public CustomToonShaderHookType Name;
			public string Condition;
			[TextArea(4, 10)]
			public string Code = string.Empty;
		}
	}
}