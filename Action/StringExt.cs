namespace PPKG;

internal static class StringExt {
	public static bool Contains(this string self, params char[] any) {
		foreach (var c in self) {
			if (any.Contains(c)) return true;
		}

		return false;
	}
}
