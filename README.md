![Banner](Images/banner.png?)

# EeveeSpotifyReincarnated (Auto-Sync Fork)

**Maintainers:** [jaydenjcpy](https://github.com/jaydenjcpy) & [faroukbmiled](https://github.com/faroukbmiled) & [Mod4](https://github.com/M0d-4) <br />
**Last Update:** `8/02/26` **Spotify Version:** `9.1.68`

This tweak makes Spotify think you have a Premium subscription, granting free listening, just like Spotilife, and provides some additional features like custom lyrics.

This is a fork of [SideloadLabs/EeveeSpotifyReincarnated](https://github.com/SideloadLabs/EeveeSpotifyReincarnated) with an added **automated CI/CD pipeline**: it syncs itself with upstream, builds `.deb`/`.ipa` packages, scans them for malware, and publishes everything to Releases — without you running anything by hand. See [Automated Sync & Build](#automated-sync--build-cicd) below.

> [!NOTE]
> The original EeveeSpotify repository was disabled due to a [DMCA takedown](https://github.com/github/dmca/blob/master/2025/08/2025-08-14-spotify.md). This repository will not contain IPA packages in the repo itself.

🇬🇧 English (this section) | 🇷🇺 [Русская версия ниже](#-eeveespotifyreincarnated-форк-с-автосинхронизацией)

## Custom Lyrics Support

**Spotify 9.1.56 and above** - Full custom lyrics functionality is available with the following providers:
- **Spicy Lyrics**
- **Musixmatch(Requires Musixmatch Token)**
- **PetitLyrics**
- **LRCLIB**
- **Genius**

> [!NOTE]
> All providers work now

## How to build an EeveeSpotify IPA using Github actions
> [!NOTE]
> If this your first time, complete following steps before starting:
>
> 1. Fork this repository using the fork button on the top right
> 2. On your forked repository, go to **Repository Settings** > **Actions**, enable **Read and Write** permissions.

<details>
  <summary>How to build the EeveeSpotify IPA (manual, one-off)</summary>
  <ol>
    <li>Click on <strong>Sync fork</strong>, and if your branch is out-of-date, click on <strong>Update branch</strong>.</li>
    <li>Navigate to the <strong>Actions tab</strong> in your forked repository and select <strong>Create IPA Packages</strong> if you're on desktop/widescreen. Tap on <strong>All Workflows</strong> and select <strong>Create IPA Packages</strong> if you're on mobile/portrait.</li>
    <li>Click the <strong>Run workflow</strong> button located on the right side.</li>
    <li>Prepare a decrypted .ipa file <em>(we cannot provide this due to legal reasons)</em>, then upload it to a file provider (e.g., filebin.net, filemail.com, or Dropbox is recommended). Paste the URL of the decrypted IPA file in the provided field.</li>
    <li><strong>NOTE:</strong> Make sure to provide a direct download link to the file, not a link to a webpage. Otherwise, the process will fail.</li>
    <li>Go to the releases page of the EeveeSpotify repository (<strong>NOT</strong> the fork). Hold and copy the link of the .deb file, which corresponds to your phone's architecture.</li>
    <li>Make sure all inputs are correct, then click <strong>Run workflow</strong> to start the process.</li>
    <li>Wait for the build to finish. You can download the EeveeSpotify IPA from the releases section of your forked repo. (If you can't find the releases section, go to your forked repo and add /releases to the URL, i.e., github.com/user/EeveeSpotifyReborn/releases.)</li>
  </ol>
</details>

There are a few other specialized manual workflows in `.github/workflows/` for advanced use, if you'd rather not wait for the automated pipeline:
- **`builddeb.yml`** ("Build rootless + RootHide .debs + Draft Release") — builds both a rootless and a RootHide `.deb` in one go and drafts a release.
- **`buildnopatch.yml`** / **`buildpatched.yml`** — build from any branch, with a choice of uploading to a workflow artifact or filebin.net instead of a Release.

## Automated Sync & Build (CI/CD)

This fork adds `.github/workflows/auto-sync-and-build.yml` — a pipeline that keeps your fork in sync with upstream and publishes ready-to-install builds automatically, with no manual steps once it's set up.

### What it does, end to end

1. **Sync** — checks the latest tag on [SideloadLabs/EeveeSpotifyReincarnated](https://github.com/SideloadLabs/EeveeSpotifyReincarnated). If a release for that tag doesn't already exist in your fork, it fast-forwards your `Master` branch to match upstream and pushes it.
2. **Build** — compiles the tweak and packages a rootless `.deb`. If a decrypted Spotify IPA is available (see [Secrets](#secrets) below), it also injects the tweak and produces a ready-to-sideload `.ipa`.
3. **Scan** — every relevant file is scanned for malware **twice**: right after download (before any patching) and again on the final built files (after patching). See [Antivirus scanning](#antivirus-scanning).
4. **Release** — publishes (or updates) a GitHub Release tagged with the upstream version. The `.deb`, the `.ipa` (when built), and both scan reports are attached, and the release description itself contains a build summary and the scan results — no need to download anything just to check what happened.

If something's missing or only partially works (no decrypted IPA configured, the IPA turns out to still be encrypted, the URL is bad/expired, antivirus flags something) **the pipeline does not just fail and stop** — it still publishes whatever it *could* build, and explains exactly what happened and why, right in the release notes.

### Triggers

- **Schedule** — runs automatically every day at 03:00 UTC.
- **`workflow_dispatch`** — run it manually any time from the *Actions* tab.
- **Push to `.github/ci-trigger-sync.txt`** — committing anything to that file also triggers a run (a quick way to kick off a sync from git without opening the Actions UI).

### `workflow_dispatch` inputs

| Input | What it means |
|---|---|
| **`force_build`** *("Build even if upstream has no new tag")* | By default, the pipeline only rebuilds when upstream has a tag that isn't released in your fork yet — this avoids burning CI minutes rebuilding something that's already published. Turn this **on** to force a rebuild/republish of the *current* tag anyway. You need this after changing the `VANILLA_IPA_URL` secret (so the IPA actually gets built this time), or whenever you just want to re-run the pipeline for testing — otherwise it'll just see "already released" and skip straight past the build. |
| **`ipa_url`** *("Override: direct URL to a decrypted Spotify IPA (defaults to the VANILLA_IPA_URL secret)")* | Lets you pass a decrypted IPA link for **this one run only**, without touching the `VANILLA_IPA_URL` secret. Leave it empty to fall back to the secret. |

### Secrets

Add these under **Settings → Secrets and variables → Actions → New repository secret**. Also check **Settings → Actions → General → Workflow permissions** is set to **Read and write**.

| Secret | Required? | What goes in it |
|---|---|---|
| **`GH_PAT`** | Yes, for the sync step | A [Personal Access Token](https://github.com/settings/tokens) (classic, with `repo` + `workflow` scopes) from your own account. The auto-generated `GITHUB_TOKEN` that Actions provides can't push commits that touch files under `.github/workflows/` — which the sync step's own merge does — so a real PAT is required to push the updated `Master` branch back to your fork. |
| **`VANILLA_IPA_URL`** | No, but required to also get an `.ipa` | A **direct download link** to your own **already-decrypted** Spotify `.ipa`. GitHub Actions has no way to decrypt Apple's FairPlay DRM itself — you have to dump a decrypted copy yourself from your own jailbroken device (e.g. with `frida-ios-dump` or `bagbak`), upload it somewhere (filebin.net, your own storage, etc.), and put the **direct file URL** here — not a link to a webpage. Without this secret the pipeline still runs fine, it just publishes the `.deb` only. |
| **`VT_API_KEY`** | No | A free [VirusTotal](https://www.virustotal.com/) API key (sign up → your profile icon → API Key). Free tier limits: 4 requests/min, 500/day. Enables real, automatic malware scanning on every build. Without it, ClamAV scanning still runs (it never needs a key), and the VirusTotal section of the report just gives you a link to check/upload the file yourself instead of doing it automatically. |

### Antivirus scanning

Every IPA gets scanned **twice**:
- **Before patching** — the vanilla IPA you provided, right after it's downloaded.
- **After patching** — the final `.deb` and `.ipa` that actually get released.

Two engines:
- **ClamAV** — always runs locally on the build runner, no account or key needed.
- **VirusTotal** — runs automatically (uploads the file, waits for all engines to finish) if `VT_API_KEY` is set. If it's not set, that section is skipped with a note, and you instead get a direct link to look the file up (or upload it yourself) on virustotal.com. Note: a freshly patched file almost never has a prior VirusTotal record, so that link will usually say "Item not found" until you either configure the key or upload it yourself.

Both reports are attached to the release as `.md` files **and** their full content is embedded directly in the release description, so you can see exactly what was found without downloading anything. If anything gets flagged as malicious or suspicious, the run still completes and publishes normally (so the evidence is actually reachable), but the release gets a prominent **⚠️ SECURITY WARNING** section and the job log shows `::error::` annotations pointing at the specific finding.

### Ready builds always land in Releases

Every successful run ends up on your fork's **[Releases](../../releases)** page, tagged with the upstream version (e.g. `v6.6.7`). Attached to that one release: the `.deb`, the `.ipa` (when a decrypted source was available), and both scan reports — plus a build summary (EeveeSpotify version, patched Spotify version, file sizes, scan results) directly in the release description.

### Rebuilding just the IPA (`auto-build-ipa.yml`)

Already have a release with a `.deb` attached and just want to (re)attach an `.ipa` — without re-running the whole sync+build pipeline? Run `.github/workflows/auto-build-ipa.yml` manually:

| Input | Meaning |
|---|---|
| **`tag`** | The existing release tag to attach the IPA to (required). |
| **`ipa_url`** | Direct URL to a decrypted Spotify IPA. Leave empty to use the `VANILLA_IPA_URL` secret. |

It grabs the `.deb` already attached to that release, patches it into the given IPA, and uploads the resulting `.ipa` to the same release.

## The History

In January 2024, Spotilife, the only tweak to get Spotify Premium, stopped working on new Spotify versions. [whoeevee](https://github.com/whoeevee) decompiled Spotilife, reverse-engineered Spotify, intercepted requests, etc., and created this tweak.

In December 2025, whoeevee, the maintainer of the EeveeSpotify tweak at the time, announced he'll be discontinuing the tweak because of the burden of keeping up with Spotify's constantly changing architectures. Soon after, [Meep1](https://github.com/Meeep1), forks the original Eevee repo and continues to develop the tweak to support newer Spotify versions, under the project name EeveeSpotiyRevivedPublic.

In  March 2026, the latest EeveeSpotifyRevivedPublic release, v9.1.28, users experienced constant logging out issues and reported to Skye, however, at the time of this README.md written, EeveeSpotifyRevivedPublic hasn't released any newer updates. During March, I've been constantly annoyed by the logout issue and decided to take matters into my own hands and forked EeveeSpotifyRevivedPublic and fixed the logout issue, which will eventually lead to the creation of this repository, which will be continuing the legacy of EeveeSpotify for newer versions of Spotify.

## Restrictions

Please refrain from opening issues about the following features, as they are server-sided and will **NEVER** work:

- Very High audio quality
- Native playlist downloading (you can download podcast episodes though)
- Jam (hosting a Spotify Jam and joining it remotely requires Premium; only joining in-person works)
- AI DJ/Playlist
- Spotify Connect (When using Spotify Connect, the device will act as a remote control and stream directly to the connected device. This is a server-sided limitation and is beyond the control of EeveeSpotify, so it will behave as if you have a Free subscription while using this feature.)

## [Common Issues](https://github.com/jaydenjcpy/EeveeSpotifyReincarnated/blob/Master/common_issues.md)
Please check out the hyperlink above before opening an issue

## Lyrics Support

EeveeSpotify replaces Spotify monthly limited lyrics with one of the following four lyrics providers:

- Genius: Offers the best quality lyrics, provides the most songs, and updates lyrics the fastest. Does not and will never be time-synced.

- LRCLIB: The most open service, offering time-synced lyrics. However, it lacks lyrics for many songs.

- Musixmatch: The service Spotify uses. Provides time-synced lyrics for many songs, but you'll need a user token to use this source. To obtain the token, download Musixmatch from the App Store, sign up, then go to Settings > Get help > Copy debug info, and paste it into EeveeSpotify alert. You can also extract the token using MITM.

- PetitLyrics: Offers plenty of time-synced Japanese and some international lyrics.

If the tweak is unable to find a song or process the lyrics, you'll see a "Couldn't load the lyrics for this song" message. The lyrics might be wrong for some songs when using Genius due to how the tweak searches songs. While I've made it work in most cases, kindly refrain from opening issues about it.

## How It Works

EeveeSpotify intercepts Spotify requests to load user data, deserializes it, and modifies the parameters in real-time. This method works incredibly stable across supported Spotify versions.

The tweak also sets `trackRowsEnabled` to `true`, allowing you to see track rows and liked tracks on artist pages just like with Premium.

## Installation

For sideloaded IPAs, we recommend using **SideStore** or certificate-based signing tools like **Ksign** for best compatibility.

To open Spotify links in sideloaded app, use [OpenSpotifySafariExtension](https://github.com/BillyCurtis/OpenSpotifySafariExtension). Remember to activate it and allow access in Settings > Safari > Extensions.

## Credits
Thanks for all of the community's support, also, thanks to all the devs who worked along with me to revive this project Go check the other dev's out:

[Ryuk](https://github.com/faroukbmiled)

[Mod4](https://github.com/M0d-4)

[estrogencat](https://github.com/estrogencat)

[Skye](https://github.com/Meeep1)

[whoeevee](https://github.com/whoeevee)

## Disclaimer

This project is an **independent modification (tweak)** for the Spotify app. We are **not affiliated, associated, authorized, endorsed by, or in any way officially connected with Spotify**, or any of its subsidiaries or affiliates.

This tweak is created solely for **personal and educational purposes**. Use it at your own risk.

**We do not take any responsibility for any issues, damages, or consequences** resulting from the use or misuse of this tweak. If something breaks, it's not our problem.

## Star History

<a href="https://www.star-history.com/?repos=SideloadLabs%2FEeveeSpotifyReincarnated&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=SideloadLabs/EeveeSpotifyReincarnated&type=date&theme=dark&legend=top-left&sealed_token=C1hKWTv3UNdLAgsZjjCL7Rthp6YSGB4Mm9kIalnH1lgZXZnYVL09WbBt57E-FFzQXg8gZyFOW356S5XMTWmvQdIuEihF66WxqGuJTejmAdJx5XJHxC2l3A" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=SideloadLabs/EeveeSpotifyReincarnated&type=date&legend=top-left&sealed_token=C1hKWTv3UNdLAgsZjjCL7Rthp6YSGB4Mm9kIalnH1lgZXZnYVL09WbBt57E-FFzQXg8gZyFOW356S5XMTWmvQdIuEihF66WxqGuJTejmAdJx5XJHxC2l3A" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=SideloadLabs/EeveeSpotifyReincarnated&type=date&legend=top-left&sealed_token=C1hKWTv3UNdLAgsZjjCL7Rthp6YSGB4Mm9kIalnH1lgZXZnYVL09WbBt57E-FFzQXg8gZyFOW356S5XMTWmvQdIuEihF66WxqGuJTejmAdJx5XJHxC2l3A" />
 </picture>
</a>

---

# 🇷🇺 EeveeSpotifyReincarnated (форк с автосинхронизацией)

**Мейнтейнеры:** [jaydenjcpy](https://github.com/jaydenjcpy) & [faroukbmiled](https://github.com/faroukbmiled) & [Mod4](https://github.com/M0d-4) <br />
**Последнее обновление:** `8/02/26` **Версия Spotify:** `9.1.68`

Этот твик заставляет Spotify думать, что у вас есть Premium-подписка — бесплатное прослушивание без ограничений, как в Spotilife, плюс дополнительные функции вроде кастомных текстов песен.

Это форк [SideloadLabs/EeveeSpotifyReincarnated](https://github.com/SideloadLabs/EeveeSpotifyReincarnated) с добавленным **автоматическим CI/CD-пайплайном**: он сам синхронизируется с апстримом, собирает пакеты `.deb`/`.ipa`, проверяет их антивирусом и публикует всё в Releases — без ручного запуска каждого шага. Подробности — в разделе [Автоматическая синхронизация и сборка](#автоматическая-синхронизация-и-сборка-cicd) ниже.

> [!NOTE]
> Оригинальный репозиторий EeveeSpotify был отключён из-за [DMCA-жалобы](https://github.com/github/dmca/blob/master/2025/08/2025-08-14-spotify.md). Этот репозиторий не хранит IPA-пакеты в самом себе.

## Поддержка кастомных текстов песен

**Spotify 9.1.56 и выше** — полностью работает поддержка текстов песен со следующими провайдерами:
- **Spicy Lyrics**
- **Musixmatch (требует токен Musixmatch)**
- **PetitLyrics**
- **LRCLIB**
- **Genius**

> [!NOTE]
> Все провайдеры сейчас работают

## Как собрать EeveeSpotify IPA через GitHub Actions
> [!NOTE]
> Если это твой первый раз, сначала выполни следующие шаги:
>
> 1. Сделай форк этого репозитория кнопкой Fork в правом верхнем углу
> 2. В своём форке зайди в **Repository Settings** → **Actions** и включи разрешения **Read and Write**

<details>
  <summary>Как собрать EeveeSpotify IPA вручную (разовая сборка)</summary>
  <ol>
    <li>Нажми <strong>Sync fork</strong>, и если ветка отстала — нажми <strong>Update branch</strong>.</li>
    <li>Перейди во вкладку <strong>Actions</strong> в своём форке и выбери <strong>Create IPA Packages</strong> (на мобильном — сначала <strong>All Workflows</strong>).</li>
    <li>Нажми <strong>Run workflow</strong> справа.</li>
    <li>Подготовь дешифрованный .ipa-файл <em>(мы не можем предоставить его по юридическим причинам)</em>, загрузи его на файлообменник (filebin.net, filemail.com или Dropbox), и вставь прямую ссылку в поле.</li>
    <li><strong>ВАЖНО:</strong> ссылка должна вести прямо на файл, а не на страницу — иначе сборка не пройдёт.</li>
    <li>Зайди на страницу релизов оригинального репозитория EeveeSpotify (<strong>НЕ</strong> форка) и скопируй ссылку на .deb-файл под архитектуру своего телефона.</li>
    <li>Проверь все поля и нажми <strong>Run workflow</strong>.</li>
    <li>Дождись завершения сборки — готовый IPA появится в разделе Releases твоего форка (если не находишь его — добавь <code>/releases</code> к адресу репозитория).</li>
  </ol>
</details>

В `.github/workflows/` есть ещё несколько специализированных ручных workflow для продвинутых случаев, если не хочешь ждать автоматический пайплайн:
- **`builddeb.yml`** ("Build rootless + RootHide .debs + Draft Release") — собирает сразу rootless и RootHide `.deb` и создаёт черновик релиза.
- **`buildnopatch.yml`** / **`buildpatched.yml`** — сборка с любой ветки, с выбором — выгружать в артефакт workflow или на filebin.net вместо релиза.

## Автоматическая синхронизация и сборка (CI/CD)

Этот форк добавляет `.github/workflows/auto-sync-and-build.yml` — пайплайн, который сам держит форк в актуальном состоянии и публикует готовые к установке сборки, без единого ручного шага после настройки.

### Что он делает, от начала до конца

1. **Синхронизация** — проверяет последний тег апстрима [SideloadLabs/EeveeSpotifyReincarnated](https://github.com/SideloadLabs/EeveeSpotifyReincarnated). Если релиза с таким тегом в твоём форке ещё нет, перематывает ветку `Master` вперёд до апстрима и пушит её.
2. **Сборка** — компилирует твик и собирает rootless `.deb`. Если доступен дешифрованный Spotify IPA (см. [Секреты](#секреты) ниже) — также внедряет твик и собирает готовый к сайдлоаду `.ipa`.
3. **Проверка антивирусом** — каждый релевантный файл сканируется **дважды**: сразу после скачивания (до патча) и ещё раз на итоговых собранных файлах (после патча). Подробнее — [Антивирус-проверка](#антивирус-проверка).
4. **Публикация релиза** — создаёт (или обновляет) GitHub Release с тегом версии апстрима. К релизу прикрепляются `.deb`, `.ipa` (если собрался) и оба отчёта сканирования, а само описание релиза содержит сводку сборки и результаты сканов — не нужно ничего скачивать, чтобы проверить, что произошло.

Если чего-то не хватает или получилось не всё (не настроен дешифрованный IPA, IPA оказался всё ещё зашифрован, ссылка битая/протухла, антивирус что-то нашёл) — **пайплайн не просто падает и останавливается**: он всё равно публикует то, что смог собрать, и подробно объясняет прямо в описании релиза, что случилось и почему.

### Триггеры запуска

- **По расписанию** — автоматически каждый день в 03:00 UTC.
- **`workflow_dispatch`** — запуск вручную в любой момент из вкладки *Actions*.
- **Push в `.github/ci-trigger-sync.txt`** — любой коммит в этот файл тоже запускает прогон (удобный способ "пнуть" синхронизацию из git, не открывая интерфейс Actions).

### Параметры `workflow_dispatch`

| Параметр | Что означает |
|---|---|
| **`force_build`** *("Build even if upstream has no new tag" — собрать, даже если у апстрима нет нового тега)* | По умолчанию пайплайн пересобирает только тогда, когда у апстрима есть тег, для которого в твоём форке ещё нет релиза — это не тратит время CI на пересборку уже опубликованной версии. Включи этот параметр, чтобы принудительно пересобрать и переопубликовать **текущий** тег заново. Это нужно после смены секрета `VANILLA_IPA_URL` (иначе IPA в этот раз просто не соберётся), или когда хочешь перезапустить пайплайн для теста — без этого флага workflow увидит "уже опубликовано" и сразу пропустит сборку. |
| **`ipa_url`** *("Override: direct URL to a decrypted Spotify IPA (defaults to the VANILLA_IPA_URL secret)" — переопределение: прямая ссылка на дешифрованный Spotify IPA, по умолчанию берётся из секрета VANILLA_IPA_URL)* | Позволяет передать ссылку на дешифрованный IPA **только для этого одного прогона**, не трогая секрет `VANILLA_IPA_URL`. Оставь пустым, чтобы использовать значение из секрета. |

### Секреты

Добавляются в **Settings → Secrets and variables → Actions → New repository secret**. Также проверь, что в **Settings → Actions → General → Workflow permissions** стоит **Read and write**.

| Секрет | Обязателен? | Что туда класть |
|---|---|---|
| **`GH_PAT`** | Да, для шага синхронизации | [Personal Access Token](https://github.com/settings/tokens) (classic, со scope `repo` + `workflow`) от твоего аккаунта. Автоматический `GITHUB_TOKEN`, который Actions выдаёт сам, не может пушить коммиты, затрагивающие файлы в `.github/workflows/` — а именно это делает мёрж на шаге синхронизации, поэтому нужен настоящий PAT, чтобы запушить обновлённую ветку `Master` обратно в форк. |
| **`VANILLA_IPA_URL`** | Нет, но нужен, чтобы получить ещё и `.ipa` | **Прямая ссылка на скачивание** твоего собственного **уже дешифрованного** Spotify `.ipa`. GitHub Actions не умеет сам снимать FairPlay-защиту Apple — дешифрованную копию нужно снять самостоятельно с собственного джейлбрейкнутого устройства (например, через `frida-ios-dump` или `bagbak`), загрузить куда-нибудь (filebin.net, своё хранилище и т.п.) и указать здесь **прямую ссылку на файл** — не на страницу. Без этого секрета пайплайн всё равно нормально работает, просто публикует только `.deb`. |
| **`VT_API_KEY`** | Нет | Бесплатный API-ключ [VirusTotal](https://www.virustotal.com/) (регистрация → иконка профиля → API Key). Лимиты бесплатного тарифа: 4 запроса/мин, 500/день. Включает настоящее автоматическое сканирование каждой сборки на вредоносность. Без ключа ClamAV всё равно работает (ему ключ не нужен), а раздел VirusTotal в отчёте просто даёт ссылку, чтобы проверить/загрузить файл вручную, вместо автоматической проверки. |

### Антивирус-проверка

Каждый IPA сканируется **дважды**:
- **До патча** — исходный (vanilla) IPA сразу после скачивания.
- **После патча** — итоговые `.deb` и `.ipa`, которые реально попадают в релиз.

Два движка:
- **ClamAV** — всегда запускается локально на раннере сборки, ключ/аккаунт не нужен.
- **VirusTotal** — запускается автоматически (загружает файл и ждёт, пока все движки закончат), если задан `VT_API_KEY`. Если не задан — этот раздел пропускается с пометкой, а вместо результата даётся прямая ссылка, чтобы проверить/загрузить файл вручную на virustotal.com. Важно: у свежесобранного файла почти никогда нет предыдущей записи на VirusTotal, поэтому ссылка обычно покажет "Item not found", пока не настроишь ключ или не загрузишь файл сам.

Оба отчёта прикрепляются к релизу как `.md`-файлы, **и** их полное содержимое встраивается прямо в описание релиза — результаты видно сразу, без скачивания. Если что-то помечено как вредоносное или подозрительное, прогон всё равно завершается и публикуется нормально (чтобы находку реально можно было увидеть), но в релизе появляется заметный раздел **⚠️ SECURITY WARNING**, а в логах джобы — аннотации `::error::` с указанием конкретной находки.

### Готовые сборки всегда попадают в Releases

Каждый успешный прогон оказывается на странице **[Releases](../../releases)** твоего форка, с тегом версии апстрима (например, `v6.6.7`). К этому релизу прикреплены: `.deb`, `.ipa` (если был доступен дешифрованный источник) и оба отчёта сканирования — плюс сводка сборки (версия EeveeSpotify, версия пропатченного Spotify, размеры файлов, результаты сканов) прямо в описании релиза.

### Пересобрать только IPA (`auto-build-ipa.yml`)

Если релиз с `.deb` уже есть и нужно просто (пере)прикрепить к нему `.ipa` — без перезапуска всего пайплайна синхронизации и сборки — запусти `.github/workflows/auto-build-ipa.yml` вручную:

| Параметр | Значение |
|---|---|
| **`tag`** | Тег существующего релиза, к которому нужно прикрепить IPA (обязателен). |
| **`ipa_url`** | Прямая ссылка на дешифрованный Spotify IPA. Оставь пустым, чтобы использовать секрет `VANILLA_IPA_URL`. |

Скрипт берёт `.deb`, уже прикреплённый к этому релизу, встраивает его в переданный IPA и загружает получившийся `.ipa` в тот же релиз.

## История

В январе 2024 года Spotilife — единственный твик, дававший Spotify Premium — перестал работать на новых версиях Spotify. [whoeevee](https://github.com/whoeevee) декомпилировал Spotilife, реверс-инжинирил Spotify, перехватывал запросы и создал этот твик.

В декабре 2025 года whoeevee, на тот момент мейнтейнер твика EeveeSpotify, объявил о прекращении разработки — слишком тяжело поддерживать твик под постоянно меняющуюся архитектуру Spotify. Вскоре после этого [Meep1](https://github.com/Meeep1) сделал форк оригинального репозитория Eevee и продолжил разработку под новые версии Spotify, под названием EeveeSpotiyRevivedPublic.

В марте 2026 года, после последнего релиза EeveeSpotifyRevivedPublic (v9.1.28), пользователи столкнулись с постоянными вылетами из аккаунта и сообщали об этом Skye, однако на момент написания этого README новых обновлений EeveeSpotifyRevivedPublic не выходило. Автора этого форка проблема разлогина настолько достала, что он форкнул EeveeSpotifyRevivedPublic и исправил её сам — так появился этот репозиторий, продолжающий наследие EeveeSpotify для новых версий Spotify.

## Ограничения

Пожалуйста, не открывай issue по следующим функциям — они завязаны на сервер Spotify и **никогда** не заработают:

- Качество звука Very High
- Нативное скачивание плейлистов (эпизоды подкастов скачать можно)
- Jam (хостинг Spotify Jam и удалённое присоединение требуют Premium; работает только присоединение "вживую")
- AI DJ/плейлист
- Spotify Connect (в этом режиме устройство работает как пульт и стримит напрямую на подключённое устройство — это серверное ограничение вне контроля EeveeSpotify, поэтому будет вести себя как бесплатная подписка)

## [Частые проблемы](https://github.com/jaydenjcpy/EeveeSpotifyReincarnated/blob/Master/common_issues.md)
Пожалуйста, загляни по ссылке выше, прежде чем открывать issue

## Поддержка текстов песен

EeveeSpotify заменяет ограниченные по месяцу тексты песен Spotify одним из четырёх провайдеров:

- Genius: лучшее качество, больше всего песен, быстрее всего обновляется. Никогда не будет тайм-синхронизированным.

- LRCLIB: самый открытый сервис, с тайм-синхронизацией. Но не хватает текстов для многих песен.

- Musixmatch: сервис, который использует сам Spotify. Тайм-синхронизированные тексты для многих песен, но нужен пользовательский токен. Чтобы получить токен: скачай Musixmatch из App Store, зарегистрируйся, зайди в Settings → Get help → Copy debug info и вставь в алерт EeveeSpotify. Токен также можно извлечь через MITM.

- PetitLyrics: много тайм-синхронизированных японских и части международных текстов.

Если твик не может найти песню или обработать текст, появится сообщение "Couldn't load the lyrics for this song". Для некоторых песен тексты через Genius могут быть неверными из-за особенностей поиска — это по большей части исправлено, но, пожалуйста, не открывай issue по этому поводу.

## Как это работает

EeveeSpotify перехватывает запросы Spotify на загрузку пользовательских данных, десериализует их и на лету модифицирует параметры. Метод стабильно работает на всех поддерживаемых версиях Spotify.

Твик также включает `trackRowsEnabled`, показывая треки и лайкнутые песни на страницах артистов, как с Premium.

## Установка

Для сайдлоаднутых IPA рекомендуем **SideStore** или инструменты подписи сертификатами вроде **Ksign** — лучшая совместимость.

Чтобы открывать ссылки Spotify в сайдлоаднутом приложении, используй [OpenSpotifySafariExtension](https://github.com/BillyCurtis/OpenSpotifySafariExtension). Не забудь включить его и разрешить доступ в Settings → Safari → Extensions.

## Благодарности
Спасибо всему сообществу за поддержку, и спасибо разработчикам, которые работали над возрождением проекта:

[Ryuk](https://github.com/faroukbmiled)

[Mod4](https://github.com/M0d-4)

[estrogencat](https://github.com/estrogencat)

[Skye](https://github.com/Meeep1)

[whoeevee](https://github.com/whoeevee)

## Дисклеймер

Этот проект — **независимая модификация (твик)** приложения Spotify. Мы **никак не связаны, не аффилированы, не авторизованы и не одобрены Spotify** или любыми её дочерними компаниями.

Твик создан исключительно в **личных и образовательных целях**. Используешь на свой страх и риск.

**Мы не несём ответственности** за любые проблемы, повреждения или последствия использования или неправильного использования этого твика. Если что-то сломалось — это не наша проблема.

## История звёзд

<a href="https://www.star-history.com/?repos=SideloadLabs%2FEeveeSpotifyReincarnated&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=SideloadLabs/EeveeSpotifyReincarnated&type=date&theme=dark&legend=top-left&sealed_token=C1hKWTv3UNdLAgsZjjCL7Rthp6YSGB4Mm9kIalnH1lgZXZnYVL09WbBt57E-FFzQXg8gZyFOW356S5XMTWmvQdIuEihF66WxqGuJTejmAdJx5XJHxC2l3A" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=SideloadLabs/EeveeSpotifyReincarnated&type=date&legend=top-left&sealed_token=C1hKWTv3UNdLAgsZjjCL7Rthp6YSGB4Mm9kIalnH1lgZXZnYVL09WbBt57E-FFzQXg8gZyFOW356S5XMTWmvQdIuEihF66WxqGuJTejmAdJx5XJHxC2l3A" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=SideloadLabs/EeveeSpotifyReincarnated&type=date&legend=top-left&sealed_token=C1hKWTv3UNdLAgsZjjCL7Rthp6YSGB4Mm9kIalnH1lgZXZnYVL09WbBt57E-FFzQXg8gZyFOW356S5XMTWmvQdIuEihF66WxqGuJTejmAdJx5XJHxC2l3A" />
 </picture>
</a>
