FROM grafana/grafana:10.4.3

ENV GF_INSTALL_PLUGINS="alexanderzobnin-zabbix-app alexanderzobnin-zabbix-datasource novalabs-ora-datasource marcusolsson-json-datasource"

COPY grafana/provisioning /etc/grafana/provisioning
