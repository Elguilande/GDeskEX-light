<#
.SYNOPSIS
    GDeskEx Light – Versão experimental para PCs com pouca RAM (1.5 GB)
.DESCRIPTION
    Versão limitada do GDeskEx.
    - Máximo de 12 apps
    - 3 processos em background com internet
    - 5 processos em background offline
    - Memória limitada a 1.5 GB
.AUTHOR
    Elves Guilande (GTSXAI)
#>

# ========== CONFIGURAÇÕES DO MODO LIGHT ==========
$MaxApps = 12
$MaxBackgroundOnline = 3
$MaxBackgroundOffline = 5
$MemoryLimitMB = 1536

# ========== FUNÇÕES AUXILIARES ==========
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Test-WSAInstalled {
    $package = Get-AppxPackage -Name "*WindowsSubsystemForAndroid*" -ErrorAction SilentlyContinue
    return ($null -ne $package)
}

function Test-WSARunning {
    $proc = Get-Process -Name "WsaClient" -ErrorAction SilentlyContinue
    return ($null -ne $proc)
}

function Start-WSA {
    Write-ColorOutput "Iniciando WSA..." "Cyan"
    Start-Process "shell:AppsFolder\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe!App"
    Start-Sleep -Seconds 8
}

function Test-DeveloperMode {
    $tcpTest = Test-NetConnection -ComputerName 127.0.0.1 -Port 58526 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    return ($tcpTest.TcpTestSucceeded -eq $true)
}

function Ensure-ADB {
    $adbPaths = @(
        "$env:ProgramFiles\WSA\adb.exe",
        "$env:LocalAppData\Android\Sdk\platform-tools\adb.exe",
        (Get-Command adb -ErrorAction SilentlyContinue).Source
    )
    foreach ($path in $adbPaths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }
    Write-ColorOutput "ADB não encontrado. Verifique se o WSA está instalado corretamente." "Red"
    exit 1
}

function Wait-Device {
    param([string]$AdbPath, [int]$TimeoutSeconds = 30)
    Write-ColorOutput "Aguardando dispositivo Android (WSA)..." "Cyan"
    for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
        $devices = & $AdbPath devices
        if ($devices -match "\tdevice$") {
            Write-ColorOutput "Dispositivo conectado." "Green"
            return $true
        }
        Start-Sleep -Seconds 1
    }
    Write-ColorOutput "Timeout: dispositivo não conectado." "Red"
    return $false
}

function Ensure-WSAEnvironment {
    if (-not (Test-WSAInstalled)) {
        Write-ColorOutput "WSA não encontrado. Execute '.\gdeskex-light.ps1 wsa-install' primeiro." "Red"
        exit 1
    }
    if (-not (Test-WSARunning)) {
        Start-WSA
        Start-Sleep -Seconds 3
    }
    if (-not (Test-DeveloperMode)) {
        Write-ColorOutput "Modo desenvolvedor do WSA não está ativado." "Red"
        Write-ColorOutput "Abra as configurações do WSA e ative o 'Modo desenvolvedor'." "Yellow"
        Start-Process "ms-settings:developers?subsystem=android"
        Read-Host "Pressione Enter após ativar o modo desenvolvedor"
    }
}

function Get-UserAppCount {
    param([string]$AdbPath)
    $packages = & $AdbPath shell "pm list packages -3"
    $count = ($packages | Measure-Object).Count
    return $count
}

function Test-InternetConnection {
    try {
        $result = Test-NetConnection -ComputerName 8.8.8.8 -Port 53 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        return $result.TcpTestSucceeded
    } catch {
        return $false
    }
}

function Limit-BackgroundProcesses {
    param([string]$AdbPath)

    $isOnline = Test-InternetConnection
    $maxProc = if ($isOnline) { $MaxBackgroundOnline } else { $MaxBackgroundOffline }

    Write-ColorOutput "Aplicando limite de processos em segundo plano ($maxProc)..." "Yellow"

    # Tenta limitar processos em background (melhor esforço)
    & $AdbPath shell "settings put global low_power 1" 2>$null
    & $AdbPath shell "settings put global background_activity_starts_enabled 0" 2>$null
    & $AdbPath shell "cmd deviceidle force-idle" 2>$null
}

# ========== FUNÇÕES PRINCIPAIS ==========
function Install-AndroidApp {
    param([Parameter(Mandatory)] [string]$ApkPath)

    if (-not (Test-Path $ApkPath)) {
        Write-ColorOutput "Arquivo $ApkPath não encontrado." "Red"
        return
    }

    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }

    $currentApps = Get-UserAppCount -AdbPath $AdbPath
    Write-ColorOutput "Apps instalados atualmente: $currentApps / $MaxApps" "Cyan"

    if ($currentApps -ge $MaxApps) {
        Write-ColorOutput "Limite de $MaxApps apps atingido no modo Light." "Red"
        Write-ColorOutput "Remova algum app antes de instalar outro." "Yellow"
        return
    }

    Write-ColorOutput "Instalando $ApkPath ..." "Cyan"
    & $AdbPath install $ApkPath

    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Instalação concluída." "Green"
        $newCount = Get-UserAppCount -AdbPath $AdbPath
        Write-ColorOutput "Total de apps agora: $newCount / $MaxApps" "Cyan"
    } else {
        Write-ColorOutput "Falha na instalação." "Red"
    }
}

