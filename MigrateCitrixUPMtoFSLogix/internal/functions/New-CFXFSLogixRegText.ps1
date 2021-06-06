function New-CFXFSLogixRegText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPointPath,
        [Parameter(Mandatory = $true)]
        [string] $Username,
        [Parameter(Mandatory = $true)]
        [string] $SID
    )

    $regText = @"
Windows Registry Editor Version 5.00
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$SID]
"ProfileImagePath"="C:\\Users\\$Username"
"FSL_OriginalProfileImagePath"="C:\\Users\\$Username"
"Flags"=dword:00000000
"State"=dword:00000000
"ProfileLoadTimeLow"=dword:00000000
"ProfileLoadTimeHigh"=dword:00000000
"RefCount"=dword:00000000
"RunLogonScriptSync"=dword:00000000
"@

    $fslogixAppdataPath = Join-PSFPath -Path $MountPointPath -Child 'Profile\AppData\Local\FSLogix'
    $null = New-Item -Path $fslogixAppdataPath -ItemType Directory -Force -ErrorAction Stop

    $regFilePath = Join-PSFPath -Path $fslogixAppdataPath -Child 'ProfileData.reg'
    $regText | Out-File -FilePath $regFilePath -Encoding ascii -ErrorAction Stop

    Write-PSFMessage -Level Verbose -Message "Created Registry file at: $regFilePath"
}