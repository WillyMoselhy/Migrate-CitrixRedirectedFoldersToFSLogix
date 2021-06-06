function Get-CFXADUserSID {
    [CmdletBinding()]
    param (
        # Username used for logon (SAMAccountName)
        [Parameter(Mandatory = $true)]
        [string] $Username
    )


    try {
        $sid = (New-Object System.Security.Principal.NTAccount($Username)).translate([System.Security.Principal.SecurityIdentifier]).Value
        #Get-ADUser -Identity $Username -ErrorAction Stop
    }
    catch {
        throw
    }
    Write-PSFMessage -Level Verbose -Message "Resolved SID for $username as $sid"
    $sid

}