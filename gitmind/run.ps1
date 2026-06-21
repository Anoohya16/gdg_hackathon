# Load .env file and export variables to the current process
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        $line = $_.Trim()
        # Skip empty lines and comments
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $key, $value = $line -split '=', 2
            if ($key -and $value) {
                [System.Environment]::SetEnvironmentVariable($key.Trim(), $value.Trim(), "Process")
                Write-Host "Loaded variable: $key"
            }
        }
    }
} else {
    Write-Warning ".env file not found."
}

# Check if Mix/Elixir is available on the system PATH
if (Get-Command mix -ErrorAction SilentlyContinue) {
    # Check if Erlang is installed and booting correctly
    if (Get-Command erl -ErrorAction SilentlyContinue) {
        Write-Host "Checking Erlang runtime health..." -ForegroundColor Cyan
        $erlCheck = & erl -eval "init:stop()." -noshell -noinput 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n[ERROR] Erlang runtime is broken! Boot test failed with error:" -ForegroundColor Red
            Write-Host "$erlCheck" -ForegroundColor DarkRed
            
            Write-Host "`n=== ERLANG DIAGNOSTICS & SELF-HEALING ===" -ForegroundColor Yellow
            Write-Host "The error above indicates that Erlang cannot locate its boot files (start.boot)." -ForegroundColor Yellow
            Write-Host "This usually happens on Windows if Erlang was recently installed/copied, but its" -ForegroundColor Yellow
            Write-Host "post-installation configuration utility ('Install.exe') was never run." -ForegroundColor Yellow
            Write-Host "`nAttempting to launch Erlang's 'Install.exe' as Administrator..." -ForegroundColor Green
            
            $erlPath = (Get-Command erl).Source
            $erlDir = Split-Path (Split-Path $erlPath -Parent) -Parent
            $installExe = Join-Path $erlDir "Install.exe"
            
            if (Test-Path $installExe) {
                Write-Host "Found Install.exe at: $installExe" -ForegroundColor Green
                Write-Host "Launching in an elevated window..." -ForegroundColor Green
                Write-Host "IMPORTANT: A UAC (User Account Control) prompt will appear. Please approve it." -ForegroundColor Yellow
                Write-Host "When the black console window appears, it will prompt:" -ForegroundColor Yellow
                Write-Host "  'Do you want a minimal startup instead of sasl [No]:'" -ForegroundColor Yellow
                Write-Host "Please press [ENTER] (defaulting to 'No') to generate the boot scripts and complete setup." -ForegroundColor Yellow
                
                Start-Process -FilePath $installExe -Verb RunAs -Wait
                
                # Recheck Erlang health
                Write-Host "`nRe-checking Erlang runtime health after configuration..." -ForegroundColor Cyan
                $erlCheck2 = & erl -eval "init:stop()." -noshell -noinput 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Erlang setup completed successfully! Boot script verified." -ForegroundColor Green
                } else {
                    Write-Host "`n[ERROR] Erlang post-install configuration failed or was canceled." -ForegroundColor Red
                    Write-Host "Please run '$installExe' manually as Administrator to fix the installation." -ForegroundColor Yellow
                    exit 1
                }
            } else {
                Write-Host "`n[ERROR] Could not find 'Install.exe' at '$installExe'." -ForegroundColor Red
                Write-Host "Please download the official installer and reinstall Erlang OTP." -ForegroundColor Yellow
                exit 1
            }
        } else {
            Write-Host "Erlang runtime is healthy." -ForegroundColor Green
        }
    } else {
        Write-Warning "Erlang 'erl' was not found on your system PATH."
    }

    Write-Host "`nFetching dependencies..."
    mix deps.get
    
    Write-Host "Running database migrations..."
    mix ecto.migrate
    
    Write-Host "Starting GitMind server..."
    iex.bat -S mix
} else {
    Write-Warning "Elixir/Mix is not found on your system PATH."
    Write-Host "Environment variables have been exported. Please run the application in your Elixir-enabled environment."
}
