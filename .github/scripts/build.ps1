param (
	[Parameter(Mandatory)]
	[string] $outDir
)

$ErrorActionPreference = "stop"
pushd "$PSScriptRoot/../.."

function exec {
	&$args[0] $args[1..$args.length]
	if($lastExitCode -ne 0) {
		throw "$($args[0]) exited with $lastExitCode"
	}
}

function download-mars {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $version
	)

	$ErrorActionPreference = "stop"
	$url, $ext = if($isWindows) {
		"https://github.com/insomnimus/mars/releases/download/v$version/mars-i686-pc-windows-msvc.zip", ".zip"
	} elseif($isMacos) {
		"https://github.com/insomnimus/mars/releases/download/v$version/mars-x86_64-apple-darwin.tar.xz", ".tar.xz"
	} else {
		"https://github.com/insomnimus/mars/releases/download/v$version/mars-x86_64-unknown-linux-musl.tar.xz", ".tar.xz"
	}

	$temp = new-temporaryFile
	del -lp $temp
	$temp = [IO.Path]::ChangeExtension($temp, $ext)
	Invoke-WebRequest -OutFile $temp $url

	$dir = new-temporaryFile
	del -lp $dir

	if($isWindows) {
		expand-archive -destination $dir $temp
		del -lp $temp
		join-path $dir mars.exe
	} else {
		script:exec tar -xf $tmp --directory $dir
		del -lp $temp
		if($LastExitCode -ne 0) {
			throw "tar exited with exit code $LastExitCode"
		}
		$mars = join-path $dir mars
		script:exec chmod +x $mars
		$mars
	}
}

function bundle-7z {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $version,
		[Parameter(Mandatory)]
		[string] $outDir32,
		[Parameter(Mandatory)]
		[string] $outDir64
	)

	if(-not (test-path -lp $outDir32)) {
		$null = new-item -type directory $outDir32
	}
	if(-not (test-path -lp $outDir64)) {
		$null = new-item -type directory $outDir64
	}

	$ErrorActionPreference = "stop"
	$x32url = "https://7-zip.org/a/7z$version.exe"
	$x64url = "https://7-zip.org/a/7z$version-x64.exe"

	$temp = new-temporaryFile
	remove-item -lp $temp
	$dir = new-item -type directory $temp
	$x32 = join-path $dir "7zip-x32.exe"
	$x64 = join-path $dir "7zip-x64.exe"

	invoke-webRequest $x32url -outFile $x32
	invoke-webRequest $x64url -outFile $x64

	$x32dir = join-path $dir "x32"
	$x64dir = join-path $dir "x64"

	script:exec 7z x -aoa -bso0 -bsp0 $x32 "-o$x32dir"
	script:exec 7z x -aoa -bso0 -bsp0 $x64 "-o$x64dir"

	remove-item -lp $x32, $x64
	move-item -lp "$x32dir/License.txt" "$outDir32/LICENSE.7zip.txt"
	move-item -lp "$x32Dir/7z.exe" $outDir32

	move-item -lp "$x64dir/License.txt" "$outDir64/LICENSE.7zip.txt"
	move-item -lp "$x64dir/7z.exe" $outDir64

	remove-item -recurse -force -lp $x32dir, $x64dir
}

try {
	$outDir = [IO.Path]::GetFullPath($outDir, $PWD.providerPath)
	if([IO.Path]::EndsInDirectorySeparator($outDir)) {
		$outDir = $outDir.Substring(0, $outDir.length - 1)
	}
	if(-not (test-path -lp $outDir)) {
		$null = new-item -type directory $outDir
	}

	./build.ps1 -publish
	$mars = script:download-mars 0.7.1
	$null = script:exec $mars -HSNlen -O module/docs ./docs

	remove-item -lp $mars
	# Create 32 bit and 64 bit directories
	$tempDir = new-temporaryFile
	remove-item -lp $tempDir
	$null = new-item -type directory $tempDir

	$module32 = join-path $tempDir "module32"
	$module64 = join-path $tempDir "module64"
	copy-item -recurse module $module32
	copy-item -recurse module $module64

	script:bundle-7z "2301" -outDir32 "$module32/libexec" -outDir64 "$module64/libexec"
	cd $module32
	script:exec 7z a -aoa -bso0 -bsp0 "--" "$outDir/ppkg-x32.zip" *
	cd $module64
	script:exec 7z a -aoa -bso0 -bsp0 "--" "$outDir/ppkg-x64.zip" *
} catch {
	write-error "error: $_"
	popd
	exit 1
} finally {
	popd
}
