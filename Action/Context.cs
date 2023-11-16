namespace Action;

using SPath = System.IO.Path;
using DotNet.Globbing;
using Alphaleonis.Win32.Filesystem;
using System.Linq;


public class Context {
	internal string[] dirComponents;
	internal string dir { get; set; }
	public KernelTransaction Tx { get; set; }

	public Context(KernelTransaction tx, string dir) {
		this.Tx = tx;

		if (!SPath.IsPathRooted(dir)) {
			throw new ArgumentException($"the path specified is relative: {dir}", "dir");
		}

		this.dir = dir = Path.RemoveTrailingDirectorySeparator(dir);
		this.dirComponents = dir.Split('\\');
	}

	internal string resolve(string p) {
		var path = Path.RemoveTrailingDirectorySeparator(Path.Combine(this.dir, p));
		if (!this.isInDir(path)) {
			throw new Errors.PathLeavesDir(this.dir, p);
		}
		return path;
	}

	internal void assertInDir(string path) {
		if (!this.isInDir(path)) {
			throw new Errors.PathLeavesDir(this.dir, path);
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

	internal string[] glob(string pattern) {
		var globOpts = new GlobOptions() {
			Evaluation = new EvaluationOptions() { CaseInsensitive = true }
		};

		if (pattern.StartsWith("./") || pattern.StartsWith(".\\")) {
			pattern = pattern.Substring(2);
		}
		if (!pattern.Contains('*', '?', '[')) {
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
			return new string[] { this.resolve(pattern) };
		}

		var depth = pattern.Contains("**") ? 0
		: (this.dirComponents.Length + pattern.Count(c => c == '\\' || c == '/'));

		var g = Glob.Parse(pattern.Substring(lastSlash + 1), globOpts);

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

		var items = Directory.EnumerateFileSystemEntriesTransacted(
			this.Tx,
			root,
			DirectoryEnumerationOptions.FilesAndFolders | DirectoryEnumerationOptions.Recursive,
			filter
		)
		.ToArray();

		if (items.Length == 0) return new string[] { this.resolve(pattern) };
		else return items;
	}
}