# GitHub Repository Dashboard
# Zeigt Downloads, Zugriffe, Issues, Kommentare und mehr fuer alle Repos an.
# Einfach per Doppelklick ausfuehren (siehe .bat-Datei).

$ErrorActionPreference = "Continue"
$owner = "HappyStarfish"

# Pruefe ob gh installiert und eingeloggt ist
$ghCheck = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FEHLER: GitHub CLI (gh) ist nicht eingeloggt oder nicht installiert."
    Write-Host "Installiere gh von https://cli.github.com/ und fuehre 'gh auth login' aus."
    Write-Host ""
    Read-Host "Druecke Enter zum Beenden"
    exit 1
}

function Write-Section($title) {
    $line = "=" * 60
    Write-Host ""
    Write-Host $line
    Write-Host "  $title"
    Write-Host $line
}

function Write-SubSection($title) {
    Write-Host ""
    Write-Host "--- $title ---"
}

# Repos abrufen
$repos = gh repo list $owner --limit 50 --json name,description,isPrivate,stargazerCount,forkCount,updatedAt | ConvertFrom-Json

if (-not $repos -or $repos.Count -eq 0) {
    Write-Host "Keine Repos gefunden."
    Read-Host "Druecke Enter zum Beenden"
    exit 0
}

Write-Host ""
Write-Host "GitHub Dashboard fuer: $owner"
Write-Host "Datum: $(Get-Date -Format 'dd.MM.yyyy HH:mm')"
Write-Host "Anzahl Repos: $($repos.Count)"

