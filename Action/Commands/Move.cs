namespace PPKG;

using Alphaleonis.Win32.Filesystem;
using CommandLine;

public class Move: Command {
	public string Name => "move";

	[Option('f', "force")]
	public bool Force { get; set; }
	[Option('n', "null-glob")]
	public bool NullGlob { get; set; }

	[Value(0, Min = 2)]
	public IEnumerable<string> Files { get; set; }

	public void Run(Context c) {
		var files = this.Files.ToArray();
		if (this.NullGlob && files.Length < 2) return;
		var target = c.resolve(files[files.Length - 1]);
		var sources = files.Take(files.Length - 1).SelectMany(x => c.glob(x, this.NullGlob));
		var targetIsDir = Directory.ExistsTransacted(c.Tx, target);

		var i = 0;
		foreach (var p in sources) {
			if (i > 0 && !targetIsDir) {
				throw new Exception($"tried to move multiple items into one path ({target})");
			}
			i++;

			var dest = targetIsDir ? Path.Combine(
				target,
				Path.GetFileName(p)
			)
			: target;

			c.assertInDir(p);

			var opts = MoveOptions.CopyAllowed | MoveOptions.WriteThrough;
			if (this.Force && !Directory.ExistsTransacted(c.Tx, p)) {
				opts |= MoveOptions.ReplaceExisting;
			}

			var res = File.MoveTransacted(c.Tx, p, dest, opts);
			if (res.ErrorCode != 0) {
				throw new IOException($"error moving {p} to {dest}: {res.ErrorMessage}");
			}
		}
	}
}
