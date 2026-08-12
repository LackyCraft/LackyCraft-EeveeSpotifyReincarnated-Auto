
## Автоматическое обновление и CI/CD

В этом форке можно настроить автоматическое обновление и сборку без ручного запуска каждого шага.

1. Добавьте в ваш форк два workflow файла:
   - `.github/workflows/auto-sync-and-build.yml` — синхронизирует `Master` с upstream, собирает `.deb` и создает GitHub Release на последнем теге; если задан секрет `VANILLA_IPA_URL` или input `ipa_url`, то этот workflow также соберет IPA и прикрепит его к релизу.
   - `.github/workflows/auto-build-ipa.yml` — ручный fallback для пересборки IPA из существующего Release тега, если вам нужно перезапустить только IPA-часть.
2. В настройках репозитория GitHub перейдите в `Settings` → `Secrets and variables` → `Actions` и добавьте секрет `VANILLA_IPA_URL` с прямой ссылкой на ваш собственный исходный Spotify IPA.
3. Убедитесь, что в `Actions` включены разрешения `Read and Write` для токена действий.
4. При каждом новом теге у upstream репозитория workflow будет обновлять ваш форк, собирать пакет и публиковать его в Release.
5. IPA-файл может собираться автоматически сразу после создания релиза, если `VANILLA_IPA_URL` задан.

> Важно: исходный Spotify IPA нельзя хранить в репозитории. GitHub workflow должен загружать его по прямой ссылке из вашего собственного хранилища.

## The History

In January 2024, Spotilife, the only tweak to get Spotify Premium, stopped working on new Spotify versions. [whoeevee](https://github.com/whoeevee) decompiled Spotilife, reverse-engineered Spotify, intercepted requests, etc., and created this tweak.

In December 2025, whoeevee, the maintainer of the EeveeSpotify tweak at the time, announced he'll be discontinuing the tweak because of the burden of keeping up with Spotify's constantly changing architectures. Soon after, [Meep1](https://github.com/Meeep1), forks the original Eevee repo and continues to develop the tweak to support newer Spotify versions, under the project name EeveeSpotiyRevivedPublic.

In  March 2026, the latest EeveeSpotifyRevivedPublic release, v9.1.28, users experienced constant logging out issues and reported to Skye, however, at the time of this README.md written, EeveeSpotifyRevivedPublic hasn't released any newer updates. During March, I've been constantly annoyed by the logout issue and decided to take matters into my own hands and forked EeveeSpotifyRevivedPublic and fixed the logout issue, which will eventually lead to the creation of this repository, which will be continuing the legacy of EeveeSpotify for newer versions of Spotify.
