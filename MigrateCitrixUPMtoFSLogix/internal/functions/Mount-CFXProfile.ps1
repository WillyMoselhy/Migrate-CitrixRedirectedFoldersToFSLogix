function Mount-CFXProfile {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [string] $FRX ,

        [Parameter(Mandatory = $true)]
        [string] $DiskPath

    )

    # Open disk for editing using FRX
    $editDisk = & $FRX begin-edit-profile -filename $DiskPath

    if($editDisk[-1] -ne 'Operation completed successfully!' ){
        throw ($editDisk | Out-String)
    }

    $mountPointPath = $editDisk[1]
    if(-Not (Test-Path -Path $mountPointPath)){
        throw "Mount point path is invalid:`r`n$($editDisk | out-string)"
    }

    $mountPointCookie = $editDisk[5]

    <# Removed this check as sometimes the cookie is 3 characters, add later when we know the proper regex for it
    if(-Not ($mountPointCookie -match '^(\d|\w){4}$')){
        throw "Mount point cookie is invalid:`r`n$($editDisk | out-string)"
    }
    #>

    Write-PSFMessage -Level Verbose -Message "Mounted VHD at $mountPointPath - Cookie $mountPointCookie"
    [PSCustomObject]@{
        Path = $mountPointPath
        Cookie = $mountPointCookie
    }
}