#requires -Version 5.1

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $gitleaks = Get-Command gitleaks -ErrorAction SilentlyContinue
    if (-not $gitleaks) {
        $wingetCommand = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\gitleaks.exe'
        if (Test-Path -LiteralPath $wingetCommand) {
            $gitleaks = Get-Command $wingetCommand
        }
    }
}

Describe 'secret guard' {
    It 'installs and configures the expected guard' {
        $scriptText = Get-Content -LiteralPath (Join-Path $repoRoot '03-git-github\setup-secret-guard.ps1') -Raw

        $scriptText | Should -Match 'Gitleaks\.Gitleaks'
        $scriptText | Should -Match 'vibe-runbooks-windows:gitleaks'
        $scriptText | Should -Match 'gitleaks git --pre-commit --staged'
        $scriptText | Should -Match 'core\.hooksPath'
        $scriptText | Should -Match 'test-secret-guard\.ps1'
    }

    It 'ignores private env files but keeps safe templates' {
        Push-Location $repoRoot
        try {
            & git check-ignore --quiet --no-index -- .env
            $privateExit = $LASTEXITCODE
            & git check-ignore --quiet --no-index -- .env.example
            $templateExit = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $privateExit | Should -Be 0
        $templateExit | Should -Be 1
    }

    It 'has Gitleaks available in Windows CI' {
        $gitleaks | Should -Not -BeNullOrEmpty
    }

    It 'blocks a staged test secret' {
        $repository = Join-Path $TestDrive 'leak-repository'
        New-Item -ItemType Directory -Path $repository | Out-Null
        Push-Location $repository
        try {
            & git init --quiet
            $testToken = 'ghp_' + '1234567890' + 'abcdefghijklmnopqrstuvwxyz'
            "github_token=$testToken" | Set-Content -LiteralPath 'leak.txt' -Encoding Ascii
            & git add leak.txt
            & $gitleaks.Source git --pre-commit --staged --redact --no-banner *> $null
            $scanExit = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $scanExit | Should -Be 1
    }

    It 'allows normal staged content' {
        $repository = Join-Path $TestDrive 'safe-repository'
        New-Item -ItemType Directory -Path $repository | Out-Null
        Push-Location $repository
        try {
            & git init --quiet
            'hello from Windows' | Set-Content -LiteralPath 'README.md' -Encoding UTF8
            & git add README.md
            & $gitleaks.Source git --pre-commit --staged --redact --no-banner *> $null
            $scanExit = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $scanExit | Should -Be 0
    }
}
