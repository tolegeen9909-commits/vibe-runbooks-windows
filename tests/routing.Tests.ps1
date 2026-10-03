#requires -Version 5.1

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $indexText = Get-Content -LiteralPath (Join-Path $repoRoot 'INDEX.md') -Raw
    $agentsText = Get-Content -LiteralPath (Join-Path $repoRoot 'AGENTS.md') -Raw
    $macIndexText = Get-Content -LiteralPath (Join-Path $repoRoot 'mac-mini-24x7\INDEX.md') -Raw

    $windowsRunbooks = @(
        '00-preflight\runbook.md',
        '01-windows-setup\runbook.md',
        '02-foundation\runbook.md',
        '03-git-github\runbook.md',
        '04-ai-helpers\runbook.md',
        '05-flutter\runbook.md',
        '06-first-win\runbook.md',
        '05w-netlify\runbook.md',
        '06w-first-site\runbook.md',
        '07-checkpoint\runbook.md',
        '99-appendix-backend\runbook.md'
    )

    $expectedFiles = @(
        'README.md', 'AGENTS.md', 'CLAUDE.md', 'FOR-CODEX.md', 'RITUALS.md',
        'INDEX.md', 'TROUBLESHOOTING.md', 'scripts\lib.ps1',
        'scripts\select-tracks.ps1',
        'scripts\test-secret-guard.ps1',
        'scripts\command-guard.py', 'state\progress-template.json',
        '00-preflight\runbook.md', '00-preflight\check-system.ps1', '00-preflight\verify.ps1',
        '01-windows-setup\runbook.md', '01-windows-setup\verify.ps1',
        '02-foundation\runbook.md', '02-foundation\verify.ps1',
        '03-git-github\runbook.md', '03-git-github\verify.ps1',
        '04-ai-helpers\runbook.md', '04-ai-helpers\verify.ps1',
        '05-flutter\runbook.md', '05-flutter\verify.ps1', '05-flutter\skip.ps1',
        '06-first-win\runbook.md', '06-first-win\verify.ps1',
        '05w-netlify\runbook.md', '05w-netlify\verify.ps1',
        '06w-first-site\runbook.md', '06w-first-site\verify.ps1',
        '07-checkpoint\runbook.md', '07-checkpoint\self-check.ps1',
        '99-appendix-backend\runbook.md',
        'mac-mini-24x7\AGENTS.md',
        'mac-mini-24x7\FOR-CODEX.md',
        'mac-mini-24x7\RITUALS.md',
        'mac-mini-24x7\INDEX.md',
        'mac-mini-24x7\runbook.md',
        'mac-mini-24x7\SOURCES.md',
        'mac-mini-24x7\TROUBLESHOOTING.md',
        'mac-mini-24x7\scripts\lib.sh',
        'mac-mini-24x7\scripts\record-checkpoint.sh',
        'mac-mini-24x7\state\progress-template.json',
        'mac-mini-24x7\tests\route.sh',
        'mac-mini-24x7\00-preflight\runbook.md',
        'mac-mini-24x7\00-preflight\check-system.sh',
        'mac-mini-24x7\01-macos-update\runbook.md',
        'mac-mini-24x7\02-power-24x7\runbook.md',
        'mac-mini-24x7\02-power-24x7\verify.sh',
        'mac-mini-24x7\03-ssh-termius\runbook.md',
        'mac-mini-24x7\03-ssh-termius\verify.sh',
        'mac-mini-24x7\04-anydesk\runbook.md',
        'mac-mini-24x7\04-anydesk\verify.sh',
        'mac-mini-24x7\05-tailscale\runbook.md',
        'mac-mini-24x7\05-tailscale\verify.sh',
        'mac-mini-24x7\06-recovery-security\runbook.md',
        'mac-mini-24x7\06-recovery-security\verify.sh',
        'mac-mini-24x7\07-reboot-checkpoint\runbook.md',
        'mac-mini-24x7\08-power-loss-headless\runbook.md',
        'mac-mini-24x7\09-development\runbook.md',
        'mac-mini-24x7\09-development\verify.sh',
        'mac-mini-24x7\10-final-checkpoint\runbook.md',
        'mac-mini-24x7\10-final-checkpoint\self-check.sh',
        '.github\workflows\macos.yml'
    )
}

