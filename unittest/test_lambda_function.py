import os
import sys
 
current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

from app.lambda_function import handler

def test_deve_retornar_hello_world():
  event = {"nome": "Joao"}
  resposta = handler(event, None)
  resposta_esperada = {
    "statusCode": 200,
    "body": "Hello World!"
  }
  assert resposta == resposta_esperada
