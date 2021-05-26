function Copy-CFXRobocopy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Source,
        [Parameter(Mandatory = $true)]
        [string] $Destination,
        [Parameter(Mandatory = $true)]
        [string] $LogPath
    )


    Write-PSFMessage -Level Verbose -Message "Copying files from $Source to $Destination - Logging to $LogPath"

        $robocopyArgs = @(
        $Source
        $Destination
        '/XJ','/E','/B','/MT:10','/W:1','/R:1','/NP','/NS','/NDL' ,'/COPYALL'
    )
    $robocopyProcess = Start-Process -FilePath Robocopy -ArgumentList $robocopyArgs -RedirectStandardOutput $LogPath -Wait -PassThru -NoNewWindow
    <#
        /COPYALL: Copy with timestamp, NTFS permissions, Owner, Audit, etc...
        /XJ: Do not copy junction points (this can cause infinite loops)
        /E: Copy all subfolder and files including empty directories
        /B: Copy in backup mode, requires permission on target system OS. HElps avoid NTFS security blocks.
        /MT:10 Copy 10 files simultaneously (Multi-threaded) Good for network performance.
        /W:1 /R:1: In case of error, retry one time. wait one second.
        /NP /NFL /NJH /NJS: Do not show progress, list of files or directories, header, or summary. So Robocopy should not return any output other than errors.
    #>
    Write-PSFMessage -Level Verbose -Message "Robocopy exited with code: $($robocopyProcess.ExitCode)"
    if($robocopyProcess.ExitCode -notin (1,3)){
        # Exit codes 1 and 3 means all good, anything else could be an error. https://adamtheautomator.com/robocopy/#Exit_Codes
        $robocopyLog = Get-Content -Path $LogPath
        throw "Robocopy returned $($robocopyProcess.ExitCode):`r`n$($robocopyLog | out-string)"
    }
}