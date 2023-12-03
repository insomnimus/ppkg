---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-list

## SYNOPSIS
Gets a list of the currently installed packages.

## SYNTAX

```
ppkg-list [[-pattern] <String[]>] [-repo <String[]>] [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-list` command gets a list of the currently installed packages.

The `pattern` parameter accepts wildcards just like the `-like` operator.

You can reduce the results to a specified repository by using the `-repo` option.

## EXAMPLES

### Example 1: List all installed packages
```powershell
PS> ppkg-install
```

### Example 2: List all installed packages in a specific repository
```powershell
PS> ppkg-install -repo main
```

### Example 3: Get packages that match a pattern
```powershell
PS> ppkg-install ps-*
```

## PARAMETERS

### -pattern
Filter results with a glob pattern

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -repo
Limit results to a repository or repositories

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
