[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::CursorVisible = $false

$scriptDirectory = [System.IO.Path]::GetFullPath((Split-Path -Parent $MyInvocation.MyCommand.Path))
Set-Location -Path $scriptDirectory

if (!(Test-Path "pubspec.yaml")) {
    Write-ErrorAndPause "pubspec.yaml not found in the current directory. Please run the script from the root of your Flutter project."
}

function Show-BuildMenu {
    $options = @('Release Build', 'Debug Build', 'Exit')
    $selected = 0
    
    while ($true) {
        Clear-Host
        Write-Host '=== Lumina Build Menu ===' -ForegroundColor Cyan
        Write-Host 'Use Up/Down arrow keys to select, Enter to confirm' -ForegroundColor Yellow
        Write-Host ''
        
        for ($i = 0; $i -lt $options.Length; $i++) {
            if ($i -eq $selected) {
                Write-Host ('> ' + $options[$i]) -ForegroundColor Green
            } else {
                Write-Host ('  ' + $options[$i]) -ForegroundColor Gray
            }
        }
        
        $key = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        
        switch ($key.VirtualKeyCode) {
            38 {
                if ($selected -gt 0) { $selected-- }
            }
            40 {
                if ($selected -lt ($options.Length - 1)) { $selected++ }
            }
            13 {
                switch ($selected) {
                    0 { return 'release' }
                    1 { return 'debug' }
                    2 { exit }
                }
            }
        }
    }
}

function Write-ErrorAndPause {
    param([string]$ErrorMessage)
    Write-Host ('Error: ' + $ErrorMessage) -ForegroundColor Red
    while ($true) {
        Start-Sleep -Seconds 1
    }
}

function Show-Spinner {
    param(
        [string]$Message,
        [string]$Command
    )
    $spinner = '|', '/', '-', '\'
    $spinnerPos = 0
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    
    $job = Start-Job -ScriptBlock {
        param($command, $tempFile)
        try {
            Invoke-Expression $command
            $exitCode = $LASTEXITCODE
            $exitCode | Out-File -FilePath $tempFile
        }
        catch {
            -1 | Out-File -FilePath $tempFile
            throw
        }
    } -ArgumentList $Command, $tempFile

    Write-Host -NoNewline ($Message + ' ')
    
    while ($job.State -eq 'Running') {
        Write-Host -NoNewline "`r$Message $($spinner[$spinnerPos])"
        $spinnerPos++
        if ($spinnerPos -ge $spinner.Length) {
            $spinnerPos = 0
        }
        Start-Sleep -Milliseconds 100
    }

    $result = Receive-Job -Job $job
    Remove-Job -Job $job
    
    $exitCode = [int](Get-Content -Path $tempFile)
    Remove-Item -Path $tempFile -Force

    Write-Host "`r$Message Done!" -ForegroundColor Green
    
    if ($exitCode -ne 0) {
        Write-ErrorAndPause "Command failed. Please check the Flutter SDK installation and try again."
    }
    
    return $result
}

function Invoke-FlutterCommand {
    param([string]$Command, [string]$Message)
    
    $currentDir = Get-Location
    $command = "cd '$currentDir'; $Command"

    Clear-Host

    $result = Show-Spinner -Message $Message -Command $command

    return $result
}


try {
    if (-not $BuildType) {
        $BuildType = Show-BuildMenu
    }

    Write-Host ('Starting Flutter build process for ' + $BuildType + ' build...') -ForegroundColor Green
    Write-Host ''

    Invoke-FlutterCommand 'flutter clean' 'Cleaning project'
    Invoke-FlutterCommand 'flutter pub run build_runner build --delete-conflicting-outputs' 'Running build runner'
    
    if ($BuildType -eq 'release') {
        Invoke-FlutterCommand 'flutter build apk --release' 'Compiling release APK'
        $outputName = 'Lumina.apk'
    } else {
        Invoke-FlutterCommand 'flutter build apk --debug' 'Compiling debug APK'
        $outputName = 'Lumina-debug.apk'
    }

    $source = "build\app\outputs\flutter-apk\app-$BuildType.apk"
    $destination = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'), $outputName)

    if (!(Test-Path $source)) {
        Write-ErrorAndPause ('Built APK not found at expected location: ' + $source)
    }

    Clear-Host
    Move-Item -Path $source -Destination $destination -Force

    Write-Host 'Build completed successfully!' -ForegroundColor Green
    Write-Host 'Compiled APK is placed on the desktop. You can now close this window.' -ForegroundColor Yellow
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
catch {
    Write-ErrorAndPause $_.Exception.Message
}
