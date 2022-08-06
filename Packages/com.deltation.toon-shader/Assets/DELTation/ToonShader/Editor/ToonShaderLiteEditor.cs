using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;

namespace DELTation.ToonShader.Editor
{
	[UsedImplicitly]
	public class ToonShaderLiteEditor : ToonShaderEditorBase
	{
		protected override void DrawProperties(MaterialEditor materialEditor, MaterialProperty[] properties,
			Material material)
		{
			var ctx = new MaterialEditorContext(materialEditor, properties, material);

			Foldout(ctx, "Color", DrawAlbedo, true);
			RampFoldout(ctx, DrawRampProperties);
			MiscFoldout(ctx, DrawMisc);
		}

		private static void DrawRampProperties(in MaterialEditorContext ctx)
		{
			DrawShadowTintProperty(ctx);
			DrawRampProperty0(ctx);
			DrawRampSmoothnessProperty(ctx);
		}

		private static void DrawMisc(in MaterialEditorContext ctx)
		{
			DrawProperty(ctx, "_VertexLit");
			DrawProperty(ctx, "_ReceiveShadows");
			DrawFogProperty(ctx);
			DrawVertexColorProperty(ctx);
		}
	}
}