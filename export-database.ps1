# Firestore Database Exporter
param(
    [string]$CredentialsPath = "database.json",
    [string]$OutputPath = "firestore_backup.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CredentialsPath)) {
    Write-Error "Credentials file not found at: $CredentialsPath"
    exit 1
}

Write-Host "Reading credentials from $CredentialsPath..." -ForegroundColor Cyan
$cred = Get-Content $CredentialsPath -Raw | ConvertFrom-Json
$projectId = $cred.project_id
$clientEmail = $cred.client_email

# Extract RSA Private Key
$pkPem = $cred.private_key
$pkBase64 = $pkPem -replace '-----BEGIN PRIVATE KEY-----', '' -replace '-----END PRIVATE KEY-----', '' -replace '\s+', ''
$pkBytes = [System.Convert]::FromBase64String($pkBase64)
$cng = [System.Security.Cryptography.CngKey]::Import($pkBytes, [System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
$rsa = New-Object System.Security.Cryptography.RSACng($cng)

function Base64UrlEncode([byte[]]$bytes) {
    [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

Write-Host "Authenticating with Google OAuth2..." -ForegroundColor Cyan
$header = @{ alg = "RS256"; typ = "JWT" } | ConvertTo-Json -Compress
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$claim = @{
    iss = $clientEmail
    scope = "https://www.googleapis.com/auth/datastore"
    aud = "https://oauth2.googleapis.com/token"
    exp = $now + 3600
    iat = $now
} | ConvertTo-Json -Compress

$headerB64 = Base64UrlEncode ([System.Text.Encoding]::UTF8.GetBytes($header))
$claimB64 = Base64UrlEncode ([System.Text.Encoding]::UTF8.GetBytes($claim))
$dataToSign = [System.Text.Encoding]::UTF8.GetBytes("$headerB64.$claimB64")
$signature = $rsa.SignData($dataToSign, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
$sigB64 = Base64UrlEncode $signature
$jwt = "$headerB64.$claimB64.$sigB64"

$body = @{
    grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer"
    assertion = $jwt
}

$tokenResponse = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/token" -Method Post -Body $body
$accessToken = $tokenResponse.access_token
$authHeaders = @{ Authorization = "Bearer $accessToken" }

Write-Host "Authenticated successfully for project: $projectId" -ForegroundColor Green

function Convert-FirestoreValue($val) {
    if ($null -eq $val) { return $null }
    
    if ($val.PSObject.Properties['stringValue']) { return $val.stringValue }
    if ($val.PSObject.Properties['integerValue']) { return [long]$val.integerValue }
    if ($val.PSObject.Properties['doubleValue']) { return [double]$val.doubleValue }
    if ($val.PSObject.Properties['booleanValue']) { return [bool]$val.booleanValue }
    if ($val.PSObject.Properties['timestampValue']) { return $val.timestampValue }
    if ($val.PSObject.Properties['nullValue']) { return $null }
    if ($val.PSObject.Properties['referenceValue']) { return $val.referenceValue }
    if ($val.PSObject.Properties['geoPointValue']) { return $val.geoPointValue }
    
    if ($val.PSObject.Properties['arrayValue']) {
        $arr = @()
        if ($val.arrayValue.values) {
            foreach ($item in $val.arrayValue.values) {
                $arr += ,(Convert-FirestoreValue $item)
            }
        }
        return $arr
    }
    
    if ($val.PSObject.Properties['mapValue']) {
        $map = [ordered]@{}
        if ($val.mapValue.fields) {
            foreach ($prop in $val.mapValue.fields.PSObject.Properties) {
                $map[$prop.Name] = Convert-FirestoreValue $prop.Value
            }
        }
        return $map
    }
    
    return $val
}

function Convert-FirestoreDoc($doc) {
    $result = [ordered]@{}
    if ($doc.fields) {
        foreach ($prop in $doc.fields.PSObject.Properties) {
            $result[$prop.Name] = Convert-FirestoreValue $prop.Value
        }
    }
    return $result
}

function Get-SubcollectionIds($parentDocPath) {
    $url = "https://firestore.googleapis.com/v1/$parentDocPath`:listCollectionIds"
    try {
        $res = Invoke-RestMethod -Uri $url -Method Post -Headers $authHeaders -Body "{}" -ContentType "application/json"
        if ($res.collectionIds) { return $res.collectionIds }
    } catch {
        # No subcollections or error
    }
    return @()
}

function Export-Collection($parentPath, $collectionId) {
    Write-Host "  Exporting collection: $collectionId..." -ForegroundColor Yellow
    $docsResult = [ordered]@{}
    $pageSize = 100
    $pageToken = ""
    $totalCount = 0

    do {
        $url = "https://firestore.googleapis.com/v1/$parentPath/$collectionId`?pageSize=$pageSize"
        if ($pageToken) {
            $url += "&pageToken=$pageToken"
        }
        
        $res = Invoke-RestMethod -Uri $url -Method Get -Headers $authHeaders
        if ($res.documents) {
            foreach ($doc in $res.documents) {
                $docName = $doc.name
                $docId = $docName.Substring($docName.LastIndexOf('/') + 1)
                $docData = Convert-FirestoreDoc $doc
                
                # Check for subcollections
                $subCollections = Get-SubcollectionIds $docName
                if ($subCollections.Count -gt 0) {
                    $docData['__subcollections__'] = [ordered]@{}
                    foreach ($subCol in $subCollections) {
                        $docData['__subcollections__'][$subCol] = Export-Collection $docName $subCol
                    }
                }
                
                $docsResult[$docId] = $docData
                $totalCount++
            }
        }
        $pageToken = $res.nextPageToken
    } while ($pageToken)

    Write-Host "    -> Fetched $totalCount document(s) from $collectionId" -ForegroundColor DarkGreen
    return $docsResult
}

# Fetch root collections
$rootUrl = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents:listCollectionIds"
$rootRes = Invoke-RestMethod -Uri $rootUrl -Method Post -Headers $authHeaders -Body "{}" -ContentType "application/json"
$rootCollections = $rootRes.collectionIds

Write-Host "Discovered $($rootCollections.Count) root collections: $($rootCollections -join ', ')" -ForegroundColor Cyan

$databaseExport = [ordered]@{}
$baseParentPath = "projects/$projectId/databases/(default)/documents"

foreach ($colId in $rootCollections) {
    $databaseExport[$colId] = Export-Collection $baseParentPath $colId
}

Write-Host "Saving export to $OutputPath..." -ForegroundColor Cyan
$jsonOutput = $databaseExport | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $OutputPath), $jsonOutput, [System.Text.Encoding]::UTF8)

Write-Host "`nSuccessfully exported Firestore database to $OutputPath!" -ForegroundColor Green
