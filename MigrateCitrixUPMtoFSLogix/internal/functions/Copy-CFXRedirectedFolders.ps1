function Copy-CFXRedirectedFolders {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $FRX ,

        [Parameter(Mandatory = $true)]
        [string] $DiskPath,

        [Parameter(Mandatory = $true)]
        [string] $RedirectedFoldersPath
    )
    Write-PSFMessage -Level Verbose -Message "Mounting VHD using FRX.exe: $Diskpath"
    $mountPoint = Mount-CFXProfile -FRX $FRX -DiskPath $DiskPath
    try{
        $roboCopyError = $null

        $robocopyDestination = (Join-PSFPath $mountPoint.Path 'Profile')
        $robocopyLogPath = Join-PSFPath $env:Temp "$(Split-Path -Path $DiskPath -Leaf).robocopy.log"

        Copy-CFXRobocopy -Source $RedirectedFoldersPath -Destination $robocopyDestination -LogPath $robocopyLogPath -ErrorAction Stop
    }
    catch {
        $roboCopyError = $_
    }
    finally{
        Write-PSFMessage -Level Verbose -Message "Dismounting VHD using FRX.exe"
        Dismount-CFXProfile -DiskPath $DiskPath -Cookie $mountPoint.Cookie -FRX $FRX
        if($roboCopyError) {throw $roboCopyError}
    }

}