Describe 'repository routing' {
    It 'contains every required route file' {
        foreach ($expectedFile in $expectedFiles) {
            Test-Path -LiteralPath (Join-Path $repoRoot $expectedFile) | Should -BeTrue -Because "$expectedFile is part of the published route"
        }
    }

    It 'routes by target machine without mixing platforms' {
        $agentsText | Should -Match 'Windows-маршрут'
        $agentsText | Should -Match 'Mac mini 24/7'
        $agentsText | Should -Match 'mac-mini-24x7/AGENTS\.md'
        $indexText | Should -Match 'mac-mini-24x7/INDEX\.md'
        $macIndexText | Should -Match '00-preflight'
        $macIndexText | Should -Match '10-final-checkpoint'
    }

    It 'mentions every Windows route phase in INDEX.md' {
        $phases = @(
            '00-preflight', '01-windows-setup', '02-foundation', '03-git-github',
            '04-ai-helpers', '05-flutter', '06-first-win', '05w-netlify',
            '06w-first-site', '07-checkpoint', '99-appendix-backend'
        )
        foreach ($phase in $phases) {
            $indexText | Should -Match ([regex]::Escape($phase))
        }
    }

    It 'keeps macOS commands out of Windows route documents' {
        $documents = @(
            (Join-Path $repoRoot 'README.md'),
            (Join-Path $repoRoot 'INDEX.md'),
            (Join-Path $repoRoot 'TROUBLESHOOTING.md')
        ) + @($windowsRunbooks | ForEach-Object { Join-Path $repoRoot $_ })

        $content = ($documents | ForEach-Object { Get-Content -LiteralPath $_ -Raw }) -join [Environment]::NewLine
        $content | Should -Not -Match '(?im)^\s*(?:brew|sudo|apt(?:-get)?)\s+'
        $content | Should -Not -Match '(?im)^\s*\./.+\.sh\b'
    }

    It 'keeps the Open Design rules in project AGENTS.md' {
        $agentsText | Should -Match 'Open Design MCP For Design Work'
        $agentsText | Should -Match 'open-design'
    }

    It 'keeps local progress out of Git' {
        $ignore = Get-Content -LiteralPath (Join-Path $repoRoot '.gitignore') -Raw
        $ignore | Should -Match 'state/progress\.json'
        $ignore | Should -Match 'state/progress\.log'
        $ignore | Should -Match 'mac-mini-24x7/state/progress\.json'
        $ignore | Should -Match 'mac-mini-24x7/state/progress\.log'
    }

    It 'documents the same publish switches that the scripts implement' {
        $flutterPublish = Get-Content -LiteralPath (Join-Path $repoRoot '06-first-win\first-edit-commit.ps1') -Raw
        $webPublish = Get-Content -LiteralPath (Join-Path $repoRoot '06w-first-site\publish-site.ps1') -Raw
        $flutterRunbook = Get-Content -LiteralPath (Join-Path $repoRoot '06-first-win\runbook.md') -Raw
        $webRunbook = Get-Content -LiteralPath (Join-Path $repoRoot '06w-first-site\runbook.md') -Raw

        $flutterPublish | Should -Match '\[switch\]\$Publish'
        $flutterRunbook | Should -Match 'first-edit-commit\.ps1 -Publish'
        foreach ($switch in @('Push', 'Preview', 'Production')) {
            $webPublish | Should -Match ('\[switch\]\$' + [regex]::Escape($switch))
            $webRunbook | Should -Match ('publish-site\.ps1 -' + [regex]::Escape($switch))
        }
    }

    It 'keeps strict phase and external-action invariants in the Windows checkpoint' {
        $checkpoint = Get-Content -LiteralPath (Join-Path $repoRoot '07-checkpoint\self-check.ps1') -Raw
        foreach ($marker in @(
            '00-preflight:verified', '01-windows-setup:verified', '02-foundation:verified',
            '03-git-github:verified', '04-ai-helpers:verified', 'tracks:selected-',
            '06-first-win:pushed', '06w-first-site:pushed', '06w-first-site:previewed',
            '06w-first-site:production'
        )) {
            $checkpoint | Should -Match ([regex]::Escape($marker))
        }
        $checkpoint | Should -Match '\$required = \$total'
    }

    It 'keeps critical Windows installer safeguards visible in source' {
        $preflight = Get-Content -LiteralPath (Join-Path $repoRoot '00-preflight\check-system.ps1') -Raw
        $pythonSetup = Get-Content -LiteralPath (Join-Path $repoRoot '03-git-github\setup-command-guard.ps1') -Raw
        $flutterSetup = Get-Content -LiteralPath (Join-Path $repoRoot '05-flutter\install-flutter.ps1') -Raw
        $netlifyPublish = Get-Content -LiteralPath (Join-Path $repoRoot '06w-first-site\publish-site.ps1') -Raw

        $preflight | Should -Match "Mark-RunbookStep '00-preflight:passed'"
        $pythonSetup | Should -Match 'WindowsApps'
        $pythonSetup | Should -Match 'import sys; print\(sys\.version_info\[0\]\)'
        $flutterSetup | Should -Match '\.partial'
        $flutterSetup | Should -Match 'Get-FileHash'
        $netlifyPublish | Should -Match 'Set-RunbookArtifact -Name \$artifactName'
        $netlifyPublish | Should -Match "'deploy', '--dir', '\.', '--json'"
    }
}
