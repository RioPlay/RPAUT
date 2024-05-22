# send-reminders.ps1
Param (
    [Parameter(Mandatory=$true)]
    [string]$Subject,
    [Parameter(Mandatory=$true)]
    [string]$Body,
    [Parameter(Mandatory=$true)]
    [string]$Recipient
)

Add-Type -AssemblyName "Microsoft.Office.Interop.Outlook"
$outlook = New-Object -ComObject Outlook.Application
$mail = $outlook.CreateItem(0)
$mail.Subject = $Subject
$mail.Body = $Body
$mail.To = $Recipient
$mail.Send()
Write-Host "Reminder sent to $Recipient."
