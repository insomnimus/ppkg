---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-search

## SYNOPSIS
Searches for packages from installed repositories.

## SYNTAX

### fuzzy (Default)
```
ppkg-search [-pattern] <String[]> [-repo <String[]>] [<CommonParameters>]
```

### not-fuzzy
```
ppkg-search [-package <String[]>] [-bin <String[]>] [-repo <String[]>] [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-search` cmdlet searches for packages from installed repositories.

By default packages are searched by their names, names of their binaries and words in their descriptions.
- To search for binary names only, use the `-bin` option.
- To search for package names only, use the `-package` option.

The options `-pattern`, `-bin` and `-package` all accept wildcard patterns.

## EXAMPLES

### Example 1: Get packages by name or the name of a binary
```powershell
PS> ppkg-search sed
```

### Example 2: Search for a package by only its name
```powershell
PS> ppkg-search -package gh
```

### Example 3: Search for packages containing a particular binary
```powershell
PS> ppkg-search -bin wget.exe
```

### Example 4: Get packages that match a wildcard pattern
```powershell
PS> ppkg-search *-dl
```

## PARAMETERS

### -bin
Name of an executable (accepts glob)

```yaml
Type: String[]
Parameter Sets: not-fuzzy
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -package
Name of the package (accepts glob)

```yaml
Type: String[]
Parameter Sets: not-fuzzy
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -pattern
The package name, a keyword or the name of an executable to search for (accepts glob)

```yaml
Type: String[]
Parameter Sets: fuzzy
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -repo
Specify a repository

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
