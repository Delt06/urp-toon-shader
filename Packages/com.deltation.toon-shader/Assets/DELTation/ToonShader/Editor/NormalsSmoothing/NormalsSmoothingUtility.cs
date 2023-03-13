using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Assertions;

namespace DELTation.ToonShader.Editor.NormalsSmoothing
{
	public class NormalsSmoothingUtility : EditorWindow
	{
		public const int UvChannel = 2;
		public const float MaxSmoothingAngle = 180f;
		private float _smoothingAngle = MaxSmoothingAngle;

		private Mesh _sourceMesh;

		private void OnGUI()
		{
			_sourceMesh = (Mesh)EditorGUILayout.ObjectField("Source Mesh", _sourceMesh, typeof(Mesh), false);
			_smoothingAngle = EditorGUILayout.Slider("Smoothing Angle", _smoothingAngle, 0, MaxSmoothingAngle);

			if (_sourceMesh == null)
			{
				EditorGUILayout.HelpBox("No mesh selected", MessageType.Error);
				return;
			}

			if (!_sourceMesh.isReadable)
			{
				EditorGUILayout.HelpBox("Enable Read/Write in model import settings.", MessageType.Error);
				return;
			}

			var uvs = new List<Vector4>();
			_sourceMesh.GetUVs(UvChannel, uvs);
			if (uvs.Count > 0)
				EditorGUILayout.HelpBox($"UV{UvChannel} is busy, it will be overwritten.", MessageType.Warning);

			if (GUILayout.Button("Compute Smoothed Normals"))
				ComputedSmoothedNormals();
		}

		[MenuItem("Window/URP Toon Shader/Normals Smoothing Utility")]
		private static void OpenWindow()
		{
			var window = CreateWindow<NormalsSmoothingUtility>();
			window.titleContent = new GUIContent("Normals Smoothing Utility");
			window.ShowUtility();
		}

		private void ComputedSmoothedNormals()
		{
			Close();

			Assert.IsNotNull(_sourceMesh);
			Assert.IsTrue(_smoothingAngle > 0f);

			var smoothedMesh = Instantiate(_sourceMesh);
			smoothedMesh.name = _sourceMesh.name + "_SmoothedNormals";
			smoothedMesh.CalculateNormalsAndWriteToUv(_smoothingAngle, UvChannel);
			CreateMeshAsset(smoothedMesh);
		}

		private static void CreateMeshAsset(Mesh mesh)
		{
			var path = EditorUtility.SaveFilePanelInProject("Save mesh", mesh.name, "asset",
				"Select mesh asset path"
			);
			if (string.IsNullOrEmpty(path))
			{
				DestroyImmediate(mesh);
				return;
			}

			AssetDatabase.CreateAsset(mesh, path);
			AssetDatabase.SaveAssets();

			Selection.activeObject = mesh;
		}
	}
}