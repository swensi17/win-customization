# Как внести вклад / Contributing

Спасибо, что хочешь помочь! Ниже короткие правила, чтобы репозиторий оставался аккуратным.
Thanks for helping! Below are the short rules that keep the repository tidy.

## Новый компонент / A new component

Каждая новая штука оформляется одинаково / Every new piece follows the same pattern:

1. скрипт установки `scripts/NN-имя.ps1` со следующим номером, подключённый в `Install-Auto.ps1` и откат `99-rollback.ps1`;
2. конфиги и исходники в `configs/`;
3. проверка в `scripts/Test-Setup.ps1`;
4. раскрывающийся блок в `README.md` и `README.en.md` и строка в таблице шагов;
5. шаг в `docs/AGENT_PLAYBOOK.md` с тегами `AUTO` / `MANUAL` / `VERIFY` / `ROLLBACK` / `WARN`;
6. чистый скриншот «до/после» в `screenshots/`.

## Правила / Rules

- **Без личных данных / No personal data:** никаких токенов, паролей, имени пользователя, IP, имени ПК и личных путей. Пути строить через `$env:...`. Для скриншотов терминала есть демо-режим (`splash-demo.json`).
- **Безопасность / Safety:** программы класть в `C:\...`, перед заменой настроек делать `.bak`, каждый шаг должен откатываться. Сторонние установщики проверять по цифровой подписи.
- **Проверка / Check:** перед PR запусти `scripts\Test-Setup.ps1`, в выводе не должно быть `FAIL`.
- **README:** таблицы на всю ширину (картинка-распорка `screenshots/spacer.png` в шапке), заголовки отделены пустой строкой.

## Сообщения коммитов / Commit messages

На русском, всё с маленькой буквы, в повелительном наклонении, коротко (до ~45 символов), без точки и эмодзи. Префикс типа по желанию.
Russian, all lowercase, imperative, short (up to ~45 characters), no trailing period or emoji. An optional type prefix.

```text
feat: индикатор нагрузки ram и cpu в трее
fix: короткий путь в приглашении
docs: английская версия readme
```

Одна законченная штука, один коммит. / One finished thing, one commit.