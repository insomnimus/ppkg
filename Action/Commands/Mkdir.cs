namespace PPKG;

using Alphaleonis.Win32.Filesystem;
using CommandLine;

public class Mkdir: Command {
	public string Name => "mkdir";

	[Value(0, Min = 1)]
	public IEnumerable<string> Path { get; set; }

	public void Run(Context c) {
		var files = c.resolve(this.Path);

		foreach (var p in files) {
			Directory.CreateDirectoryTransacted(c.Tx, p);
		}
	}
}
