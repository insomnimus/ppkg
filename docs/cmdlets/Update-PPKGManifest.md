---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# Update-PPKGManifest

## SYNOPSIS
Updates a package manifest by consulting github.com.

## SYNTAX

### path (Default)
```
Update-PPKGManifest [-path] <Object[]> [-dry] [-noHash] [<CommonParameters>]
```

### lp
```
Update-PPKGManifest -literalPath <Object[]> [-dry] [-noHash] [<CommonParameters>]
```

## DESCRIPTION
The `Update-PPKGManifest` cmdlet updates a package manifest to the latest version by consulting github.com.

This cmdlet is meant to be used by package repository maintainers. Do not use it on packages controlled by ppkg itself.

This cmdlet looks for the `x32.githubPattern` and `x64.githubPattern` fields in a manifest.
Manifests without those fields will be ignored.

After querying the github API for the latest release, it substitutes the text `${version}` inside the `githubPattern` string with the version returned by calling the github API.
The replacement string does not have a `v` prefix. E.g.: `0.5.2`.

Note that if the github API returns an older version than currently defined in the package manifest, the package will be downgraded.
No updates will be made if the version in the package manifest matches the version on github.

By default, the package contents are downloaded to a temporary location to calculate the hash sums and later removed from the disk.
To prevent this, specify the `-noHash` flag, in which case the hash value will be omitted from the manifest.

Note: Ulike package management cmdlets, `Update-PPKGManifest` does not use filesystem transactions, meaning it can leave the specified manifests in a corrupted state. IT's advised to source control your manifests in case of corruption.
However, it will not leave manifests in a corrupt state on regular errors.

## EXAMPLES

### Example 1: Update a package manifest
```powershell
PS> Update-PPKGManifest ./foobar.json
```

### Example 2: Update all manifests in a directory
```powershell
PS> Get-ChildItem -Filter *.json -Recurse -File | Update-PPKGManifest
```

### Example 3: Update a manifest without downloading the files
```powershell
PS> Update-PPKGManifest -noHash ./foobar.json
```

## PARAMETERS

### -dry
Do not update the files on disk

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -literalPath
Path to a PPKG manifest

```yaml
Type: Object[]
Parameter Sets: lp
Aliases: lp

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -noHash
Do not download fiels to update hashsums

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -path
Path to a PPKG manifest (supports glob)

```yaml
Type: Object[]
Parameter Sets: path
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
