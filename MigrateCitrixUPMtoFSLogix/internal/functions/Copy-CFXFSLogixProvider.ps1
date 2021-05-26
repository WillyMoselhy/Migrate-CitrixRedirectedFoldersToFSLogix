function Copy-CFXFSLogixProvider {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $DiskPath,

        [Parameter(Mandatory = $true)]
        [string[]] $ProviderPath,

        [Parameter(Mandatory = $true)]
        [switch] $SetOwner,

        [Parameter(Mandatory = $true)]
        [string] $SID
    )


    $diskItem = Get-Item -Path $DiskPath
    foreach ($path in $ProviderPath) {
        Write-PSFMessage -Level Verbose -Message "Copying to $path"
        $measure = Measure-Command -Expression {
            $null = New-Item -Path (Split-Path -Path $path) -ItemType Directory -Force -ErrorAction Stop
            Copy-Item -Path $DiskPath -Destination $path -Force -ErrorAction Stop
        }
        Write-PSFMessage -Level Verbose -Message "Completed copy."

        if($SetOwner){
            Write-PSFMessage -Level Verbose -Message "Setting ownership on $path"
            #On VHD file
            $fileACL = Get-ACL -Path $path
            $fileACL.SetOwner([System.Security.Principal.SecurityIdentifier] $SID)
            Set-ACL -Path $path -AclObject $fileACL -ErrorAction Stop

            $folderPath = Split-Path -Path $path
            $folderACL = Get-ACL -Path $folderPath
            $folderACL.SetOwner([System.Security.Principal.SecurityIdentifier] $SID)
            Set-ACL -Path $folderPath -AclObject $fileACL -ErrorAction Stop
        }

        [PSCustomObject]@{
            ProviderPath  = $path
            CopyDuration  = "{0}:{1}:{2}.{3}" -f $measure.Hours, $measure.Minutes, $measure.seconds, $measure.Milliseconds
            CopySpeedMBps = ($diskItem.length / 1MB) / $measure.TotalSeconds
        }
    }
}