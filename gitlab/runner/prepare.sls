{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import gitlab -%}

gitlab_runner_python_toml:
  pkg.installed:
    - name: {{ gitlab.runner.pytoml_pkg }}
