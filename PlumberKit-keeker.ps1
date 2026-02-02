Add-Type @"
using System; 
using System.Runtime.InteropServices;
public class PipePeek {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr CreateFile(string n, uint a, uint s, IntPtr p, uint c, uint f, IntPtr t);
    [DllImport("kernel32.dll")] 
    public static extern bool PeekNamedPipe(IntPtr p, byte[] b, uint z, out uint r, out uint a, out uint l);
    [DllImport("kernel32.dll")] 
    public static extern bool CloseHandle(IntPtr h);
}
"@

$READ = 0x80000000
$OPEN = 3
$SHARE = 3

Write-Host "`n[ SCAN NAMED PIPES ]`n" -Fore Cyan

$total = 0
$withData = 0
$noData = 0
$noAccess = 0
$errors = 0

foreach ($pipe in (Get-ChildItem "\\.\pipe\")) {
    $total++
    $name = $pipe.Name
    
    try {
        $access = [uint32]$READ
        $h = [PipePeek]::CreateFile($pipe.FullName, $access, $SHARE, [IntPtr]::Zero, $OPEN, 0, [IntPtr]::Zero)

        if ([int]$h -eq -1) {
            # INVALID_HANDLE_VALUE
            Write-Host "[X] $name" -Fore DarkRed
            $noAccess++
        }
        elseif ($h -eq [IntPtr]::Zero) {
            # NULL handle
            Write-Host "[X] $name" -Fore DarkRed
            $noAccess++
        }
        else {
            $r = 0; $a = 0; $l = 0
            $ok = [PipePeek]::PeekNamedPipe($h, $null, 0, [ref]$r, [ref]$a, [ref]$l)
            
            if ($ok) {
                if ($a -gt 0) {
                    # Есть данные
                    Write-Host "[+] $name" -NoNewline -Fore Green
                    Write-Host " ($a bite)" -Fore Yellow
                    $withData++
                }
                else {
                    # Нет данных
                    Write-Host "[ ] $name" -Fore Gray
                    $noData++
                }
            }
            else {
                Write-Host "[!] $name" -Fore Red
                $errors++
            }
            
            [PipePeek]::CloseHandle($h) | Out-Null
        }
    }
    catch {
        
        Write-Host "[E] $name" -Fore Red
        $errors++
    }
}

# Статистика
Write-Host "`n[ STAT ]" -Fore Cyan
Write-Host "Total pipes: $total" -Fore White
Write-Host "Pipes have any data: $withData" -Fore Green
Write-Host "Clean pipes: $noData" -Fore Gray
Write-Host "No access: $noAccess" -Fore DarkRed
Write-Host "Errors: $errors" -Fore Red


if ($withData -gt 0) {
    Write-Host "`n[ Pipes have any data ]" -Fore Yellow
    
    foreach ($pipe in (Get-ChildItem "\\.\pipe\")) {
        try {
            $access = [uint32]$READ
            $h = [PipePeek]::CreateFile($pipe.FullName, $access, $SHARE, [IntPtr]::Zero, $OPEN, 0, [IntPtr]::Zero)
            
            if ([int]$h -ne -1 -and $h -ne [IntPtr]::Zero) {
                $r = 0; $a = 0; $l = 0
                if ([PipePeek]::PeekNamedPipe($h, $null, 0, [ref]$r, [ref]$a, [ref]$l) -and $a -gt 0) {
                    Write-Host "  $($pipe.Name.PadRight(40)) - $a байт" -Fore Green
                }
                [PipePeek]::CloseHandle($h) | Out-Null
            }
        }
        catch {}
    }
}
