function :new-tx {
	# Returns (TransactionScope, AlphaFS.KernelTransaction)
	[CmdletBinding()]
	param ()

	[Transactions.TransactionManager]::ImplicitDistributedTransactions = $true
	[Transactions.TransactionScope]::new([Transactions.TransactionScopeOption]::RequiresNew)
	[Alphaleonis.Win32.Filesystem.KernelTransaction]::new([Transactions.Transaction]::Current)
}

function :fullpath {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[object[]] $path
	)

	process {
		foreach($p in $path) {
			if($p) {
				[IO.Path]::GetFullPath($p, $PWD.ProviderPath)
			}
		}
	}
}

function :get-file {
	[CmdletBinding()]
	[OutputType([IO.FileSystemInfo])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[object[]] $path,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	process {
		if($tx) {
			foreach($p in $path | script::fullpath) {
				try {
					$attr = [Alphaleonis.Win32.Filesystem.File]::GetAttributesTransacted($tx, $p)
					if($attr.HasFlag([IO.FileAttributes]::Directory)) {
						[IO.DirectoryInfo]::new($p) | add-member NoteProperty IsDirectory $true -typeName boolean -passthru
					} else {
						[IO.FileInfo]::new($p) | add-member NoteProperty IsDirectory $false -typeName boolean -passthru
					}
				} catch {
					write-error "error accessing file ${p}: $_"
				}
			}
		} else {
			get-item -lp:$path -force | foreach-object {
				$isDir = $_ -is [IO.DirectoryInfo]
				$_ | add-member NoteProperty IsDirectory $isDir -typeName boolean -passthru -force
			}
		}
	}
}

function :ls {
	[CmdletBinding()]
	[OutputType([IO.FileSystemInfo])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[object[]] $path,

		[string] $filter,
		[switch] $directory,
		[switch] $file,
		[switch] $recurse,

		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	begin {
		$enumOpts = if($file -eq $directory) {
			[Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::FilesAndFolders
		} elseif($file) {
			[Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::Files
		} else {
			[Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::Folders
		}
		if($recurse) {
			$enumOpts += [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::Recursive
		}
	}

	process {
		foreach($p in $path | script::fullpath) {
			try {
				if($tx) {
					[Alphaleonis.Win32.Filesystem.Directory]::EnumerateFileSystemEntriesTransacted($tx, $p, $enumOpts) `
					| script::get-file -tx $tx `
					| where-object { !$filter -or $_.name -like $filter }
				} else {
					Get-ChildItem -lp $p -file:$file -directory:$directory  `
					| where-object { !$filter -or $_.name -like $filter } `
					| foreach-object { $_ | add-member NoteProperty IsDirectory ($_ -is [IO.DirectoryInfo]) -force -typeName boolean -passthru }
				}
			} catch {
				write-error "failed to enumerate ${p}: $_"
			}
		}
	}
}

function :rm {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[Alias("lp")]
		[object[]] $path,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx,

		[switch] $force,
		[switch] $recurse,
		# short for -recurse -force
		[switch] $rf
	)

	begin {
		if($rf) {
			$recurse = $force = $true
		}
	}

	process {
		foreach($p in $path) {
			trace "deleting $p"
			if($tx) {
				$f = script::get-file -ea stop $p -tx $tx
				if($f.isDirectory) {
					[Alphaleonis.Win32.Filesystem.Directory]::DeleteTransacted($tx, $f.fullname, $recurse)
				} else {
					[Alphaleonis.Win32.Filesystem.File]::DeleteTransacted($tx, $f.fullname, $true) # TODO: Set last parameter (delete read-only) to $force?
				}
			} else {
				try {
					remove-item -lp $p -recurse:$recurse -force:$force -ea stop
				} catch {
					err "error deleting ${p}: $_"
				}
			}
		}
	}
}

function :mkdir {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[object[]] $path,
		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	process {
		foreach($p in $path) {
			if($tx) {
				$p = script::fullpath $p
				if(script::exists $p -tx $tx) {
					err -ea stop "can't create new directory: the path $p already exists"
				}
				[void] [Alphaleonis.Win32.Filesystem.Directory]::CreateDirectoryTransacted($tx, $p)
			} else {
				trace "creating directory $p"
				try {
					$null = new-item -ea stop -type directory $p
				} catch {
					err "error creating directory ${p}: $_"
				}
			}
		}
	}
}

function :empty-dir {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[object] $path,
		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	process {
		if(script::exists $path -tx:$tx) {
			script::rm -rf -ea stop $path -tx:$tx
		}
		script::mkdir $path -tx:$tx
	}
}

function :mv {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[Alias("lp")]
		[object[]] $path,

		[Parameter(Mandatory, Position = 1)]
		[object] $destination,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx,

		[switch] $force
	)

	begin {
		$files = [Collections.Generic.List[object]]::new(16)
	}

	process {
		foreach($p in $path | script::get-file -tx:$tx -ea stop) {
			[void] $files.add($p)
		}
	}

	end {
		$destination = script::fullpath $destination
		$destIsDir = script::exists -dir $destination -tx:$tx
		if($files.count -gt 1 -and -not $destIsDir) {
			err -ea stop "tried to move multiple files into the same destination ($destination)"
		}

		foreach($f in $files) {
			if($tx) {
				$dest = $destIsDir ? (join-path $destination $f.name) : $destination
				trace "moving $f to $dest"

				$opts = if($force -and -not $f.IsDirectory) {
					[Alphaleonis.Win32.Filesystem.MoveOptions]::ReplaceExisting
				} else {
					[Alphaleonis.Win32.Filesystem.MoveOptions]::None
				}
				$opts += [Alphaleonis.Win32.Filesystem.MoveOptions]::CopyAllowed -bor [Alphaleonis.Win32.Filesystem.MoveOptions]::WriteThrough

				$res = [Alphaleonis.Win32.Filesystem.File]::MoveTransacted($tx, $f, $dest, $opts)
				assert $res.ErrorCode -eq 0 "failed to move $f to ${dest}: $($res.ErrorMessage)"
			} else {
				try {
					move-item -ea stop -lp $f.fullname -destination $destination -force:$force
				} catch {
					err "error moving $f to ${destination}: $_"
				}
			}
		}
	}
}

function :cp {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[Alias("lp")]
		[object[]] $path,
		[Parameter(Mandatory, Position = 1)]
		[object] $destination,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx,

		[switch] $force,
		[switch] $recurse
	)

	begin {
		$files = [Collections.Generic.List[object]]::new(16)
	}

	process {
		foreach($p in $path | script::get-file -tx:$tx -ea stop) {
			[void] $files.add($p)
		}
	}

	end {
		$destination = script::fullpath $destination
		$destIsDir = script::exists -dir $destination -tx:$tx
		if($files.count -gt 1 -and -not $destIsDir) {
			err -ea stop "tried to copy multiple files into the same destination ($destination)"
		}

		foreach($f in $files) {
			$dest = $destIsDir ? (join-path $destination $f.name) : $destination
			trace "copying $f to $dest"

			if($tx) {
				$opts = if($force) {
					[Alphaleonis.Win32.Filesystem.CopyOptions]::None
				} else {
					[Alphaleonis.Win32.Filesystem.CopyOptions]::FailIfExists
				}
				if(-not $p.IsDirectory) {
					$opts += [Alphaleonis.Win32.Filesystem.CopyOptions]::OpenSourceForWrite
				}
				$opts += [Alphaleonis.Win32.Filesystem.CopyOptions]::AllowDecryptedDestination

				$res = [Alphaleonis.Win32.Filesystem.File]::CopyTransacted($tx, $f, $dest, $opts)
				assert $res.ErrorCode -eq 0 "failed to copy $f to ${dest}: $($res.ErrorMessage)"
			} else {
				try {
					copy-item -ea stop -lp $f.fullname -destination $dest -force:$force -recurse:$recurse
				} catch {
					err "error copying ${f} to ${dest}: $_"
				}
			}
		}
	}
}

function :ensure-dir {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[object[]] $path,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	process {
		foreach($p in $path | script::fullpath) {
			if(script::exists -not -directory $p -tx:$tx) {
				script::mkdir $p -tx:$tx
			}
		}
	}
}

function :exists {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[object[]] $path,

		[switch] $not,
		[switch] $directory,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	process {
		foreach($p in $path) {
			$yes = if($tx) {
				$f = script::get-file $p -tx $tx -ea ignore
				($null -ne $f -and (-not $directory -or $f.IsDirectory))
			} else {
				$type = $directory ? "Container" : "Any"
				test-path -lp $p -type $type
			}

			$not ? !$yes : $yes
		}
	}
}

function :write-file {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $path,
		[Parameter(Mandatory, Position = 1)]
		[object] $data,

		[Parameter()]
		[Text.Encoding] $encoding,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	$path = script::fullpath $path
	if($data -is [string]) {
		$encoding ??= [Text.Encoding]::UTF8
		$data = $encoding.GetBytes($data)
	} elseif($data -isnot [byte[]] -and $data -isnot [Collections.Generic.List[byte]]) {
		err -ea stop "(internal error) value data provided to :write-file must be string or byte[]; but instead it is $($data.GetType())"
	}

	if($tx) {
		[Alphaleonis.Win32.Filesystem.File]::WriteAllBytesTransacted($tx, $path, $data)
	} else {
		[Alphaleonis.Win32.Filesystem.File]::WriteAllBytes($path, $data)
	}
}

function :ln {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $path,
		[Parameter(Mandatory)]
		[string] $pointsTo,

		[Parameter(ParameterSetName = "hard")]
		[switch] $hard,
		[Parameter(ParameterSetName = "junction")]
		[switch] $junction,

		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	assert ($junction -or $hard) "script::ln: one of -hard or -junction needs to be used"

	$path = script::fullpath $path
	trace "linking $path -> $pointsTo"
	try {
		if($tx) {
			if($hard) {
				[Alphaleonis.Win32.Filesystem.File]::CreateHardLinkTransacted($tx, $path, $pointsTo)
			} elseif($junction) {
				[Alphaleonis.Win32.Filesystem.Directory]::CreateJunction($tx, $path, $pointsTo, $true, $true)
			}
		} else {
			$type = $hard ? "HardLink" : "Junction"
			new-item -ea stop -type $type -path $path -target $pointsTo
		}
	} catch {
		write-error "error linking $path -> ${pointsTo}: $_"
	}
}
