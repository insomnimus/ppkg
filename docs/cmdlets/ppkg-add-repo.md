---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-add-repo

## SYNOPSIS
Adds a repository.

## SYNTAX

```
ppkg-add-repo [-name] <String> [-git] <String> [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-add-repo` cmdlet installs a repository through git.

The repository url must point to a git repository.

## EXAMPLES

### Example 1: Add a new repository
```powershell
PS> ppkg-add-repo personal https://github.com/myname/ppkg-packages
```

## PARAMETERS

### -git
The git clone URL of the repository

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -name
The name that will be used locally to refer to the repository

```yaml
Type: String
Parameter Sets: (All)
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
