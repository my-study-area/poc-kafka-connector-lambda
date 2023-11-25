
from datetime import datetime
import os


def handler(event, context):
  print(f'Evento recebido: {event}')
  print(f'Variaveis de ambiente: {os.getenv("ENVIRONMENT")}')
  return {
    "statusCode": 200,
    "body": "Hello World!"
  }

if __name__ == "__main__":
  handler({"value": "my example"}, None)
