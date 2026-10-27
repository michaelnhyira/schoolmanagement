param(
    [int]$Port = 3000
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
if (-not $root) {
    $root = Get-Location
}

# Find an available port starting from $Port
$listener = $null
while ($Port -lt 3100) {
    try {
        $listener = New-Object System.Net.HttpListener
        $prefix = "http://localhost:$Port/"
        $listener.Prefixes.Add($prefix)
        $listener.Start()
        break
    } catch {
        $listener = $null
        $Port++
    }
}

if (-not $listener) {
    Write-Error "Could not bind to any port between 3000 and 3100."
    exit 1
}

$url = "http://localhost:$Port/"
Write-Host "Server running at $url"
Write-Host "Press Ctrl+C to stop."

# Open the browser
Start-Process $url

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".mjs"  = "application/javascript; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $rawPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($rawPath)) {
            $rawPath = "index.html"
        }

        # Decode path and sanitize
        $decodedPath = [System.Uri]::UnescapeDataString($rawPath).Replace('/', '\')
        $filePath = Join-Path $root $decodedPath

        # Check if file exists within root
        $fullPath = [System.IO.Path]::GetFullPath($filePath)
        $rootFullPath = [System.IO.Path]::GetFullPath($root)

        if (-not $fullPath.StartsWith($rootFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $response.StatusCode = 403
            $response.Close()
            continue
        }

        if (-not (Test-Path $fullPath -PathType Leaf)) {
            # SPA Fallback for client-side routing
            $fullPath = Join-Path $root "index.html"
        }

        if (Test-Path $fullPath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }

            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $response.ContentType = $mime
            $response.ContentLength64 = $bytes.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
} finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
}