foreach ($repo in $repos) {
    $name = $repo.name
    Write-Section $name

    # Basis-Infos
    $vis = if ($repo.isPrivate) { "Privat" } else { "Oeffentlich" }
    $desc = if ($repo.description) { $repo.description } else { "(keine Beschreibung)" }
    Write-Host "Beschreibung: $desc"
    Write-Host "Sichtbarkeit: $vis"
    Write-Host "Sterne: $($repo.stargazerCount)"
    Write-Host "Forks: $($repo.forkCount)"
    Write-Host "Zuletzt aktualisiert: $($repo.updatedAt.Substring(0,10))"

    # Traffic / Zugriffe (letzte 14 Tage)
    Write-SubSection "Zugriffe (letzte 14 Tage)"
    try {
        $views = gh api "repos/$owner/$name/traffic/views" 2>$null | ConvertFrom-Json
        Write-Host "Seitenaufrufe gesamt: $($views.count)"
        Write-Host "Eindeutige Besucher: $($views.uniques)"
    } catch {
        Write-Host "(Keine Traffic-Daten verfuegbar)"
    }

    try {
        $clones = gh api "repos/$owner/$name/traffic/clones" 2>$null | ConvertFrom-Json
        Write-Host "Clones gesamt: $($clones.count)"
        Write-Host "Eindeutige Cloner: $($clones.uniques)"
    } catch {
        Write-Host "(Keine Clone-Daten verfuegbar)"
    }

    # Referrer (woher kommen Besucher)
    try {
        $referrers = gh api "repos/$owner/$name/traffic/popular/referrers" 2>$null | ConvertFrom-Json
        if ($referrers -and $referrers.Count -gt 0) {
            Write-SubSection "Top-Referrer (woher kommen Besucher)"
            foreach ($ref in $referrers) {
                Write-Host "- $($ref.referrer): $($ref.count) Aufrufe, $($ref.uniques) eindeutig"
            }
        }
    } catch {}

    # Beliebte Inhalte
    try {
        $paths = gh api "repos/$owner/$name/traffic/popular/paths" 2>$null | ConvertFrom-Json
        if ($paths -and $paths.Count -gt 0) {
            Write-SubSection "Beliebteste Seiten"
            foreach ($p in $paths | Select-Object -First 5) {
                Write-Host "- $($p.path): $($p.count) Aufrufe"
            }
        }
    } catch {}

    # Releases und Downloads
    Write-SubSection "Releases und Downloads"
    try {
        $releases = gh api "repos/$owner/$name/releases" 2>$null | ConvertFrom-Json
        if ($releases -and $releases.Count -gt 0) {
            $totalDownloads = 0
            foreach ($rel in $releases) {
                $relDate = $rel.published_at.Substring(0,10)
                $relDownloads = ($rel.assets | Measure-Object -Property download_count -Sum).Sum
                if (-not $relDownloads) { $relDownloads = 0 }
                $totalDownloads += $relDownloads
                Write-Host "- $($rel.tag_name) ($relDate): $relDownloads Downloads"
                foreach ($asset in $rel.assets) {
                    Write-Host "    $($asset.name): $($asset.download_count) Downloads"
                }
            }
            Write-Host "Downloads insgesamt: $totalDownloads"
        } else {
            Write-Host "(Keine Releases vorhanden)"
        }
    } catch {
        Write-Host "(Fehler beim Abrufen der Releases)"
    }

    # Issues
    Write-SubSection "Issues"
    try {
        $openIssues = gh api "repos/$owner/$name/issues?state=open&per_page=100" 2>$null | ConvertFrom-Json
        # GitHub API gibt auch Pull Requests als Issues zurueck, diese filtern
        $realIssues = $openIssues | Where-Object { -not $_.pull_request }
        $issueCount = if ($realIssues) { $realIssues.Count } else { 0 }
        Write-Host "Offene Issues: $issueCount"
        if ($realIssues -and $realIssues.Count -gt 0) {
            foreach ($issue in $realIssues | Select-Object -First 10) {
                $commentHint = if ($issue.comments -gt 0) { " ($($issue.comments) Kommentare)" } else { "" }
                Write-Host "- #$($issue.number): $($issue.title)$commentHint"
            }
        }
    } catch {
        Write-Host "(Fehler beim Abrufen der Issues)"
    }

    # Pull Requests
    Write-SubSection "Pull Requests"
    try {
        $prs = gh api "repos/$owner/$name/pulls?state=open&per_page=100" 2>$null | ConvertFrom-Json
        $prCount = if ($prs) { $prs.Count } else { 0 }
        Write-Host "Offene Pull Requests: $prCount"
        if ($prs -and $prs.Count -gt 0) {
            foreach ($pr in $prs | Select-Object -First 10) {
                Write-Host "- #$($pr.number): $($pr.title) (von $($pr.user.login))"
            }
        }
    } catch {
        Write-Host "(Fehler beim Abrufen der Pull Requests)"
    }

    # Neueste Kommentare (Issue-Kommentare + Commit-Kommentare)
    Write-SubSection "Neueste Kommentare"
    try {
        $comments = gh api "repos/$owner/$name/issues/comments?sort=created&direction=desc&per_page=5" 2>$null | ConvertFrom-Json
        if ($comments -and $comments.Count -gt 0) {
            foreach ($c in $comments) {
                $cDate = $c.created_at.Substring(0,10)
                # Issue-Nummer aus URL extrahieren
                $issueNum = ($c.issue_url -split "/")[-1]
                $preview = $c.body
                if ($preview.Length -gt 100) { $preview = $preview.Substring(0,100) + "..." }
                Write-Host "- $cDate von $($c.user.login) zu #${issueNum}:"
                Write-Host "  $preview"
            }
        } else {
            Write-Host "(Keine Kommentare vorhanden)"
        }
    } catch {
        Write-Host "(Fehler beim Abrufen der Kommentare)"
    }

    # Discussions (falls aktiviert)
    try {
        $discussions = gh api graphql -f query="query { repository(owner: `"$owner`", name: `"$name`") { discussions(first: 5, orderBy: {field: CREATED_AT, direction: DESC}) { totalCount nodes { title number author { login } comments { totalCount } } } } }" 2>$null | ConvertFrom-Json
        $discData = $discussions.data.repository.discussions
        if ($discData -and $discData.totalCount -gt 0) {
            Write-SubSection "Discussions"
            Write-Host "Gesamt: $($discData.totalCount)"
            foreach ($d in $discData.nodes) {
                $dComments = $d.comments.totalCount
                Write-Host "- #$($d.number): $($d.title) ($dComments Antworten)"
            }
        }
    } catch {}

    # Watchers / Subscribers
    try {
        $repoDetail = gh api "repos/$owner/$name" 2>$null | ConvertFrom-Json
        Write-SubSection "Weitere Statistiken"
        Write-Host "Beobachter (Watchers): $($repoDetail.subscribers_count)"
        Write-Host "Offene Issues (gesamt): $($repoDetail.open_issues_count)"
        Write-Host "Groesse: $([math]::Round($repoDetail.size / 1024, 1)) MB"
        Write-Host "Lizenz: $(if ($repoDetail.license) { $repoDetail.license.name } else { '(keine)' })"
        Write-Host "Hauptsprache: $(if ($repoDetail.language) { $repoDetail.language } else { '(keine)' })"
    } catch {}
}

Write-Host ""
Write-Host ("=" * 60)
Write-Host "  Dashboard fertig."
Write-Host ("=" * 60)
Write-Host ""
Read-Host "Druecke Enter zum Beenden"