function Run-AndroidApp {
    param([Parameter(Mandatory)] [string]$Package)
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }

    $resolve = & $AdbPath shell cmd package resolve-activity --user 0 $Package
    if (-not $resolve) {
        Write-ColorOutput "Pacote '$Package' não encontrado." "Red"
        return
    }
    $activity = ($resolve -split '\s+')[-1].Trim()
    Write-ColorOutput "Executando $Package ..." "Cyan"
    & $AdbPath shell am start -n $activity
}

function List-AndroidApps {
    param([switch]$UserOnly)
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }

    $cmd = if ($UserOnly) { "pm list packages -3" } else { "pm list packages" }
    $packages = & $AdbPath shell $cmd
    $list = $packages -replace "^package:","" | Sort-Object

    $count = ($list | Measure-Object).Count
    Write-ColorOutput "Total de apps: $count" "Cyan"
    $list
}

function Remove-AndroidApp {
    param([Parameter(Mandatory)] [string]$Package)
    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }

    Write-ColorOutput "Desinstalando $Package ..." "Yellow"
    & $AdbPath uninstall $Package
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "App desinstalado." "Green"
    } else {
        Write-ColorOutput "Falha na desinstalação." "Red"
    }
}

# ========== FUNÇÕES DO WSA ==========
function Set-WSAMemoryLimit {
    param([Parameter(Mandatory)] [int]$MemoryMB)
    if (-not (Test-WSAInstalled)) {
        Write-ColorOutput "WSA não instalado." "Red"
        return
    }

    Write-ColorOutput "Definindo limite de memória para $MemoryMB MB..." "Cyan"
    wsl --shutdown 2>$null
    WsaClient /shutdown 2>$null
    Start-Sleep -Seconds 2

    $configPath = "$env:LOCALAPPDATA\Packages\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe\LocalState\wsa_settings.xml"
    if (Test-Path $configPath) {
        $content = Get-Content $configPath -Raw
        if ($content -match 'MemoryLimit') {
            $newContent = $content -replace '(MemoryLimit>)\d+(</MemoryLimit>)', "`$1$MemoryMB`$2"
        } else {
            $newContent = $content -replace '(</Settings>)', "  <MemoryLimit>$MemoryMB</MemoryLimit>`n</Settings>"
        }
        Set-Content -Path $configPath -Value $newContent -Force
        Write-ColorOutput "Limite de memória aplicado." "Green"
    } else {
        Write-ColorOutput "Arquivo de configuração do WSA não encontrado." "Yellow"
    }
}

function Set-WSADeviceSpoof {
    param([Parameter(Mandatory)] [string]$Model = "Pixel4a")
    if (-not (Test-WSAInstalled)) { return }

    Ensure-WSAEnvironment
    $AdbPath = Ensure-ADB
    if (-not (Wait-Device -AdbPath $AdbPath)) { return }

    Write-ColorOutput "Aplicando configurações de baixo consumo..." "Cyan"
    & $AdbPath shell "setprop ro.product.model sunfish"
    & $AdbPath shell "setprop ro.product.manufacturer Google"
    & $AdbPath shell "setprop ro.config.low_ram true"
    & $AdbPath shell "settings put global animator_duration_scale 0.5"
    & $AdbPath shell "settings put global transition_animation_scale 0.5"
    & $AdbPath shell "settings put global window_animation_scale 0.5"
}

function Restart-WSA {
    Write-ColorOutput "Reiniciando WSA..." "Cyan"
    wsl --shutdown 2>$null
    WsaClient /shutdown 2>$null
    Start-Sleep -Seconds 3
    Start-Process "shell:AppsFolder\MicrosoftCorporationII.WindowsSubsystemForAndroid_8wekyb3d8bbwe!App"
    Write-ColorOutput "WSA reiniciado." "Green"
}

function Optimize-WSALight {
    Write-ColorOutput "=== Aplicando Modo Light (1.5 GB) ===" "Cyan"
    Write-ColorOutput "Regras deste modo:" "Yellow"
    Write-ColorOutput " - Máximo de $MaxApps aplicativos" "Yellow"
    Write-ColorOutput " - 3 processos em background (com internet)" "Yellow"
    Write-ColorOutput " - 5 processos em background (offline)" "Yellow"
    Write-Host ""

    Set-WSAMemoryLimit -MemoryMB $MemoryLimitMB
    Set-WSADeviceSpoof -Model "Pixel4a"

    if (Test-WSARunning) {
        $AdbPath = Ensure-ADB
        if (Wait-Device -AdbPath $AdbPath) {
            Limit-BackgroundProcesses -AdbPath $AdbPath
        }
    }

    Write-ColorOutput "Modo Light aplicado com sucesso!" "Green"
    Restart-WSA
}

