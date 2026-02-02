FROM grafana/grafana:10.4.3

ENV GF_INSTALL_PLUGINS alexanderzobnin-zabbix-app alexanderzobnin-zabbix-datasource novalabs-ora-datasource marcusolsson-json-datasource grafana-piechart-panel
ENV GF_PLUGIN_ALLOW_LOADING_UNSIGNED_PLUGINS alexanderzobnin-zabbix-app,novalabs-ora-datasource
ENV GF_SERVER_ROOT_URL http://localhost:3000

COPY grafana/provisioning /etc/grafana/provisioning

RUN grafana-cli plugins install alexanderzobnin-zabbix-app \
    && grafana-cli plugins install alexanderzobnin-zabbix-datasource \
    && grafana-cli plugins install novalabs-ora-datasource \
    && grafana-cli plugins install marcusolsson-json-datasource \
    && grafana-cli plugins install grafana-piechart-panel
