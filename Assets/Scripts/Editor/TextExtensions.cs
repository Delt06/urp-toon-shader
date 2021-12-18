using System.Collections.Generic;

namespace Editor
{
	internal static class TextExtensions
	{
		public static IEnumerable<string> TakeUntilFirstUnbalancedIf(this IEnumerable<string> lines)
		{
			var counter = 0;
			
			foreach (var line in lines)
			{
				var trimmedLine = line.Trim();
				if (trimmedLine.StartsWith("#if"))
					counter++;
				else if (trimmedLine.StartsWith("#endif"))
					counter--;

				if (counter < 0)
					break;
				
				yield return line;
			}
		}
	}
}