{% set tplroot = tpldir.split('/')[0] -%}
{% from tplroot ~ '/map.jinja' import gitlab -%}

{# Reload systemd (like `systemctl daemon-reload`) after new package installed,
   this will prevent issue when systemd can't enable service due fact it can't
   find service unit file. Usually this happens only on RedHat derivatives #}
gitlab_runner_reload_systemd:
  module.wait:
  {#- Workaround for deprecated `module.run` syntax, subject to change in Salt 3005 #}
  {%- if 'module.run' in salt['config.get']('use_superseded', [])
      or grains['saltversioninfo'] >= [3005] %}
    - service.systemctl_reload: {}
  {%- else %}
    - name: service.systemctl_reload
  {%- endif %}

# Enable and start service
gitlab_runner_service:
  service.{{ gitlab.runner.service.status }}:
    - name: {{ gitlab.runner.service.name }}
    - enable: {{ gitlab.runner.service.enable }}
    - require:
      - module: gitlab_runner_reload_systemd
