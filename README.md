# Grafana Observability Stack

Este projeto entrega um stack completo com Grafana, PostgreSQL 14 (partitioned por ano), Redis, Prometheus e integração pronta para Zabbix e APIs JSON. A ideia é usar o Grafana como camada unificadora de métricas corporativas (tempo real e históricas), com:

1. Banco PostgreSQL preparado para armazenar séries temporais ou logs no esquema `metric_samples`, garantindo que os dados sejam particionados por ano automaticamente e armazenados no volume do SO montado em `/mnt/postgresql/data`.
2. Grafana com todos os plugins solicitados (app Zabbix, datasource Zabbix, datasource Oracle 12c, JSON API, painel de pizza) para acessar dados de Zabbix, ler APIs JSON e também suportar conexões a bases Oracle.
3. Redis para cache/alertas (depois configurado pelo usuário) e Prometheus para scraping local (Grafana e Prometheus se enxergam) e visualização de métricas do próprio cluster.
4. Loki para centralizar logs de aplicações e do próprio Grafana em `http://localhost:3100`, permitindo que dashboards incluam painéis de logs lado a lado com métricas.

## Build e execução

1. **Garanta que o diretório de dados existe:**
   ```powershell
   mkdir -Force C:/mnt/postgresql/data
   ```
   Essa pasta é exposta ao contêiner PostgreSQL automaticamente via `docker-compose.yml`.

2. **Construir a imagem do Grafana:**
   ```powershell
   docker compose build grafana
   ```
   O `Dockerfile` copia a provisão do Grafana e instala em tempo de build os plugins requisitados.

3. **Subir todo o stack:**
   ```powershell
   docker compose up -d
   ```
   O PostgreSQL aplica o script `postgres/init/partitioning.sql` no bootstrap, criando a tabela particionada `metric_samples` e o gatilho que gera partições anuais automaticamente.

4. **Verificar logs/estado:**
   ```powershell
   docker compose ps
   docker compose logs grafana
   docker compose logs loki
   ```

## Como o projeto funciona

- **Grafana:** usa o `Dockerfile` customizado com `GF_INSTALL_PLUGINS` para garantir que os apps/datasources Zabbix, Oracle 12c, JSON API e o painel de pizza já estejam disponíveis. A pasta `grafana/provisioning/datasources/datasource.yaml` injeta dois data sources na inicialização (Zabbix e JSON API) usando variáveis de ambiente (`ZABBIX_API_URL`, `JSON_API_URL`, etc.). Ajuste esses valores em um `.env.local` ou no entorno do contêiner antes de subir o stack.

- **PostgreSQL:** o volume `pgdata` está mapeado para `/mnt/postgresql/data` no host, garantindo persistência fora do contêiner. O script de inicialização cria a tabela `metric_samples` com triggers que chamam `create_metric_partition` para garantir partições anuais (2024 em diante) antes de qualquer inserção. Para adicionar um ano futuro manualmente, rode:
  ```sql
  SELECT create_metric_partition(2028);
  ```

- **Prometheus:** lê métricas locais (incluindo o próprio Grafana) a partir do arquivo `prometheus/prometheus.yml`. Você pode apontar o Grafana para esse Prometheus como uma fonte adicional, usando o endereço `http://prometheus:9090`.

- **Redis:** fica disponível em `grafana-redis:6379` para suportar caching e outras funcionalidades (ex.: alertas do Grafana ou reservas de sessões). Ele também é exposto para testes (`localhost:6379`).

- **Loki:** o contêiner `grafana-loki` expõe `http://localhost:3100` e armazena chunks/index em `loki/`. Basta adicionar mais um data source do tipo Loki no Grafana apontando para `http://loki:3100` para correlacionar logs de aplicativos, redes ou da própria plataforma dentro dos dashboards existentes.

## Papéis do Grafana e funções extra

1. **Integração com Zabbix:** o app/data source do Zabbix permite puxar métricas diretamente da API (`ZABBIX_API_URL`). Configure o token em `ZABBIX_API_TOKEN` para autenticação segura.
2. **Leitura de APIs JSON:** o plugin JSON API ajuda o Grafana a consumir endpoints REST/JSON (via `JSON_API_URL`) e transformar respostas em métricas e painéis.
3. **Suporte Oracle 12c:** o plugin `novalabs-ora-datasource` já está instalado para conectar o Grafana a instâncias Oracle 12c autenticadas via credentials definidas no próprio Grafana.
4. **Zabbix App:** oferece painéis prontos e descoberta de hosts, facilitando a visualização de ativos monitorados e alertas.

## Próximos passos sugeridos

1. Configure os valores ausentes (`ZABBIX_API_URL`, `ZABBIX_API_TOKEN`, `JSON_API_URL`, `JSON_API_BEARER_TOKEN`) em um `.env.local` ou diretamente no ambiente dos contêineres.
2. Crie dashboards no Grafana e aponte o Prometheus como uma fonte para agregar métricas internas e externas.
3. Certifique-se de ajustar regras de firewall/Proxy para que o Grafana alcance o Zabbix e a API JSON reais usadas na sua organização.
4. Adicione um data source do tipo Loki (`http://loki:3100`) para que os painéis possam correlacionar logs e métricas e explore os dashboards com os logs agregados pela nova fonte.
# grafana
