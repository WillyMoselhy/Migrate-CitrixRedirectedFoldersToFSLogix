function Copy-CFXData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $SourcePath,

        [Parameter(Mandatory = $true)]
        [string] $DestinationPath,

        [Parameter(Mandatory = $true)]
        [string] $DataLabel,

        [Parameter(Mandatory = $true)]
        [string] $Username,

        [Parameter(Mandatory = $false)]
        [int] $RobocopyMT
    )


    #Prepare Folders

    #Copy Files
    try {
        $roboCopyError = $null

        $robocopyDestination = (Join-PSFPath $mountPoint.Path 'Profile')
        $robocopyLogPath = Join-PSFPath $env:Temp "$(Split-Path -Path $DestinationPath -Leaf).robocopy.log"


        $robocopyLogPath = Join-PSFPath $env:Temp "FSLogixMigration-$Username-robocopy-$DataLabel.log"
        Copy-CFXRobocopy -Source $SourcePath -Destination $robocopyDestination -LogPath $robocopyLogPath -RobocopyMT $RobocopyMT -ErrorAction Stop

    }
    catch {
        $roboCopyError = $_
        throw $roboCopyError
    }
}