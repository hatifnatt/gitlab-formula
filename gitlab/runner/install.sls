{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import gitlab -%}

include:
  - .repo
  - .service
  {# {%- if gitlab.runner.docker.install %}
  # can't simply use 'service.docker' for include and require below because it will throw error like
  # "The following requisites were not found: require: sls: service.docker"
  # see https://github.com/saltstack/salt/issues/10852
  - {{ gitlab.runner.docker.install_sls }}
  {%- endif %} #}

# pin version
{%- if grains.os_family == 'Debian' %}
gitlab_runner_pin_version:
  file.managed:
    - name: /etc/apt/preferences.d/gitlab_runner
    - contents: |
        # This file managed by Salt, do not edit by hand!
        Explanation: Prefer GitLab provided packages over the Debian native ones
        Package: gitlab-runner
        {%- if gitlab.runner.version %}
        Pin: version {{ gitlab.runner.version }}
        {%- endif %}
        Pin: origin packages.gitlab.com
        Pin-Priority: 1000
    - require_in:
      - pkg: gitlab_runner_pkg
{%- endif %}

# set environment prior package installing
# see https://docs.gitlab.com/runner/install/linux-repository.html#disable-skel
# will be available from version 12.10
gitlab_runner_environ:
  environ.setenv:
    - name: GITLAB_RUNNER_DISABLE_SKEL
    - value: 'true'
    - prereq:
      - pkg: gitlab_runner_pkg

# install package
gitlab_runner_pkg:
  pkg.installed:
    - name: gitlab-runner
{%- if gitlab.runner.version %}
    - version: {{ gitlab.runner.version }}
{%- endif %}
    - reqire:
      - sls: repo
      - environ: gitlab_runner_environ
    - watch_in:
      - service: gitlab_runner_service
      - module: gitlab_runner_reload_systemd

# clean files copied from skel
# required for runner version 12.9 and below
gitlab_runner_clean_home:
  file.absent:
    - names:
      - '{{ gitlab.runner.home }}/.bash_logout'
      - '{{ gitlab.runner.home }}/.bashrc'
      - '{{ gitlab.runner.home }}/.profile'
    - require:
      - pkg: gitlab_runner_pkg

{%- if not gitlab.runner.run_as_root %}
gitlab_runner_configs_owner:
  file.directory:
    - name: /etc/gitlab-runner
    - user: {{ gitlab.runner.user }}
    - group: {{ gitlab.runner.group }}
    - recurse:
      - user
      - group
    - require:
      - pkg: gitlab_runner_pkg
    - require_in:
      - service: gitlab_runner_service

gitlab_runner_service_run_as_regular_user:
  file.managed:
    - name: "/etc/systemd/system/{{ gitlab.runner.service.name }}.service.d/user.conf"
    - makedirs: true
    - template: jinja
    - contents: |
        [Service]
        User={{ gitlab.runner.user }}
        Group={{ gitlab.runner.group }}
    - watch_in:
      - module: gitlab_runner_reload_systemd
      - service: gitlab_runner_service

{%- elif gitlab.runner.run_as_root %}
gitlab_runner_configs_owner:
  file.directory:
    - name: /etc/gitlab-runner
    - user: {{ gitlab.runner.root_user }}
    - group: {{ gitlab.runner.root_group }}
    - recurse:
      - user
      - group
    - require:
      - pkg: gitlab_runner_pkg
    - require_in:
      - service: gitlab_runner_service

gitlab_runner_service_run_as_root:
  file.absent:
    - name: "/etc/systemd/system/{{ gitlab.runner.service.name }}.service.d/user.conf"
    - watch_in:
      - service: gitlab_runner_service

{%- endif %}

# Gitlab Runner user will be added to docker group, to be able to control Docker via unix socket
# NOTE: If runner is running as root it's still necessary to add gitlab-runner user to docker group
# because shell executor run scrips on behalf of the gitlab-runner user
{% if gitlab.runner.docker.add_to_group -%}
gitlab_runner_allow_docker:
  group.present:
    - name: {{ gitlab.runner.docker.group }}
    - addusers:
      - {{ gitlab.runner.user }}
    - onlyif: getent group {{ gitlab.runner.docker.group }}
    - require:
      - pkg: gitlab_runner_pkg
    - watch_in:
      - service: gitlab_runner_service

gitlab_runner_{{ gitlab.runner.docker.group }}_not_found:
  test.fail_without_changes:
    - name: Group '{{ gitlab.runner.docker.group }}' is not found
    - comment: |
        '{{ gitlab.runner.user }}' is not added to '{{ gitlab.runner.docker.group }}' group.
        Group '{{ gitlab.runner.docker.group }}' is not found, do you have Docker installed?
        Is '{{ gitlab.runner.docker.group }}' group a correct group of Docker in your OS?
    - unless: getent group {{ gitlab.runner.docker.group }}

# Remove gitlab-runner user from docker group
{% else -%}
gitlab_runner_deny_docker:
  group.present:
    - name: {{ gitlab.runner.docker.group }}
    - delusers:
      - {{ gitlab.runner.user }}
    - onlyif: getent group {{ gitlab.runner.docker.group }}
    - require:
      - pkg: gitlab_runner_pkg
    - watch_in:
      - service: gitlab_runner_service

{% endif -%}
