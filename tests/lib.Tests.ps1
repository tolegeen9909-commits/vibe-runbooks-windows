#requires -Version 5.1

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot 'scripts\lib.ps1')
    $originalRunbookRoot = $script:RunbookRoot
}

AfterAll {
    $script:RunbookRoot = $originalRunbookRoot
}

Describe 'scripts/lib.ps1' {
    BeforeEach {
        $script:RunbookRoot = $TestDrive
        $stateDirectory = Join-Path $TestDrive 'state'
        New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $repoRoot 'state\progress-template.json') -Destination (Join-Path $stateDirectory 'progress-template.json')
    }

    It 'adds a line only once' {
        $path = Join-Path $TestDrive 'nested\ignore'

        (Add-LineOnce -Path $path -Line '.env') | Should -BeTrue
        (Add-LineOnce -Path $path -Line '.env') | Should -BeFalse
        @(Get-Content -LiteralPath $path) | Should -HaveCount 1
    }

    It 'initializes state without modifying the template' {
        $statePath = Initialize-RunbookState
        $state = Read-RunbookState

        $statePath | Should -Be (Join-Path $TestDrive 'state\progress.json')
        $state.schemaVersion | Should -Be 1
        @(Get-Content -LiteralPath (Join-Path $TestDrive 'state\progress-template.json')) | Should -Not -BeNullOrEmpty
    }

    It 'marks a completed step idempotently' {
        Mark-RunbookStep -Step 'test:done'
        Mark-RunbookStep -Step 'test:done'

        $state = Read-RunbookState
        @($state.completedSteps | Where-Object { $_ -eq 'test:done' }) | Should -HaveCount 1
        $state.lastCheckpoint | Should -Be 'test:done'
        (Get-Content -LiteralPath (Join-Path $TestDrive 'state\progress.log')) | Should -HaveCount 2
    }

    It 'adds and removes selected tracks without duplicates' {
        Set-RunbookTrack -Track flutter -Enabled $true
        Set-RunbookTrack -Track flutter -Enabled $true
        Set-RunbookTrack -Track web -Enabled $true
        Set-RunbookTrack -Track flutter -Enabled $false

        $state = Read-RunbookState
        @($state.selectedTracks) | Should -HaveCount 1
        @($state.selectedTracks)[0] | Should -Be 'web'
    }

    It 'stores and updates named artifacts without exposing them in the template' {
        Set-RunbookArtifact -Name 'netlifyPreviewUrl' -Value 'https://preview.example.test'
        Set-RunbookArtifact -Name 'netlifyPreviewUrl' -Value 'https://preview-2.example.test'

        (Get-RunbookArtifact -Name 'netlifyPreviewUrl') | Should -Be 'https://preview-2.example.test'
        (Get-RunbookArtifact -Name 'missing') | Should -BeNullOrEmpty
        $template = Get-Content -LiteralPath (Join-Path $TestDrive 'state\progress-template.json') -Raw | ConvertFrom-Json
        @($template.artifacts.PSObject.Properties) | Should -HaveCount 0
    }

    It 'returns the verification result from required checks' {
        (Complete-RunbookVerification -Phase test -Passed 2 -Required 2) | Should -BeTrue
        (Complete-RunbookVerification -Phase test -Passed 1 -Required 2 -Failures @('missing')) | Should -BeFalse
    }
}
