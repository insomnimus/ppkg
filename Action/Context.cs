namespace PPKG;

using SPath = System.IO.Path;
using DotNet.Globbing;
using Alphaleonis.Win32.Filesystem;
using System.Linq;

public class Context {
	private static GlobOptions GlobOpts = new GlobOptions() {
		Evaluation = new EvaluationOptions() { CaseInsensitive = true }
	};

	internal string dir { get; set; }
	public KernelTransaction Tx { get; set; }
	public System.Action<string> Trace { get; set; }

	internal string[] dirComponents;

	public Context(KernelTransaction tx, string dir, System.Action<string> trace) {
		this.Tx = tx;
		this.Trace = trace;

		if (!SPath.IsPathRooted(dir)) {
			throw new ArgumentException($"the path specified is relative: {dir}", "dir");
		}

		this.dir = dir = Path.RemoveTrailingDirectorySeparator(dir);
		this.dirComponents = dir.Split('\\');
	}

	internal string resolve(string p) {
		var path = Path.RemoveTrailingDirectorySeparator(Path.Combine(this.dir, p));
		if (!this.isInDir(path)) {
			throw new PathLeavesDirError(this.dir, p);
		}
		return path;
	}

	internal void assertInDir(string path) {
		if (!this.isInDir(path)) {
			throw new PathLeavesDirError(this.dir, path);
		}
	}

	internal string[] resolve(IEnumerable<string> paths)
	=> paths.Select(x => this.resolve(x)).ToArray();

	internal bool isInDir(string p) {
		var comps = p.Split(new char[] { '\\', '/' });
		if (comps.Length < this.dirComponents.Length) return false;

		for (var i = 0; i < this.dirComponents.Length; i++) {
			if (!comps[i].Equals(this.dirComponents[i], StringComparison.OrdinalIgnoreCase)) {
				return false;
			}
		}

		return true;
	}

	internal string[] glob(string pattern, bool nullGlob) {
		this.Trace($"called glob (nullglob = {nullGlob}): {pattern}");
		if (pattern.StartsWith("./") || pattern.StartsWith(".\\")) {
			pattern = pattern.Substring(2);
		}
		if (!pattern.Contains('*', '?', '[')) {
			this.Trace("pattern does not contain wildcards, not globbing");
			return new string[] { this.resolve(pattern) };
		}

		var lastSlash = -1;
		for (var i = 0; i < pattern.Length; i++) {
			var c = pattern[i];
			if (c == '\\' || c == '/') {
				lastSlash = i;
			} else if (c == '*' || c == '?' || c == '[') {
				break;
			}
		}

		var root = (lastSlash < 0) ? this.dir : SPath.Combine(this.dir, pattern.Substring(0, lastSlash));
		if (!Directory.ExistsTransacted(this.Tx, root)) {
			this.Trace($"globbed path {root}/{pattern} does not exist, not globbing");
			return nullGlob ? new string[] { }
			: new string[] { this.resolve(pattern) };
		}

		var depth = pattern.Contains("**") ? 0
		: (this.dirComponents.Length + pattern.Count(c => c == '\\' || c == '/'));

		var g = Glob.Parse(pattern.Substring(lastSlash + 1), GlobOpts);

		var filter = new DirectoryEnumerationFilters() {
			InclusionFilter = (entry) => {
				var s = entry.FullPath.Substring(this.dir.Length + 1);
				return g.IsMatch(s);
			},
			RecursionFilter = (entry) => {
				return entry.IsDirectory &&
				(depth == 0 || depth >= entry.FullPath.Count(c => c == '\\' || c == '/'));
			}
		};

		this.Trace($"globbing directory {root} with depth {depth} and pattern {g}");
		var items = Directory.EnumerateFileSystemEntriesTransacted(
			this.Tx,
			root,
			DirectoryEnumerationOptions.FilesAndFolders | DirectoryEnumerationOptions.Recursive,
			filter
		)
		.ToArray();

		this.Trace($"globbing matched {items.Length} path(sd)");

		if (!nullGlob && items.Length == 0) return new string[] { this.resolve(pattern) };
		else return items;
	}
}
