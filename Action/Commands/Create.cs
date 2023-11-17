namespace PPKG;

using System.Text;

using Alphaleonis.Win32.Filesystem;
using CommandLine;

public class Create: Command {
	public string Name => "create";

	[Option('f', "force", SetName = "force")]
	public bool Force { get; set; }
	[Option('m', "if-missing", SetName = "if-missing")]
	public bool IfMissing { get; set; }

	[Option('e', "encoding", Default = "utf8")]
	public Encoding Encoding { get; set; }

	[Option('d', "data", Default = "")]
	public string Data { get; set; }

	[Value(0, Min = 1)]
	public IEnumerable<string> Path { get; set; }

	public void Run(Context c) {
		var files = c.resolve(this.Path);
		var data = this.Encoding.GetBytes(this.Data);

		foreach (var p in files) {
			if (File.ExistsTransacted(c.Tx, p)) {
				if (this.IfMissing) continue;
				else if (!this.Force) {
					throw new IOException($"the file `{p}` already exists and neither --force nor --if-missing was specified", 80);
				}
			}

			File.WriteAllBytesTransacted(c.Tx, p, data);
		}
	}
}
