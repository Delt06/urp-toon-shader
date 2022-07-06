using System;
using System.Collections.Generic;
using DELTation.ToonShader.Custom;
using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine.UIElements;
using TargetType = DELTation.ToonShader.Custom.CustomToonShaderPropertyTypedValue;

namespace DELTation.ToonShader.Editor.Custom
{
	[CustomPropertyDrawer(typeof(TargetType))]
	public class CustomToonShaderPropertyTypedValuePropertyDrawer : PropertyDrawer
	{
		public override VisualElement CreatePropertyGUI(SerializedProperty property)
		{
			var container = new VisualElement();

			var valueElements = new Dictionary<CustomToonShaderPropertyType, VisualElement>();


			void RefreshVisibility()
			{
				var type = (CustomToonShaderPropertyType)property.FindPropertyRelative(nameof(TargetType.Type))
					.enumValueFlag;

				foreach (var keyValuePair in valueElements)
				{
					var valueElement = valueElements[keyValuePair.Key];
					var style = valueElement.style;
					style.display = keyValuePair.Key == type ? DisplayStyle.Flex : DisplayStyle.None;
				}

				container.MarkDirtyRepaint();
			}

			RenderContainer(property, container, RefreshVisibility);

			valueElements.Clear();

			foreach (CustomToonShaderPropertyType type in Enum.GetValues(typeof(CustomToonShaderPropertyType)))
			{
				var visualElement = CreateValueElementOrDefault(property, type);
				if (visualElement == null) continue;

				valueElements.Add(type, visualElement);
				container.Add(visualElement);
			}

			RefreshVisibility();

			return container;
		}

		private static void RenderContainer(SerializedProperty property, VisualElement container, Action onChanged)
		{
			var typeProperty = property.FindPropertyRelative(nameof(TargetType.Type));
			var typeField = new PropertyField(typeProperty);
			typeField.RegisterValueChangeCallback(_ => onChanged());
			container.Add(typeField);

			var valueContainer = new VisualElement();
			container.Add(valueContainer);
		}

		private VisualElement CreateValueElementOrDefault(SerializedProperty property,
			CustomToonShaderPropertyType type)
		{
			const string valueLabel = "Value";
			return type switch
			{
				CustomToonShaderPropertyType.Integer => new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.IntegerValue)),
					valueLabel
				),
				CustomToonShaderPropertyType.Float => new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.FloatValue)),
					valueLabel
				),
				CustomToonShaderPropertyType.Texture2D => new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.TextureValue)),
					valueLabel
				),
				CustomToonShaderPropertyType.Texture2DArray => null,
				CustomToonShaderPropertyType.Texture3D => null,
				CustomToonShaderPropertyType.Cubemap => null,
				CustomToonShaderPropertyType.CubemapArray => null,
				CustomToonShaderPropertyType.Color => new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.ColorValue)),
					valueLabel
				),
				CustomToonShaderPropertyType.Vector => new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.VectorValue)),
					valueLabel
				),
				CustomToonShaderPropertyType.Range => CreateRangeValueElement(property),
				_ => throw new ArgumentOutOfRangeException(nameof(type), type, null),
			};
		}

		private static VisualElement CreateRangeValueElement(SerializedProperty property)
		{
			var rangeValueField = new VisualElement();
			rangeValueField.Add(new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.RangeMinValue)),
					"Min Value"
				)
			);
			rangeValueField.Add(new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.RangeMaxValue)),
					"Max Value"
				)
			);
			rangeValueField.Add(new PropertyField(
					property.FindPropertyRelative(nameof(TargetType.RangeValue))
				)
			);
			return rangeValueField;
		}
	}
}