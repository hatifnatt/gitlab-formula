{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import gitlab -%}
{% from tplroot ~ '/macro.jinja' import register_command -%}
# TODO Generate config by serializing data from pillar and register runner via GitLab API.
#      Problems with this approach: how to insert token into runner config, we need to get it from
#      GitLab server, then add it into runner config data and after all serialize all data in TOML fromat.
#      Probably the best ways is to write custom Python module for that.

include:
  - .config

# Delete removed
{% if gitlab.runner.delete_removed -%}
gitlab_runner_delete_removed:
  cmd.run:
    - name: gitlab-runner verify --delete
    - onlyif: "gitlab-runner verify 2>&1 | grep -qE 'ERROR: .* is removed'"
{% endif -%}

# Register runner
{% for runner in gitlab.runner.runners -%}
gitlab_runner_register_{{ runner.name }}:
  cmd.run:
    - name: |-
        {{ register_command(runner) }}
    - env:
      # pass registration token via env, to make it little bit harder to see during state run
      - REGISTRATION_TOKEN: {{ gitlab.runner.registration_token }}
    - unless: gitlab-runner verify -n {{ runner.name }}
    - require:
      - sls: {{ tpldot }}.config
{% endfor %}
