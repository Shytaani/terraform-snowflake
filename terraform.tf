terraform {
  cloud {
    organization = "shytaani-personal"

    workspaces {
      name = "ws-tf-snowflake"
    }
  }

  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.93.0"
    }
  }

  required_version = "~> 1.9"
}