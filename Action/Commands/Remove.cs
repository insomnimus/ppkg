namespace Action;

using CommandLine;
using Alphaleonis.Win32.Filesystem;

public class Remove: Command {
	public string Name => "remove";

	[Option('n', "null-glopb")]
	public bool NullGlob { get; set; }

	[Value(0, Min = 1)]
	public IEnumerable<string> Files { get; set; }

	public void Run(Context c) {
		foreach (var p in this.Files.SelectMany(x => c.glob(x, this.NullGlob))) {
			// This is likely unnecessary as glob() starts from c.dir to begin with.
			c.assertInDir(p);
			var attrs = File.GetAttributesTransacted(c.Tx, p);
			if (attrs.HasFlag(FileAttributes.Directory)) {
				Directory.DeleteTransacted(c.Tx, p, true);
			} else {
				File.DeleteTransacted(c.Tx, p, true);
			}
		}
	}
}
