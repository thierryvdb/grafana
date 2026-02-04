# Grafana Observability Stack

Este projeto fornece uma stack de observabilidade completa e conteinerizada, ideal para centralizar e visualizar métricas de diversas fontes. A stack inclui Grafana, Prometheus, PostgreSQL e Redis, todos orquestrados com Docker Compose.

## Arquitetura

O diagrama abaixo ilustra a arquitetura da stack de observabilidade:

```
+-----------------+      +-----------------+      +-----------------+
|   Zabbix        |------>|   Grafana       |<------|   Prometheus    |
| (Fonte Externa) |      | (Porta: 13000)  |      | (Coleta Métricas) |
+-----------------+      +-----------------+      +-----------------+
                         |      ^      ^      |
                         |      |      |      |
                         v      v      v      v
+-----------------+      +-----------------+
|   JSON API      |------>|   PostgreSQL    |
| (Fonte Externa) |      |  (Banco de Dados) |
+-----------------+      +-----------------+
                         |      ^
                         |      |
                         v      v
                         +-----------------+
                         |      Redis      |
                         |     (Cache)     |
                         +-----------------+
```

### Componentes

*   **Grafana**: Serviço principal de visualização. Pré-configurado com os seguintes data sources:
    *   **Zabbix**: Para visualização de métricas do Zabbix.
    *   **JSON API**: Para consumir dados de qualquer API JSON.
    *   **Prometheus**: Para visualizar métricas coletadas pelo Prometheus.

*   **Prometheus**: Sistema de monitoramento e alerta. Coleta métricas dos serviços da stack.

*   **PostgreSQL**: Banco de dados para o Grafana. A tabela `metric_samples` é particionada por ano para otimizar o armazenamento e a consulta de dados de séries temporais.

*   **Redis**: Cache para o Grafana, melhorando a performance de dashboards e consultas.

## Estrutura do Projeto

```
.
├── .env                    # Variáveis de ambiente para a stack
├── .env.example            # Exemplo de arquivo de variáveis de ambiente
├── docker-compose.yml      # Orquestração dos contêineres
├── Dockerfile              # Dockerfile para a imagem customizada do Grafana
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasource.yaml # Provisionamento dos data sources do Grafana
├── postgres/
│   └── init/
│       └── partitioning.sql # Script de inicialização do PostgreSQL
└── prometheus/
    └── prometheus.yml      # Configuração do Prometheus
```

## Como Começar

### Pré-requisitos

*   Docker e Docker Compose instalados.

### Configuração

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/seu-usuario/seu-repositorio.git
    cd seu-repositorio
    ```

2.  **Configure as variáveis de ambiente:**
    *   Crie uma cópia do arquivo `.env.example` com o nome `.env`.
    *   Preencha as variáveis de ambiente no arquivo `.env` com os valores corretos para a sua configuração. **É crucial alterar as senhas padrão!**

### Execução

1.  **Suba a stack:**
    ```bash
    docker-compose up -d
    ```

2.  **Acesse o Grafana:**
    *   Abra o seu navegador e acesse `http://localhost:13000`.
    *   O usuário e senha padrão do Grafana são `admin`/`admin`.


## Atualizando a stack

1.  **Atualize variáveis e código:** revise e ajuste `.env`, `Dockerfile`, `grafana/provisioning` ou `prometheus/prometheus.yml` conforme o novo requisito.
2.  **Puxe e compile imagens:** execute `docker-compose pull` para baixar novas versões base e `docker-compose build grafana` se o Dockerfile mudou.
3.  **Reimplante sem perda dos dados:** rode `docker-compose up -d --remove-orphans` para subir as imagens atualizadas. Para reimplantação pontual, use `docker-compose up -d --no-deps --build <serviço>` (por exemplo `grafana`).
4.  **Valide o rollout:** confira `docker-compose ps` e `docker-compose logs <serviço>` e verifique que os containers apresentam a nova versão.

## Preservando o banco de dados PostgreSQL

1.  **Volume persistente:** o volume `pgdata` mantém os dados fora do container. Não execute `docker-compose down -v` nem `docker volume rm pgdata`, pois isso destrói o banco.
2.  **Atualizações focadas no resto da stack:** quando precisar ajustar Grafana, Prometheus ou Redis, reimplante apenas os serviços necessários (`docker-compose up -d --no-deps --build grafana prometheus redis` ou `docker-compose restart grafana`). O PostgreSQL permanece rodando e reaproveita seu volume.
3.  **Mudança de esquema ou dados:** conecte-se ao PostgreSQL (`docker-compose exec postgres psql ...`) para aplicar migrações e backups antes de reiniciar outros serviços. Dessa forma, apenas o que mudou é recarregado.

## Detalhes da Implementação

### Particionamento do PostgreSQL

O script `postgres/init/partitioning.sql` cria a tabela `metric_samples` particionada por ano. Isso é feito para otimizar o armazenamento e a consulta de grandes volumes de dados de séries temporais. Uma função e um gatilho garantem que novas partições sejam criadas automaticamente quando novos dados são inseridos.

### Provisionamento do Grafana

O `datasource.yaml` em `grafana/provisioning/datasources` provisiona automaticamente os data sources Zabbix, JSON API e Prometheus no Grafana. As configurações para esses data sources, como URLs e tokens de autenticação, são lidas a partir das variáveis de ambiente.

## Contribuindo

Contribuições são bem-vindas! Se você encontrar algum problema ou tiver alguma sugestão, por favor, abra uma issue ou envie um pull request.
