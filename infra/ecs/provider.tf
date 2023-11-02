terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1" # Defina a região desejada
  profile = "sandbox"   # Define o perfil desejado
}
