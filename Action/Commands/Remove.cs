namespace PPKG;

using CommandLine;
using Alphaleonis.Win32.Filesystem;

public class Remove: Command {
	public string Name => "remove";

	[Option('n', "null-glopb")]
	public bool NullGlob { get; set; }

	[Value(0, Min = 1)]
	public IEnumerable<string> Files { get; set; }

	public void Run(Context c) {
		var i = 0L;
		foreach (var p in this.Files.SelectMany(x => c.glob(x, this.NullGlob))) {
			i++;
			// This is likely unnecessary as glob() starts from c.dir to begin with.
			c.assertInDir(p);
			c.Trace($"retreiving file attributes for {p}");
			var attrs = File.GetAttributesTransacted(c.Tx, p);
			if (attrs.HasFlag(FileAttributes.Directory)) {
				c.Trace($"removing directory {p}");
				Directory.DeleteTransacted(c.Tx, p, true);
			} else {
				c.Trace($"removing file {p}");
				File.DeleteTransacted(c.Tx, p, true);
			}
		}

		if (i == 0) {
			c.Trace("globbing matched no path; removing nothing");
		}
	}
}
