function Get-CFXProfilePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Username,

        [Parameter(Mandatory = $true)]
        [string] $ProfilePath
    )

    $path = $ProfilePath -replace "%username%",$Username
    if($profileFolderName -like "*%*") {throw "Could replace all maps in ($ProfilePath). Please only use %Username%."}
    if(-Not (Test-Path -Path $path)){
        throw "Profile path does not exist: $path"
    }
    Write-PSFMessage -Level Verbose -Message "Calculated Profile path for $username on $ProfilePath as: $path"

    $path
}