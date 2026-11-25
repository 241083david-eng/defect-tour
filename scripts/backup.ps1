# Creates one dated zip of this folder in backups\ (defect-tour-backup-YYYY-MM-DD.zip), verifies it, then opens the folder and Google Drive.
# Keeps the newest 5 dated zips in backups\ and deletes older ones there. A second backup on the same day replaces that day's zip.
# It is written under a temporary name first and replaces the old zip only after it is verified (file names are stored as UTF-8, so Hebrew names survive a restore anywhere).
# Run with -NoOpen to create and verify the zip without opening any window.
param([switch]$NoOpen)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$backups = Join-Path $root 'backups'
New-Item -ItemType Directory -Force $backups | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd'
$final = Join-Path $backups "defect-tour-backup-$stamp.zip"
$zip = Join-Path $backups "defect-tour-backup-$stamp.tmp"
$keep = 5
$exclude = @('node_modules', 'dist', 'backups')

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $zip) { Remove-Item $zip -Force }
$archive = [System.IO.Compression.ZipFile]::Open($zip, 'Create', [System.Text.Encoding]::UTF8)
$count = 0
try {
  Get-ChildItem -Path $root -Recurse -File -Force | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length + 1)
    $top = $rel.Split('\')[0]
    if ($exclude -contains $top) { return }
    $entry = $rel.Replace('\', '/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $_.FullName, $entry) | Out-Null
    $count++
  }
} finally {
  $archive.Dispose()
}

# Verify: the zip opens and holds every file we added.
$check = [System.IO.Compression.ZipFile]::OpenRead($zip)
$entries = $check.Entries.Count
$check.Dispose()
if ($entries -eq 0 -or $entries -ne $count) {
  throw "Verification failed: wrote $count files, zip holds $entries."
}
Move-Item $zip $final -Force
$sizeMb = [math]::Round((Get-Item $final).Length / 1MB, 1)

# Keep the newest 5 dated backups here; older ones are deleted (only files named defect-tour-backup-YYYY-MM-DD.zip).
$dated = @(Get-ChildItem -Path $backups -File -Filter 'defect-tour-backup-*.zip' |
  Where-Object { $_.Name -match '^defect-tour-backup-\d{4}-\d{2}-\d{2}\.zip$' } |
  Sort-Object Name -Descending)
$old = @($dated | Select-Object -Skip $keep)
foreach ($f in $old) { Remove-Item $f.FullName -Force }

Write-Host "PASS: $final"
Write-Host "      $entries files, $sizeMb MB, verified."
if ($old.Count) { Write-Host "      Deleted $($old.Count) older backup(s) here; the newest $keep are kept." }
if ($NoOpen) { return }
Write-Host "Drag the selected file into the Google Drive folder that opens now. It is added as a new file (the name has today's date, so Drive keeps the older ones)."
Write-Host "When Drive has more than $keep backups there, delete the oldest ones in Drive."

# The folder opens with the new zip already selected, and Drive opens straight in this folder's backup folder, ready to drag into.
Start-Process explorer.exe "/select,`"$final`""
Start-Process 'https://drive.google.com/drive/folders/1yaRhn6FCM9ZWONSODyGyASshrvJ0UQ1H'
