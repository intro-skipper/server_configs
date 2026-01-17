#  .\CertOverview.ps1 .\IntroSkipper.dll

<# Output
      S/N: 5D14E786F564C7D4951C2C1A
   Issuer: CN=GlobalSign GCC R45 CodeSigning CA 2020, O=GlobalSign nv-sa, C=BE
  Subject: CN=SignPath Foundation, O=SignPath Foundation, L=Lewes, S=Delaware, C=US
 sha2_fpr: 63:99:AF:53:23:D0:DF:F1:27:93:0B:E5:3B:41:E9:E8:FE:40:86:50:6D:7B:5C:E4:8E:03:28:99:4B:4B:57:8B
 sha1_fpr: 67:4A:71:8C:26:37:40:C6:48:08:21:FC:4B:17:78:E3:E5:65:F8:97
   certid: CBB80DF2827296FFBC6E4B1FF4F45FA11D5B8451.5D14E786F564C7D4951C2C1A
  keygrip: 5FF5E33344CFAB88EF280C816D360403CA302E40
notBefore: 2025-12-22 16:45:49
 notAfter: 2027-09-07 19:23:55
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# Get Authenticode signature
$sig = Get-AuthenticodeSignature -FilePath $Path

if ($sig.Status -ne 'Valid' -and $sig.Status -ne 'UnknownError') {
    Write-Error "File is not signed or signature is invalid."
    exit 1
}

$cert = $sig.SignerCertificate

# Serial number (uppercase, no spaces)
$serial = $cert.SerialNumber.ToUpper()

# Issuer / Subject
$issuer  = $cert.Issuer
$subject = $cert.Subject

# Validity
$notBefore = $cert.NotBefore.ToString("yyyy-MM-dd HH:mm:ss")
$notAfter  = $cert.NotAfter.ToString("yyyy-MM-dd HH:mm:ss")

# Fingerprints
$sha1  = ($cert.GetCertHash("SHA1")  | ForEach-Object { $_.ToString("X2") }) -join ":"
$sha256 = ($cert.GetCertHash("SHA256") | ForEach-Object { $_.ToString("X2") }) -join ":"

# Keygrip-style value (SHA1 of public key DER)
$pubKeyDer = $cert.PublicKey.EncodedKeyValue.RawData
$keygrip = ([System.Security.Cryptography.SHA1]::Create().ComputeHash($pubKeyDer) |
           ForEach-Object { $_.ToString("X2") }) -join ""

# CertID (issuer key hash + serial, OpenPGP-like style)
$issuerKeyHash = ([System.Security.Cryptography.SHA1]::Create().ComputeHash(
    $cert.IssuerName.RawData) |
    ForEach-Object { $_.ToString("X2") }) -join ""

$certid = "$issuerKeyHash.$serial"

# Output
Write-Output ("{0,10} {1}" -f "S/N:", $serial)
Write-Output ("{0,10} {1}" -f "Issuer:", $issuer)
Write-Output ("{0,10} {1}" -f "Subject:", $subject)
Write-Output ("{0,10} {1}" -f "sha2_fpr:", $sha256)
Write-Output ("{0,10} {1}" -f "sha1_fpr:", $sha1)
Write-Output ("{0,10} {1}" -f "certid:", $certid)
Write-Output ("{0,10} {1}" -f "keygrip:", $keygrip)
Write-Output ("{0,10} {1}" -f "notBefore:", $notBefore)
Write-Output ("{0,10} {1}" -f "notAfter:", $notAfter)
