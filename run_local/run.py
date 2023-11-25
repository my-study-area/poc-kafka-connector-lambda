import os
import sys
 
current = os.path.dirname(os.path.realpath(__file__))
parent = os.path.dirname(current)
sys.path.append(parent)

from app.lambda_function import handler

os.environ['ENVIRONMENT'] = 'dev'


if __name__ == '__main__':
  print('Hello World!')
  handler({"nome": "Joao"}, None)
