# poc-kafka-connector-lambda
POC de conector lambda sink


## Anotações
```bash
# lista as lambdas
aws lambda list-functions --profile sandbox --query "Functions[].[FunctionName]"

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

## Anotações temporárias
Cluster MSK:
- unauthanticated access
- disable IAM role-based
- plaintext + TLS encryption
- security group:
  - inbound traffic
  - outbound traffic


EC2 para testes na VPC

- criar security group
  - inbound:
    - SSH / 22 / 0.0.0.0/0
  - outbound:
    - 0.0.0.0/0

- criar role:
  - trust:
  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "Service": "ec2.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
          }
      ]
  }
  ```
  - policy: AmazonMSKFullAccess
    - policy MSK:
      ```json
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": [
                      "kafka:*",
                      "ec2:DescribeSubnets",
                      "ec2:DescribeVpcs",
                      "ec2:DescribeSecurityGroups",
                      "ec2:DescribeRouteTables",
                      "ec2:DescribeVpcEndpoints",
                      "ec2:DescribeVpcAttribute",
                      "kms:DescribeKey",
                      "kms:CreateGrant",
                      "logs:CreateLogDelivery",
                      "logs:GetLogDelivery",
                      "logs:UpdateLogDelivery",
                      "logs:DeleteLogDelivery",
                      "logs:ListLogDeliveries",
                      "logs:PutResourcePolicy",
                      "logs:DescribeResourcePolicies",
                      "logs:DescribeLogGroups",
                      "S3:GetBucketPolicy",
                      "firehose:TagDeliveryStream"
                  ],
                  "Resource": "*"
              },
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:CreateVpcEndpoint"
                  ],
                  "Resource": [
                      "arn:*:ec2:*:*:vpc/*",
                      "arn:*:ec2:*:*:subnet/*",
                      "arn:*:ec2:*:*:security-group/*"
                  ]
              },
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:CreateVpcEndpoint"
                  ],
                  "Resource": [
                      "arn:*:ec2:*:*:vpc-endpoint/*"
                  ],
                  "Condition": {
                      "StringEquals": {
                          "aws:RequestTag/AWSMSKManaged": "true"
                      },
                      "StringLike": {
                          "aws:RequestTag/ClusterArn": "*"
                      }
                  }
              },
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:CreateTags"
                  ],
                  "Resource": "arn:*:ec2:*:*:vpc-endpoint/*",
                  "Condition": {
                      "StringEquals": {
                          "ec2:CreateAction": "CreateVpcEndpoint"
                      }
                  }
              },
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:DeleteVpcEndpoints"
                  ],
                  "Resource": "arn:*:ec2:*:*:vpc-endpoint/*",
                  "Condition": {
                      "StringEquals": {
                          "ec2:ResourceTag/AWSMSKManaged": "true"
                      },
                      "StringLike": {
                          "ec2:ResourceTag/ClusterArn": "*"
                      }
                  }
              },
              {
                  "Effect": "Allow",
                  "Action": "iam:PassRole",
                  "Resource": "*",
                  "Condition": {
                      "StringEquals": {
                          "iam:PassedToService": "kafka.amazonaws.com"
                      }
                  }
              },
              {
                  "Effect": "Allow",
                  "Action": "iam:CreateServiceLinkedRole",
                  "Resource": "arn:aws:iam::*:role/aws-service-role/kafka.amazonaws.com/AWSServiceRoleForKafka*",
                  "Condition": {
                      "StringEquals": {
                          "iam:AWSServiceName": "kafka.amazonaws.com"
                      }
                  }
              },
              {
                  "Effect": "Allow",
                  "Action": "iam:CreateServiceLinkedRole",
                  "Resource": "arn:aws:iam::*:role/aws-service-role/delivery.logs.amazonaws.com/AWSServiceRoleForLogDelivery*",
                  "Condition": {
                      "StringEquals": {
                          "iam:AWSServiceName": "delivery.logs.amazonaws.com"
                      }
                  }
              }
          ]
      }
      ```
- alterar sg do MSK
  - inbound:
    - all traffic / sg do EC2


Lambda
- timeout: 4 minutos
- adicionar polices:
  - AWSLambdaMSKExecutionRole
  - AmazonVPCFullAccess

### Comandos para instalação manual do kafka
```bash
sudo yum install java-1.8.0
wget https://archive.apache.org/dist/kafka/2.8.1/kafka_2.13-2.8.1.tgz
tar -xzf kafka_2.13-2.8.1.tgz 
aws configure
#us-east-1

# lista os clusters kafka na AWS
aws kafka list-clusters

# entra no diretório
cd kafka_2.13-2.8.1

#cria o topic
bin/kafka-topics.sh --create --topic teste1 --bootstrap-server localhost:9092 --partitions 3 --replication-factor 2

# lista os tópicos
bin/kafka-topics.sh --list --bootstrap-server localhost:9092

#producer do topic teste1
bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic teste1

#consumer
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic teste1 --from-beginning

# lista os consumers groups
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

## Links
- [How to hot reload your Lambda functions locally with LocalStack](https://www.youtube.com/watch?v=DFS3CnB-Z0k&ab_channel=LocalStack)
