---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-update

## SYNOPSIS
Updates installed packages and repositories.

## SYNTAX

```
ppkg-update [[-package] <String[]>] [-repo <String[]>] [-keepLogs] [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-update` cmdlet updates installed packages and repositories.

If no package name is provided, only the repositories are updated.

The repositories are updated regardless of the presence of any package name specified.

As with other package management cmdlets, `ppkg-update` uses filesystem transactions.

## EXAMPLES

### Example 1: Update local repositories
```powershell
PS> ppkg-update
```

### Example 2: Update all installed packages
```powershell
PS> ppkg-update *
```

### Example 3: Update specific packages
```powershell
PS> ppkg-update go python
```

## PARAMETERS

### -keepLogs
Do not remove the download log file on success

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

### -package
Name of the packages to update (accepts glob)

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -repo
Update a specific repository

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
