namespace Action;

using Alphaleonis.Win32.Filesystem;
using CommandLine;

public class Link: Command {
	public string Name => "link";

	[Option('f', "force")]
	public bool Force { get; set; }
	[Option('h', "hard", SetName = "hard")]
	public bool Hard { get; set; }
	[Option('j', "junction", SetName = "junction")]
	public bool Junction { get; set; }
	[Option('s', "soft", SetName = "soft")]
	public bool Soft { get; set; }

	[Value(0, Required = true)]
	public string Path { get; set; }
	[Value(1, Required = true)]
	public string PointsTo { get; set; }

	[Value(2)]
	public string? __stop {
		get => null;
		set { throw new ActionParseError(this.Name, new string[] { }, $"unexpected argument `{value!}`"); }
	}

	public void Run(Context c) {
		var p = c.resolve(this.Path);
		var target = c.resolve(this.PointsTo);

		var attrs = File.GetAttributesTransacted(c.Tx, target);

		if (attrs.HasFlag(FileAttributes.Directory)) {
			if (this.Hard) {
				throw new IOException($"cannot create a junction to a file ({this.Path} -> {this.PointsTo})");
			}
			this.Junction = true;
		} else {
			if (this.Junction) {
				throw new IOException($"cannot create a hard link to a directory ({this.Path} -> {this.PointsTo})");
			}
			this.Hard = true;
		}

		if (File.ExistsTransacted(c.Tx, p)) {
			if (this.Force) {
				File.DeleteTransacted(c.Tx, p, true);
			} else {
				throw new IOException($"cannot create link: file {this.Path} already exists and --force was not provided", 80);
			}
		} else if (Directory.ExistsTransacted(c.Tx, p)) {
			if (this.Force) {
				Directory.DeleteTransacted(c.Tx, p, true);
			} else {
				throw new IOException($"cannot create link: file {this.Path} already exists and --force was not provided", 80);
			}
		}

		if (this.Hard) {
			File.CreateHardLinkTransacted(c.Tx, p, target);
		} else if (this.Junction) {
			Directory.CreateJunction(c.Tx, p, target, true);
		} else {
			throw new Unreachable();
		}
	}
}
