using System.Collections.Generic;
using System.Globalization;
using System.Text.RegularExpressions;
using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;
using static DELTation.ToonShader.Editor.NormalsSmoothing.NormalsSmoothingUtility;

namespace DELTation.ToonShader.Editor.NormalsSmoothing
{
	public class NormalsSmoothingPostProcessor : AssetPostprocessor
	{
		private const string Tag = "SmoothedNormals";

		[UsedImplicitly]
		private void OnPostprocessModel(GameObject gameObject)
		{
			if (gameObject.name.Contains(Tag))
				Apply(gameObject);
		}

		public override int GetPostprocessOrder() => 100;

		private float GetSmoothingAngle(GameObject gameObject)
		{
			var match = Regex.Match(gameObject.name, @$"{Tag}(\d+)");
			if (!match.Success) return MaxSmoothingAngle;

			var groupCollection = match.Groups;
			var groupValue = groupCollection[1].Value;
			if (float.TryParse(groupValue, NumberStyles.Any, CultureInfo.InvariantCulture, out var angle) &&
			    angle is >= 0 and <= MaxSmoothingAngle)
				return angle;

			Debug.LogWarning($"{groupValue} is not a valid smoothing angle. Defaulting to {MaxSmoothingAngle}",
				gameObject
			);
			return MaxSmoothingAngle;
		}

		[UsedImplicitly]
		private void Apply(GameObject gameObject)
		{
			var meshes = new HashSet<Mesh>();
			var smoothingAngle = GetSmoothingAngle(gameObject);

			const bool includeInactive = true;
			foreach (var meshFilter in gameObject.GetComponentsInChildren<MeshFilter>(includeInactive))
			{
				meshes.Add(meshFilter.sharedMesh);
			}

			foreach (var skinnedMeshRenderer in
			         gameObject.GetComponentsInChildren<SkinnedMeshRenderer>(includeInactive))
			{
				meshes.Add(skinnedMeshRenderer.sharedMesh);
			}

			foreach (var mesh in meshes)
			{
				mesh.CalculateNormalsAndWriteToUv(smoothingAngle, UvChannel);
			}
		}
	}
}