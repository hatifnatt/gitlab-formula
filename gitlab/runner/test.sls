{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import gitlab -%}
{% from tplroot ~ '/macro.jinja' import register_command -%}

{% if salt['pkg.version'](gitlab.runner.pytoml_pkg)
      and salt['file.file_exists'](gitlab.runner.config_file) -%}
  {%- set loaded_config_file = salt['file.read'](gitlab.runner.config_file) %}
  {%- set current_config = salt['slsutil.deserialize']('toml', loaded_config_file) %}
{% else %}
  {%- set current_config = {} %}
{% endif -%}

{% set new_config = salt['slsutil.merge'](current_config, gitlab.runner.config) -%}

gitlab_test_print_data:
  test.configurable_test_state:
    - name: Print some dict
    - result: True
    - changes: False
    - comment: |
        --- curent ---
        {{ current_config|yaml(False)|indent(width=8) }}

        --- pillar ---
        {{ gitlab.runner.config|yaml(False)|indent(width=8) }}

        --- new    ---
        {{ new_config|yaml(False)|indent(width=8) }}


{% for runner in gitlab.runner.runners -%}
gitlab_runner_register_{{ runner.name }}:
  test.configurable_test_state:
    - name: Print some dict
    - result: True
    - changes: False
    - comment: |
        {{ register_command(runner) }}
{% endfor %}
