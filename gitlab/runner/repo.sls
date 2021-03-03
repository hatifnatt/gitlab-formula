# Repo for Debian or Ubuntu systems
{%- if grains['os'] == 'Debian' or grains['os'] == 'Ubuntu' -%}
# As recommended in official manual
# https://packages.gitlab.com/runner/gitlab-runner/install#manual-deb install prerequisites
install_prerequisites_{{ sls }}:
  pkg.installed:
    - pkgs:
      - debian-archive-keyring
      - ca-certificates
      - apt-transport-https

gitlab_runner_repo:
  pkgrepo.managed:
    - humanname: GitLab Runner
    - names:
      - deb https://packages.gitlab.com/runner/gitlab-runner/{{ grains['os']|lower }}/ {{ grains['oscodename'] }} main
      - deb-src https://packages.gitlab.com/runner/gitlab-runner/{{ grains['os']|lower }}/ {{ grains['oscodename'] }} main
    - key_url: https://packages.gitlab.com/runner/gitlab-runner/gpgkey
    - file: /etc/apt/sources.list.d/runner_gitlab-runner.list
    - refresh: true
    - require:
      - pkg: install_prerequisites_{{ sls }}

# Repo for RedHat family systems
{%- elif grains['os_family'] == 'RedHat' %}
install_prerequisites_{{ sls }}:
  pkg.installed:
    - pkgs:
      - yum-utils

gitlab_runner_repo:
  pkgrepo.managed:
    - humanname: GitLab Runner
    - baseurl: https://packages.gitlab.com/runner/gitlab-runner/el/{{ grains['osmajorrelease'] }}/$basearch
    - gpgcheck: 1
    - gpgkey: |-
        https://packages.gitlab.com/runner/gitlab-runner/gpgkey
        https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-366915F31B487241.pub.gpg
    - enabled: true
    - repo_gpgcheck: 1
    - sslverify: 1
    - sslcacert: /etc/pki/tls/certs/ca-bundle.crt
    - metadata_expire: 300
    - refresh: true
    - require:
      - pkg: install_prerequisites_{{ sls }}

{%- else %}

unsupported_os_{{ sls }}:
  test.fail_without_changes:
    - name: "Unsupported OS!"

{%- endif %}
