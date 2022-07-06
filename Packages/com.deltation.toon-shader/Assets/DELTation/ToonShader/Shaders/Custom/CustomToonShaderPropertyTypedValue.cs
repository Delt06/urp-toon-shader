using System;
using System.Globalization;
using UnityEngine;

namespace DELTation.ToonShader.Custom
{
	[Serializable]
	public struct CustomToonShaderPropertyTypedValue
	{
		public CustomToonShaderPropertyType Type;
		public int IntegerValue;
		public float FloatValue;
		public CustomToonShaderDefaultTexture TextureValue;
		public float RangeMinValue;
		public float RangeMaxValue;
		public float RangeValue;
		public Vector4 VectorValue;
		public Color ColorValue;

		public string GetTypeString() =>
			Type switch
			{
				CustomToonShaderPropertyType.Integer => "Integer",
				CustomToonShaderPropertyType.Float => "Float",
				CustomToonShaderPropertyType.Texture2D => "2D",
				CustomToonShaderPropertyType.Texture2DArray => "2DArray",
				CustomToonShaderPropertyType.Texture3D => "3D",
				CustomToonShaderPropertyType.Cubemap => "Cube",
				CustomToonShaderPropertyType.CubemapArray => "CubeArray",
				CustomToonShaderPropertyType.Color => "Color",
				CustomToonShaderPropertyType.Vector => "Vector",
				CustomToonShaderPropertyType.Range =>
					$"Range({FormatFloat(RangeMinValue)},{FormatFloat(RangeMaxValue)})",
				_ => throw new ArgumentOutOfRangeException(),
			};

		private static string FormatFloat(float value) => value.ToString(CultureInfo.InvariantCulture);

		public string GetValueString()
		{
			const string defaultTextureString = "\"\" {}";

			static string FormatAsVector4(float x, float y, float z, float w) =>
				$"({FormatFloat(x)},{FormatFloat(y)},{FormatFloat(z)},{FormatFloat(w)})";

			return Type switch
			{
				CustomToonShaderPropertyType.Integer => IntegerValue.ToString(),
				CustomToonShaderPropertyType.Float => FloatValue.ToString(CultureInfo.InvariantCulture),
				CustomToonShaderPropertyType.Texture2D => TextureValue switch
				{
					CustomToonShaderDefaultTexture.Default => defaultTextureString,
					CustomToonShaderDefaultTexture.White => "\"white\" {}",
					CustomToonShaderDefaultTexture.Black => "\"black\" {}",
					CustomToonShaderDefaultTexture.Gray => "\"gray\" {}",
					CustomToonShaderDefaultTexture.Bump => "\"bump\" {}",
					CustomToonShaderDefaultTexture.Red => "\"red\" {}",
					_ => throw new ArgumentOutOfRangeException(),
				},
				CustomToonShaderPropertyType.Texture2DArray => defaultTextureString,
				CustomToonShaderPropertyType.Texture3D => defaultTextureString,
				CustomToonShaderPropertyType.Cubemap => defaultTextureString,
				CustomToonShaderPropertyType.CubemapArray => defaultTextureString,
				CustomToonShaderPropertyType.Color => FormatAsVector4(ColorValue.r, ColorValue.g, ColorValue.b,
					ColorValue.a
				),
				CustomToonShaderPropertyType.Vector => FormatAsVector4(VectorValue.x, VectorValue.y, VectorValue.z,
					VectorValue.w
				),
				CustomToonShaderPropertyType.Range => FormatFloat(RangeValue),
				_ => throw new ArgumentOutOfRangeException(),
			};
		}
	}
}