# gitlab-formula

## Gitlab Server

Установка сервера GitLab пока что не реализована.

## Gitlab Runner

Установка и настройка Gitlab Runner

### Доступные стейты

* [gitlab.runner](gitlab.runner)
* [gitlab.runner.repo](gitlab.runner.install)
* [gitlab.runner.install](gitlab.runner.install)
* [gitlab.runner.prepare](gitlab.runner.prepare)
* [gitlab.runner.config](gitlab.runner.config)
* [gitlab.runner.register](gitlab.runner.register)
* [gitlab.runner.service](gitlab.runner.service)

#### gitlab.runner

Мета стейт выполнит установку и настройку раннера

#### gitlab.runner.repo

Стейт для подключения официально репозитория Girlab Runner - <https://packages.gitlab.com/runner/gitlab-runner/install>

#### gitlab.runner.install

Стейт для установки пакета `gitlab-runner`. Так же здесь выполняется настройка от имени какого пользователя будет выполняться запуск сервиса `gitlab-runner`. Возможен запуск от имени суперпользователя:

```yaml
gitlab:
  runner:
    root_user: root
    root_group: root
    run_as_root: true
```

или от имени обычного пользователя:

```yaml
gitlab:
  runner:
    user: gitlab-runner
    group: gitlab-runner
    run_as_root: false
```

Для работы с Docker, в случае если сервис работает от имени обычного пользователя, можно добавить пользователя `gitlab-runner` в группу `docker`:

```yaml
gitlab:
  runner:
    run_as_root: false
    docker:
      add_to_group: true
      group: docker
```

__ВНИМАНИЕ!__ По умолчанию сервис запускаеться от имени суперпользователя.

#### gitlab.runner.prepare

Вспомогательный стейт для установки Python библиотеки TOML. Поддержка TOML необходима для сериализации конфигурационного файла.

#### gitlab.runner.config

Стейт для управления конфигурационным файлом, отвечает за всю конфигурацию кроме секции `[[runners]]`.

#### gitlab.runner.register

Стейт для регистрации раннера. Регистрация выполняется с помощью команды `gitlab-runner register`.

__ВНИМАНИЕ!__ т.к. `gitlab-runner register` записывает конфигурацю в файл в момент регистрации, данный стейт не является идемпотентным, для изменения параметров нужно удалить раннер с Gitlab сервера и выполнить регистрацию повторно.

#### gitlab.runner.service

Стейт для настройки сервиса `gitlab-runner`.
