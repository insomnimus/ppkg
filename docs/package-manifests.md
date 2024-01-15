---
title: Package Manifests
lang: en
---

# Package Manifests
Packages are defined by a package manifest as JSON.

Manifests have a `.json` file extension.

## Fields
| Field | Type | Description | Required |
| ----- | ---- | ----------- | -------- |
| version | [Version](#Version) | The version of the package | yes |
| description | string | A brief description of the package | yes |
| homepage | URI string | The homepage of the package | no |
| license | string | the name of the license of the package | yes |
| bin | string list | List of binaries that the package makes available | yes |
| preInstall | [Action](#action) list | List of [actions](#action) that are to be executed after download and before install | false |
| x32 | [Resource](#resource) | The [resource](#resource) for x32 installations | no\* |
| x64 | [Resource](#resource) | The [resource](#resource) for x64 installations | no\* |

\* A package must have at least one of x32 or x64. It can have both.

## Resource
A resource describes a download source.

It can have the fields:
- `url`: The download URI (required).
- `hash` A hash sum in the form `algo:sum` where `algo` is one of MD5, SHA1, SHA256, SHA384, SHA512. An alternate form of this is just `sum`, in which case the algorithm is assumed to be SHA256.
- `files`: A list of files to be extracted from an archive if the download is an archive. If not specified, all files are extracted.
- `preInstall`: One or more [actions](#action) that will be performed after download and before installation.
- `githubPattern`: (for package maintainers) a URL pattern for automatic updating of github-based package manifests. See the [Maintaining a Package Repository page](maintaining-a-package-repository.md) for details.

Instead of writing in object syntax, you can use a string with the URL of the download. In this case all other fields will be `null`.

The supported protocols on URL's are:
- http
- https
- sftp

All other protocols are errors.

To rename the downloaded file, use a URL fragment:

`"url": "https://example.com/download/example_v2.0.5.exe#example.exe"`

Here, the downloaded file will be renamed to `example.exe`.

### HTTP and HTTPS Downloads
Files hosted through HTTP or HTTPS servers will be downloaded using the `curl.exe` command, available by default on newer versions of Windows 10 and 11.

### Using sftp URL's
A resource can specify an sftp URL with the syntax `sftp://user@server/full/path/to/download`.

This functionality is designed for hosting private repositories.
Sftp Downloads use the `sftp.exe` executable available in newer versions of Windows 10 and 11.
The configuration in the user's `~/.ssh/config` file will be picked up.

## Action
An action is a safe command you can use to perform actions during installation steps.

For further information, see the [Actions page](actions.md).

## A Note About Lists
In places where a list is expected, you can always use a single item if the list contains only one item; meaning without the brackets ``.
For example:
```json
{
	"bin": "example.exe"
}
```

## Version
Versions are strictly semantic versions. The syntax is as below.
- `major.minor.patch`
- or: `major.minor.patch-prerelease`
- where `major`, `minor` and `patch` are non-negative integers;
- and `prerelease` consists of letters, digits, underscores, periods or hyphens (-).


Versions can have a single leading `v`; e.g. `v1.2.3`.

Every other version syntax is an error; packages with invalid versions will not be available for any operation.

These are errors:
- `1.0` (missing patch)
- `2` (missing minor and patch)
- `1.2.3pre` (pre-release must be separated with a `-`)
- `1.2.3.0` (too many fields)

These are okay:
- `1.2.0`
- `0.15.0-alpha`
- `v2023.1.1`
- `v0.0.0`
- `2.0.0-beta.1`
