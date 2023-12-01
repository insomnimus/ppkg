param (
	[Parameter(Mandatory)]
	[string] $outFile
)

$outFile = [IO.Path]::GetFullPath($outFile, $pwd.providerPath)
$ErrorActionPreference = "stop"
pushd "$PSScriptRoot/../.."

function exec {
	&$args[0] $args[1..$args.length]
	if($lastExitCode -ne 0) {
		throw "$($args[0]) exited with $lastExitCode"
	}
}

function download-mars {
	$url, $ext = if($isWindows) {
		"https://github.com/insomnimus/mars/releases/download/v0.6.0/mars-i686-pc-windows-msvc.zip", ".zip"
	} elseif($isMacos) {
		"https://github.com/insomnimus/mars/releases/download/v0.6.0/mars-x86_64-apple-darwin.tar.xz", ".tar.xz"
	} else {
		"https://github.com/insomnimus/mars/releases/download/v0.6.0/mars-x86_64-unknown-linux-musl.tar.xz", ".tar.xz"
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

try {
	./build.ps1 -publish
	$mars = script:download-mars
	$null = script:exec $mars -HSNlen -O module/docs ./docs

	del -lp $mars
	cd module
	script:exec 7z a "--" $outFile *
} catch {
	write-error "error: $_"
	popd
	exit 1
} finally {
	popd
}
