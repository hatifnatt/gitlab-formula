{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import gitlab -%}

include:
  - .prepare

# pretty hacky way to update global configuration parameters
# if python toml package is installed and config file is present we load configuration from it
# this conditions are usually met on subsequent state runs
{% if salt['pkg.version'](gitlab.runner.pytoml_pkg)
      and salt['file.file_exists'](gitlab.runner.config_file) -%}
  {%- set loaded_config_file = salt['file.read'](gitlab.runner.config_file) %}
  {%- set current_config = salt['slsutil.deserialize']('toml', loaded_config_file) %}
  # then we update configuration loded from config file with parameters from pillars
  {%- set new_config = salt['slsutil.merge'](current_config, gitlab.runner.config) %}

# this state ALWAYS generate changes if new runner is registered after this state applied
# that happens due `gitlab-runner register` comand does pretty formatting for a config file
# but file.serialize with write config file in simple sorted fashion without indents
gitlab_runner_config:
  file.serialize:
    - name: {{ gitlab.runner.config_file }}
    - dataset: {{ new_config|tojson }}
    - formatter: toml
  {%- if not gitlab.runner.run_as_root %}
    - user: {{ gitlab.runner.user }}
    - group: {{ gitlab.runner.group }}
  {%- elif gitlab.runner.run_as_root %}
    - user: {{ gitlab.runner.root_user }}
    - group: {{ gitlab.runner.root_group }}
  {%- endif %}
    - require:
      - sls: {{ tpldot }}.prepare

{% else %}
# at first run usually no runners are registered
# if no runners registerd we are free to write configuration
gitlab_runner_config:
  file.serialize:
    - name: {{ gitlab.runner.config_file }}
    - dataset: {{ gitlab.runner.config|tojson }}
    - formatter: toml
  {%- if not gitlab.runner.run_as_root %}
    - user: {{ gitlab.runner.user }}
    - group: {{ gitlab.runner.group }}
  {%- elif gitlab.runner.run_as_root %}
    - user: {{ gitlab.runner.root_user }}
    - group: {{ gitlab.runner.root_group }}
  {%- endif %}
    - require:
      - sls: {{ tpldot }}.prepare
    - onlyif: test $(gitlab-runner list 2>&1 | grep -v 'Runtime\|Listing' | wc -l) -eq 0
{% endif -%}
