#requires -Version 5.1

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot 'scripts\lib.ps1')
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
        (Get-GitleaksHookContent) | Should -Match 'vibe-runbooks-windows:gitleaks'
        (Get-GitleaksHookContent) | Should -Match 'gitleaks git --pre-commit --staged'
        (Get-GitleaksHookContent) | Should -Match 'gitleaks is unavailable; commit was blocked'
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

    It 'blocks a secret through the actual Git pre-commit hook and allows safe content' {
        $repository = Join-Path $TestDrive 'leak-repository'
        New-Item -ItemType Directory -Path $repository | Out-Null
        Push-Location $repository
        try {
            & git init --quiet
            & git config user.name 'Vibe Runbooks Test'
            & git config user.email 'test@example.invalid'
            & git config commit.gpgsign false
            $hooksDirectory = Join-Path $repository '.test-hooks'
            New-Item -ItemType Directory -Path $hooksDirectory | Out-Null
            (Get-GitleaksHookContent) | Set-Content -LiteralPath (Join-Path $hooksDirectory 'pre-commit') -Encoding Ascii
            & git config core.hooksPath $hooksDirectory
            'baseline' | Set-Content -LiteralPath 'README.md' -Encoding Ascii
            & git add README.md
            & git commit --quiet -m 'test: baseline'
            $baselineHead = (& git rev-parse HEAD | Out-String).Trim()

            $testToken = 'AK' + 'IA' + 'Q7W6E5R4T3Y2U7I6'
            "aws_access_key_id=$testToken" | Set-Content -LiteralPath 'leak.txt' -Encoding Ascii
            & git add leak.txt
            & git commit --quiet -m 'test: must be blocked' *> $null
            $blockedExit = $LASTEXITCODE
            $headAfterBlockedCommit = (& git rev-parse HEAD | Out-String).Trim()

            & git reset --quiet HEAD
            'hello from Windows' | Set-Content -LiteralPath 'safe.txt' -Encoding UTF8
            & git add safe.txt
            & git commit --quiet -m 'test: safe content'
            $safeExit = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $blockedExit | Should -Not -Be 0
        $headAfterBlockedCommit | Should -Be $baselineHead
        $safeExit | Should -Be 0
    }
}
