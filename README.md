# PlumberKit

![Logo](https://yaart-web-alice-images.s3.yandex.net/fddf4062ffef11f087dcd2bc6c1b033f:2)

## introduction
While learning about "Windows Pipes" exploitation, I decided to create several scripts that would not be blocked by EDR, for use in penetration testing. The scripts have been tested on Windows 10/11 operating systems, with Kaspersky Endpoint Security v.12 acting as the EDR. Currently, there are only 3 scripts, but I plan to expand "PlumberKit" in the future by adding new tools and updating existing ones.

## functional
**PlumberKit-depose -**This tool checks "pipes" processes that can be hijacked. After selecting the target "pipes", the program creates an identical "pipes" faster than the target application and connects to it to abuse its capabilities.
**PlubmerKit-keeker -**This tool inspects all "pipes" and outputs a brief summary of those that can be "eavesdropped" on.
**PlumberKit-twins - **This tool displays all "pipes" and marks those that can be hijacked with the "DIGGED" tag.

## how to use
Depose
```powershell
  PS C:\Users\UserOS\Desktop\PlumberKit> .\PlumberKit-depose.ps1
```

## sample
```powershell
PS C:\Users\UserOS\Desktop\PlumberKit> .\PlumberKit-depose.ps1
Search vulnerable PIPE...
========================
    InitShutdown
    lsass
    ntsvcs
    scerpc
    Winsock2\CatalogChangeListener-28c-0
    Winsock2\CatalogChangeListener-538-0
    epmapper

[+] WiFiNetworkManagerTask
True
    SessEnvPublicRpc
    Winsock2\CatalogChangeListener-1548-0
[+] Everything Service
True
[+] DumpWriterACE8BA25
True
    trkwks
    Winsock2\CatalogChangeListener-144-0
    vmware-usbarbpipe
    48de374c-b9bf-4735-9bcf-4803115eec2b
[+] FaxPrint
True

Vuln PIPE: 23
1. WiFiNetworkManagerTask
2. Everything Service
3. DumpWriterACE8BA25
4. FaxPrint
5. PDFPrint
Choose PIPE to boom (1-23): 1

Babah: WiFiNetworkManagerTask
Ctrl+C to stop atack

[1] Connect to WiFiNetworkManagerTask...
```
Keeker
```powershell
PS C:\Users\UserOS\Desktop\PlumberKit> .\PlumberKit-keeker.ps1

[ SCAN NAMED PIPES ]

[E] InitShutdown
[E] lsass
[E] ntsvcs
[E] scerpc

[ STAT ]
Total pipes: 95
Pipes have any data: 0
Clean pipes: 0
No access: 0
Errors: 95
```

Twins
```powershell
PS C:\Users\UserOS\Desktop\PlumberKit> .\PlumberKit-twins.ps1
    InitShutdown
    lsass
    ntsvcs
    scerpc
    srvsvc
[+] WiFiNetworkManagerTask - DIGGED!
```
