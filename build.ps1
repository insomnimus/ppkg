$cmdcHash = "57A2FF4F855DE104B0EB332000475BBE1913A33CFC32616F2646724196748646"

function build {
	$ErrorActionPreference = "stop"
	new-item -type directory -force libdll, libexec | out-null
	remove-item libdll/*, Action/bin -recurse -force -ea ignore

	"building the C# components"
	dotnet publish -c release Action/PPKG.csproj
	if($lastExitCode -ne 0) {
		throw "failed to build the C# components of the project"
	}
	get-childitem Action/bin/release/netstandard2.1/publish | move-item -dest libdll

	if(test-path libexec/cmdc.exe) {
		$hash = Get-FileHash -algorithm sha256 libexec/cmdc.exe
		if($hash.hash -ne $cmdcHash) {
			"warning: deleting libexec/cmdc.exe because its hash does not match the expected hash"
			remove-item libexec/cmdc.exe
		}
	}

	if(-not (test-path libexec/cmdc.exe)) {
		"downloading cmdc.exe"
		$temp = New-TemporaryFile
		remove-item -lp $temp
		$temp = [IO.Path]::ChangeExtension($temp, "7z")
		Invoke-WebRequest -outFile $temp https://github.com/insomnimus/cmdc/releases/download/v0.3.0/cmdc-win32.7z
		7z x -bso0 -bsp0 $temp -olibexec
		if($lastExitCode -ne 0) {
			throw "failed to extract $temp with 7-zip"
		}
		$hash = Get-FileHash libexec/cmdc.exe -algorithm sha256
		if($hash.hash -ne "57A2FF4F855DE104B0EB332000475BBE1913A33CFC32616F2646724196748646") {
			throw "the hash of cmdc.exe does not match the expected hash; run again at a later time or file a bug report if the issue persists"
		}
		remove-item -lp $temp
	}

	"all done"
}

push-location -lp $PSScriptRoot
try {
	script:build
} catch {
	write-error "error: $_"
	exit 1
}
pop-location
