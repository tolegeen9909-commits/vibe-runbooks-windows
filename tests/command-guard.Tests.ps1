#requires -Version 5.1

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $guardPath = Join-Path $repoRoot 'scripts\command-guard.py'
    $python = (Get-Command python.exe -ErrorAction SilentlyContinue)
    if (-not $python) {
        $python = Get-Command python -ErrorAction SilentlyContinue
    }
}

Describe 'Windows command guard' {
    It 'has a Python runtime in CI' {
        $python | Should -Not -BeNullOrEmpty
    }

    It 'passes its complete built-in decision table' {
        $output = & $python.Path $guardPath --selftest 2>&1

        $LASTEXITCODE | Should -Be 0 -Because ($output -join "`n")
        $output | Should -Match 'fail=0'
    }

    It 'denies a destructive PowerShell command through the hook protocol' {
        $payload = @{ tool_name = 'PowerShell'; tool_input = @{ command = 'Remove-Item -Recurse -Force C:\' } } | ConvertTo-Json -Compress
        $output = $payload | & $python.Path $guardPath 2>&1

        $LASTEXITCODE | Should -Be 2
        $output | Should -Not -BeNullOrEmpty
    }

    It 'allows a normal build cleanup target' {
        $payload = @{ tool_name = 'PowerShell'; tool_input = @{ command = 'Remove-Item -Recurse -Force build' } } | ConvertTo-Json -Compress
        $payload | & $python.Path $guardPath 2>&1 | Out-Null

        $LASTEXITCODE | Should -Be 0
    }

    It 'denies nested output, redirection, and PowerShell script-block bypasses' {
        $commands = @(
            'Write-Output $(Remove-Item -Recurse -Force C:/)',
            'Write-Output secret > .env',
            'powershell.exe -Command "& { Remove-Item -Recurse -Force C:/ }"'
        )

        foreach ($command in $commands) {
            $payload = @{
                tool_name = 'PowerShell'
                tool_input = @{ command = $command }
            } | ConvertTo-Json -Compress
            $output = $payload | & $python.Path $guardPath 2>&1

            $LASTEXITCODE | Should -Be 2 -Because "'$command' must not bypass the guard; output: $($output -join ' ')"
        }
    }
}
