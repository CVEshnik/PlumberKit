function Test-PipeCanBeDuplicated {
    param([string]$PipeName)
    
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public class PipeTest {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr CreateNamedPipe(
            string lpName,
            uint dwOpenMode,
            uint dwPipeMode,
            uint nMaxInstances,
            uint nOutBufferSize,
            uint nInBufferSize,
            uint nDefaultTimeOut,
            IntPtr lpSecurityAttributes
        );
        
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);
    }
"@

    $PIPE_ACCESS_DUPLEX = 0x00000003
    $PIPE_TYPE_MESSAGE = 0x00000004
    $PIPE_READMODE_MESSAGE = 0x00000002
    $PIPE_WAIT = 0x00000000
    $PIPE_UNLIMITED_INSTANCES = 255
    $FILE_FLAG_FIRST_PIPE_INSTANCE = 0x00080000
    
    $fullName = "\\.\pipe\" + $PipeName
    
    
    $hPipe = [PipeTest]::CreateNamedPipe(
        $fullName,
        $PIPE_ACCESS_DUPLEX,
        $PIPE_TYPE_MESSAGE -bor $PIPE_READMODE_MESSAGE -bor $PIPE_WAIT,
        $PIPE_UNLIMITED_INSTANCES,
        1024, 1024, 0, [IntPtr]::Zero
    )
    
    if ([int]$hPipe -eq -1) {
        $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        
        return $false
    } else {
        [PipeTest]::CloseHandle($hPipe)
        return $true
    }
}

Get-ChildItem \\.\pipe\ | ForEach-Object {
    $pipeName = $_.Name
    $canDuplicate = Test-PipeCanBeDuplicated -PipeName $pipeName
    if ($canDuplicate) {
        Write-Host "[+] $pipeName - DIGGED!"
    } else {
        Write-Host "    $pipeName"
    }
}