namespace Action;

using System.Linq;
using CommandLine;
using Alphaleonis.Win32.Filesystem;

public class Copy: Command {
	public string Name => "copy";

	[Option('f', "force")]
	public bool Force { get; set; }

	[Value(0, Min = 2)]
	public IEnumerable<string> Files { get; set; }

	public void Run(Context c) {
		var files = this.Files.ToArray();
		var target = c.resolve(files[files.Length - 1]);
		var sources = files.Take(files.Length - 1).SelectMany(x => c.glob(x));
		var targetIsDir = Directory.ExistsTransacted(c.Tx, target);

		var i = 0;
		foreach (var p in sources) {
			if (i > 0 && !targetIsDir) {
				throw new Exception($"tried to copy multiple items into one path ({target})");
			}
			i++;

			var dest = targetIsDir ? Path.Combine(
				target,
				Path.GetFileName(p)
			)
			: target;

			c.assertInDir(p);

			var opts = CopyOptions.AllowDecryptedDestination;
			if (!this.Force) {
				opts |= CopyOptions.FailIfExists;
			}

			File.CopyTransacted(c.Tx, p, dest, opts);
		}
	}
}
