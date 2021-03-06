<#
DISKSPD - VM Fleet

Copyright(c) Microsoft Corporation
All rights reserved.

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

param(
    [string[]] $group = @('*'),
    [ValidateSet('Save','Shutdown','TurnOff')][string] $method = 'Shutdown'
    )

icm (get-clusternode |? State -eq Up) -arg $group,$method {
    param([string[]] $group, $method)

    $group |% {

        $g = Get-ClusterGroup |? GroupType -eq VirtualMachine |? OwnerNode -eq $env:COMPUTERNAME |? Name -like "vm-$_-*" |? State -ne 'Offline'

        # stop-clustergroup currently defaults to vm save
        # use remoted stop-vm for the shutdown case
        if ($method -eq 'Save') {
            $g | Stop-ClusterGroup
        } elseif ($method -eq 'TurnOff') {
            $g |% { Stop-VM -ComputerName $_.OwnerNode -Name $_.Name -Force -TurnOff }
        } else {
            $g |% { Stop-VM -ComputerName $_.OwnerNode -Name $_.Name -Force }
        }
    }
} | ft -AutoSize
