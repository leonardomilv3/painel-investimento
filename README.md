# Painel de Investimentos - Caixaverso

API REST para simulação e acompanhamento de investimentos, com autenticação JWT,
recomendação de produtos por perfil de risco e registro de telemetria.

**Stack:** Java 25, Quarkus 3.29, PostgreSQL 17, Flyway e Redis 7.4.

## Swagger

Com a aplicação em execução, acesse a [documentação interativa da API
(Swagger UI)](http://localhost:8080/swagger-ui). O documento OpenAPI está
disponível em <http://localhost:8080/openapi>.

## Requisitos

- JDK 25
- Docker e Docker Compose

## Executar localmente

Crie o arquivo `.env` com base no exemplo e substitua as senhas ilustrativas:

```powershell
Copy-Item .env.example .env
```

Inicie PostgreSQL e Redis:

```powershell
docker compose up -d postgres redis
```

Execute a aplicação em modo de desenvolvimento:

```powershell
.\mvnw.cmd quarkus:dev
```

A API fica disponível em <http://localhost:8080>. O Quarkus aplica as
migrações Flyway em `src/main/resources/db/migration`. Os dados de demonstração
em `src/main/resources/db/dev-data` são carregados apenas nos perfis `dev` e
`test`; os usuários `admin` e `user` com senhas iguais ao nome são exclusivos
do perfil de desenvolvimento e não devem ser usados em produção.

## Autenticação e endpoints

O login não exige token. Envie `usuario` e `senha` para `POST /auth/login`; a
resposta contém o JWT. Nas rotas protegidas, envie o token no cabeçalho
`Authorization: Bearer <token>`.

| Método | Endpoint | Acesso |
| --- | --- | --- |
| `POST` | `/auth/login` | Público |
| `POST` | `/simular-investimento` | Público |
| `GET` | `/investimentos/{clienteId}` | Admin |
| `GET` | `/perfil-risco/{clienteId}` | Admin |
| `GET` | `/produtos-recomendados/{perfil}` | Admin ou User |
| `GET` | `/simulacoes?page=0&size=20` | Admin |
| `GET` | `/simulacoes/por-produto-dia` | Admin |
| `GET` | `/telemetria?comeco=AAAA-MM-DD&fim=AAAA-MM-DD` | Admin |

O endpoint de simulação valida o valor investido (positivo, até duas casas
decimais), o prazo (de 1 a 600 meses) e o produto. A listagem de simulações
usa paginação iniciada em zero, com tamanho padrão de 20. A telemetria consulta
o mês atual quando as datas não são informadas.

## Banco de dados e cache

O PostgreSQL é configurado com Flyway e validação do esquema pelo Hibernate.
As migrações não apagam os dados existentes. O volume `postgres-data` mantém
os arquivos do banco após `docker compose down`; evite `docker compose down -v`
se quiser preservá-lo.

Os GETs usam cache Redis, com TTL padrão de 5 minutos (`CACHE_TTL`) e de
30 segundos para telemetria (`CACHE_TELEMETRIA_TTL`). Alterações confirmadas
invalidam os caches afetados; os dados de cache não são persistidos em disco.
O Redis é obrigatório para a aplicação.

## Testes

Execute a suíte completa:

```powershell
.\mvnw.cmd verify
```

Os testes de integração usam PostgreSQL e Redis isolados via Dev Services e
requerem Docker.
