function Initialize-CFXFSLogixVHD {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $MountPointPath,

        [Parameter(Mandatory = $true)]
        [string] $SID
    )
    # Create Profile folder
    Write-PSFMessage -Level Verbose -Message "Creating 'Profile' Folder"
    $profileFolder = New-Item -Path $MountPointPath -Name 'Profile' -ItemType Directory -ErrorAction Stop

    #Set Permissions on the profile
    Write-PSFMessage -Level Verbose -Message "Setting owner and permissions on 'Profile'"

    $profileACL = Get-Acl -Path $profileFolder.FullName -ErrorAction Stop

    $systemAccount = [System.Security.Principal.NTAccount]'NT AUTHORITY\SYSTEM'
    $userAccount = [System.Security.Principal.SecurityIdentifier] $SID

    $systemAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule('NT AUTHORITY\SYSTEM','FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $administratorsAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Builtin\Administrators','FullControl','ContainerInherit,ObjectInherit','None','Allow')
    $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userAccount,'FullControl','ContainerInherit,ObjectInherit','None','Allow')

    $profileACL.SetOwner($systemAccount)
    $profileACL.SetAccessRuleProtection($true,$false) # Block inheritance and remove current rules

    $profileACL.AddAccessRule($systemAccessRule)
    $profileACL.AddAccessRule($administratorsAccessRule)
    $profileACL.AddAccessRule($userAccessRule)

    Set-Acl -Path $profileFolder.FullName -AclObject $profileACL -ErrorAction Stop
}