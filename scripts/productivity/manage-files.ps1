# manage-files.ps1
Param (
    [Parameter(Mandatory=$true)]
    [string]$Directory
)

$files = Get-ChildItem -Path $Directory
foreach ($file in $files) {
    $extension = $file.Extension
    $targetDir = Join-Path -Path $Directory -ChildPath $extension.TrimStart('.')
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir
    }
    Move-Item -Path $file.FullName -Destination $targetDir
}
Write-Host "Files organized by type."
