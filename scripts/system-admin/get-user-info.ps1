# get-user-info.ps1
Param (
    [Parameter(Mandatory=$true)]
    [string]$Username
)

try {
    $user = Get-ADUser -Identity $Username -Properties *
    $user | Select-Object Name, SamAccountName, EmailAddress, Title, Department
} catch {
    Write-Error "User $Username not found in Active Directory."
}