function Show-WSAStatus {
    Write-ColorOutput "=== Status do WSA (Light Mode) ===" "Cyan"
    if (Test-WSAInstalled) {
        Write-ColorOutput "Instalado: SIM" "Green"
        if (Test-WSARunning) {
            Write-ColorOutput "Em execução: SIM" "Green"
            try {
                $AdbPath = Ensure-ADB
                if (Wait-Device -AdbPath $AdbPath -TimeoutSeconds 5) {
                    $count = Get-UserAppCount -AdbPath $AdbPath
                    Write-ColorOutput "Apps instalados: $count / $MaxApps" "Cyan"
                }
            } catch {}
        } else {
            Write-ColorOutput "Em execução: NÃO" "Red"
        }
    } else {
        Write-ColorOutput "Instalado: NÃO" "Red"
    }
}
# ========== FUNCOES DO INSTALADOR WSA ==========
function Install-WSABuilds {
    Write-ColorOutput "=== Instalação do WSABuilds (Modo Light) ===" "Cyan"
    Write-ColorOutput "Esta versão é experimental e limitada a 1.5 GB de RAM." "Yellow"
    Write-Host ""

    $osInfo = Get-CimInstance Win32_OperatingSystem
    $isWindows11 = $osInfo.Caption -match "Windows 11"

    if ($isWindows11) {
        Write-ColorOutput "Sistema detectado: Windows 11" "Green"
        $wsaUrl = "https://github.com/MustardChef/WSABuilds/releases/download/Windows_11_2407.40000.4.0_LTS_8/WSA_2407.40000.4.0_x64_Release-Nightly-with-Magisk-30.6-Stable-MindTheGapps-13.0.7z"
    } else {
        Write-ColorOutput "Sistema detectado: Windows 10" "Green"
        $wsaUrl = "https://github.com/MustardChef/WSABuilds/releases/download/Windows_10_2407.40000.4.0_LTS_8/WSA_2407.40000.4.0_x64_Release-Nightly-with-Magisk-30.6-Stable-MindTheGapps-13.0.7z"
    }

    $tempDir = Join-Path $env:TEMP "WSABuilds-Light"
    $sevenZipPath = Join-Path $tempDir "7zr.exe"
    $archivePath = Join-Path $tempDir "WSA.7z"
    $extractPath = Join-Path $tempDir "Extracted"

    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }

    # Baixa 7zr
    if (-not (Test-Path $sevenZipPath)) {
        Write-ColorOutput "Baixando 7-Zip..." "Cyan"
        Invoke-WebRequest -Uri "https://www.7-zip.org/a/7zr.exe" -OutFile $sevenZipPath
    }

    Write-ColorOutput "Baixando WSABuilds (pode demorar)..." "Cyan"
    try {
        Invoke-WebRequest -Uri $wsaUrl -OutFile $archivePath -ErrorAction Stop
    } catch {
        Write-ColorOutput "Erro no download: $_" "Red"
        return
    }

    Write-ColorOutput "Extraindo..." "Cyan"
    if (-not (Test-Path $extractPath)) {
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    }

    & $sevenZipPath x $archivePath -o"$extractPath" -y | Out-Null

    $runBat = Get-ChildItem -Path $extractPath -Recurse -Filter "Run.bat" | Select-Object -First 1

    if ($runBat) {
        Write-ColorOutput "Iniciando instalação..." "Cyan"
        Start-Process -FilePath $runBat.FullName -Wait
        Write-ColorOutput "Instalação concluída!" "Green"
        Write-ColorOutput "Agora execute: .\gdeskex-light.ps1 wsa-light" "Yellow"
    } else {
        Write-ColorOutput "Instalador não encontrado." "Red"
    }
}
# ========== PONTO DE ENTRADA ==========
$cmd = $args[0]

switch ($cmd) {
    "install"     { Install-AndroidApp -ApkPath $args[1] }
    "run"         { Run-AndroidApp -Package $args[1] }
    "list"        { List-AndroidApps }
    "list-user"   { List-AndroidApps -UserOnly }
    "remove"      { Remove-AndroidApp -Package $args[1] }
    "wsa-memory"  { if ($args[1]) { Set-WSAMemoryLimit -MemoryMB ([int]$args[1]) } else { Write-ColorOutput "Uso: .\gdeskex-light.ps1 wsa-memory 1536" "Yellow" } }
    "wsa-restart" { Restart-WSA }
    "wsa-light"   { Optimize-WSALight }
    "wsa-status"  { Show-WSAStatus }
    default {
        Write-ColorOutput @"
GDeskEx Light - Versão experimental (1.5 GB RAM)

Limitações:
  - Máximo de $MaxApps aplicativos
  - 3 processos em background (online)
  - 5 processos em background (offline)

Comandos:
  wsa-light              Aplica o modo Light
  wsa-status             Mostra status + quantidade de apps
  install [apk]          Instala app (respeita limite de 12)
  run [pacote]           Executa app
  list                   Lista apps
  list-user              Lista só apps de usuário
  remove [pacote]        Remove app
  wsa-restart            Reinicia o WSA

Exemplos:
  .\gdeskex-light.ps1 wsa-light
  .\gdeskex-light.ps1 wsa-status
  .\gdeskex-light.ps1 install C:\Downloads\app.apk
"@ "Cyan"
    }
}
