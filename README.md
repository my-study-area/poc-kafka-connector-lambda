# poc-kafka-connector-lambda
![GitHub top language](https://img.shields.io/github/languages/top/my-study-area/poc-kafka-connector-lambda)
![Terraform Version](https://img.shields.io/badge/Terraform-v1.6.4-blue.svg)
[![Repository size](https://img.shields.io/github/repo-size/my-study-area/poc-kafka-connector-lambda)](https://img.shields.io/github/repo-size/my-study-area/poc-kafka-connector-lambda)
[![Last commit](https://img.shields.io/github/last-commit/my-study-area/poc-kafka-connector-lambda)](https://github.com/my-study-area/poc-kafka-connector-lambda/commits/master)


POC de conector lambda sink

## Pré-requisitos
- docker / docker-compose
- python
- aws cli 2.0
- terraform com [tfenv](https://github.com/tfutils/tfenv) (opcional)
- terraform-local / [tflocal](https://docs.localstack.cloud/user-guide/integrations/terraform/#install-the-tflocal-wrapper-script) (opcional)
- [curls](https://curl.se/docs/manpage.html) (debug) (opcional)

## Executar localmente com a automação

```bash
# entra no diretório
cd automation

# inicia os containers
docker-compose up -d

# cria eventos no tópico Kafka para os schemas user e hello
python run_local/multi-schema-same-topic-avro-producer.py 
```

Para visualizar os logs execute num novo terminal:
```bash
aws logs tail /aws/lambda/consumer-events --follow --endpoint-url http://localhost:4566
```

## Identificando problemas na automação
Verifique se todos os containers estão executando:
```bash
docker-compose ps
```

Configure o profile localstack:
```bash
aws configure --profile localstack
# AWS Access Key ID [local]: 
# AWS Secret Access Key [local]: 
# Default region name [us-east-1]: 
# Default output format [json]:
```

Verifica se a lambda foi criada:
```bash
aws lambda list-functions \
--query "Functions[].FunctionName" \
--output text \
--endpoint-url http://localhost:4566
```

Em caso de problemas na criação da lambda execute:
```bash
# inicializa as configurações do terraform
tflocal init

# cria a lambda e a role
tflocal apply -auto-approve
```

Verifica se o plugin foi adicionado no Kafka connector:
```bash
curl http://localhost:8083/connector-plugins | grep LambdaSinkConnector
```

Verifica se foi criado o conector **connector-consumer-events**:
```bash
curl http://localhost:8083/connectors
```

Verifica o status do conector:
```bash
curl http://localhost:8083/connectors/connector-consumer-events/status
```

Remove o conector:
```bash
curl -XDELETE http://localhost:8083/connectors/connector-consumer-events

```
Cria o conector:
```bash
curl -XPOST -H 'Content-Type: application/json' http://localhost:8083/connectors -d @config/connector-localstack-avro.json
```

Cria eventos para o Kafka via console Kafka:
```bash
# inicia o bash do container schema-registry
docker-compose exec schema-registry bash

# conecta no kafka console producer
kafka-avro-console-producer \
--broker-list localhost:9092 \
--topic example-stream-avro \
--property value.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter.schema.registry.url=http://your_schema_registry:8081 \
--property value.subject.name.strategy=io.confluent.kafka.serializers.subject.TopicRecordNameStrategy \
--property value.schema="$(< hello.avsc)" \
--property key.converter=io.confluent.connect.avro.AvroConverter \
--property key.converter.schema.registry.url=http://localhost:8081 \
--property key.schema="$(< key.avsc)" \
--property key.separator=, \
--property parse.key=true \
--property key.separator=, \
--property parse.key=true


# exemplo de mensagem avro hello
{"timestamp":1637000000000},{"language": "ENGLISH", "greeting": "Hello, World!"}

# abra uma nova janela para iniciar o bash e gerar um evento avro para user
docker-compose exec schema-registry bash

# conecta no kafka console producer
kafka-avro-console-producer \
--broker-list localhost:9092 \
--topic example-stream-avro \
--property value.converter=io.confluent.connect.avro.AvroConverter \
--property value.converter.schema.registry.url=http://your_schema_registry:8081 \
--property value.subject.name.strategy=io.confluent.kafka.serializers.subject.TopicRecordNameStrategy \
--property value.schema="$(< user.avsc)" \
--property key.converter=io.confluent.connect.avro.AvroConverter \
--property key.converter.schema.registry.url=http://localhost:8081 \
--property key.schema="$(< key.avsc)" \
--property key.separator=, \
--property parse.key=true \
--property key.separator=, \
--property parse.key=true

# exemplo de mensagem avro user
{"timestamp":1637000000000},{"name": "John Doe", "age": 30}
```

## Anotações
```bash
# lista as lambdas
aws lambda list-functions --endpoint-url http://localhost:4566 --query "Functions[].[FunctionName]"

# testa comunicação com kafka
nc -vz localhost 9092

# invoca a lambda criada na automação, dentro do localstack
curl -XPOST "http://localhost:4566/2015-03-31/functions/consumer-events/invocations" -d '{"nome": "Joao"}'

# mostra o stream dos logs da lambda
aws logs tail --follow /aws/lambda/consumer-events

# executa os teste unitários com cobertura
pytest -s . -v --cov

# executa os teste unitários com cobertura na pasta htmlcov
pytest -s . -v --cov --cov-report=html

# executa os teste unitários com cobertura e mostra as linhas não cobertas
pytest --cov app --cov-branch --cov-report term-missing
```

## Links
- [How to hot reload your Lambda functions locally with LocalStack](https://www.youtube.com/watch?v=DFS3CnB-Z0k&ab_channel=LocalStack)
