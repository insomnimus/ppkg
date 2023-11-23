namespace PPKG;

using System.Text;

using Alphaleonis.Win32.Filesystem;
using CommandLine;

public enum TextEncoding {
	ASCII,
	UTF7,
	UTF8,
	UTF16,
	UTF16BE,
	UTF32,
}

public class Create: Command {
	public string Name => "create";

	[Option('f', "force", SetName = "force")]
	public bool Force { get; set; }
	[Option('m', "if-missing", SetName = "if-missing")]
	public bool IfMissing { get; set; }

	[Option('e', "encoding", Default = TextEncoding.UTF8)]
	public TextEncoding TextEncoding { get; set; }

	private Encoding Encoding => this.TextEncoding switch {
		TextEncoding.ASCII => Encoding.ASCII,
		TextEncoding.UTF7 => Encoding.UTF7,
		TextEncoding.UTF8 => Encoding.UTF8,
		TextEncoding.UTF16 => Encoding.Unicode,
		TextEncoding.UTF16BE => Encoding.BigEndianUnicode,
		TextEncoding.UTF32 => Encoding.UTF32,
		_ => throw new Unreachable($"unhandled switch case: {this.TextEncoding}"),
	};

	[Option('d', "data", Default = "")]
	public string Data { get; set; }

	[Value(0, Min = 1)]
	public IEnumerable<string> Path { get; set; }

	public void Run(Context c) {
		var files = c.resolve(this.Path);
		var data = this.Encoding.GetBytes(this.Data);

		foreach (var p in files) {
			if (File.ExistsTransacted(c.Tx, p)) {
				if (this.IfMissing) {
					c.Trace($"file {p} exists, skipping (--if-missing)");
					continue;
				} else if (!this.Force) {
					throw new IOException($"the file `{p}` already exists and neither --force nor --if-missing was specified", 80);
				}
			}

			c.Trace($"writing file {p}");
			File.WriteAllBytesTransacted(c.Tx, p, data);
		}
	}
}
