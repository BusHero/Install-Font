$script:fonts = @{}

function Add-Font {
	param($family, $url)
	$script:fonts[$family] = $url
}

function Get-Font {
	param($family)
	$script:fonts[$family]
}

function Format-Name {
	param (
		[Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$font
	)
	switch ($font.Extension) {
		".ttf" { "$($font.BaseName) (TrueType)" }
		".otf" { "$($font.BaseName) (OpenType)" }
	}
}


#region Install-FontFile (Implementation Details)

function assertFileExists($file) {
	if (-not (Test-Path $file)) 
	{
		throw "$file not found"
	}
}

function assertFileIsFontFile($file){
	$extension = [System.IO.Path]::GetExtension($file)
	if ($extension -ne '.ttf')
	{
		throw [System.Exception] "$file is not a font file"
	}
}

function copyFontDestination($FontFile, $location) {
	if (-not (Test-Path $Location))
	{
		New-Item -Path $Location -ItemType Directory
	}
	Copy-Item -Path $FontFile -Destination $Location 
}

function ensureRegistry($Registry) {
	if (-not (Test-Path $Registry))
	{
		New-Item -Path $Registry
	}
}

function addFontToRegistry($FontFile, $Registry) {
	ensureRegistry $Registry

	$font = Get-Item $FontFile 
	$formattedName = Format-Name $font
	New-ItemProperty -Name $formattedName `
		-Path $Registry `
		-PropertyType string `
		-Value $font.Name `
		-Force `
		-ErrorAction SilentlyContinue | Out-Null
}

#endregion

function Install-FontFile {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)][string[]]$Path,
		[Parameter(Mandatory = $true)][string]$Destination,
		[Parameter(Mandatory = $true)][string]$Registry)
	foreach ($file in $Path)
	{
		try {
			assertFileExists $file
			assertFileIsFontFile $file
			copyFontDestination $file $Destination
			addFontToRegistry $file $Registry
		} catch {
		}
	}
}

function Donwload-FontFamily {
	param (
		[Parameter(Mandatory = $true)][string]$url,
		[Parameter(Mandatory = $true)][string]$Location,
		[Parameter(Mandatory = $true)][string]$Registry)
	
}

Export-ModuleMember -Function Add-Font, Get-Font, Install-FontFile