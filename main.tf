provider "snowflake" {
  //account, user and password are set as environment variables

  // optional
  role      = var.role
  warehouse = var.warehouse
}

// Database
resource "snowflake_database" "terraform_database" {
  name                        = var.database
  comment                     = "Database created and managed by Terraform"
  data_retention_time_in_days = 10
}

// Schema
resource "snowflake_schema" "e_commerce_schema" {
  name     = "E_COMMERCE"
  database = snowflake_database.terraform_database.name
  comment = "Schema created and managed by Terraform"
  data_retention_days = snowflake_database.terraform_database.data_retention_time_in_days
}

// Customers Table
resource "snowflake_table" "customers" {
  name      = "CUSTOMERS"
  database  = snowflake_database.terraform_database.name
  schema    = snowflake_schema.e_commerce_schema.name
  data_retention_time_in_days = snowflake_database.terraform_database.data_retention_time_in_days

  column {
    name = "CUSTOMER_ID"
    type = "INTEGER AUTOINCREMENT PRIMARY KEY"
  }

  column {
    name = "FIRST_NAME"
    type = "STRING"
  }

  column {
    name = "LAST_NAME"
    type = "STRING"
  }

  column {
    name = "EMAIL"
    type = "STRING"
  }

  column {
    name = "SIGNUP_DATE"
    type = "DATE"
  }
}

// Products Table
resource "snowflake_table" "products" {
  name      = "PRODUCTS"
  database  = snowflake_database.terraform_database.name
  schema    = snowflake_schema.e_commerce_schema.name
  data_retention_time_in_days = snowflake_database.terraform_database.data_retention_time_in_days

  column {
    name = "PRODUCT_ID"
    type = "INTEGER AUTOINCREMENT PRIMARY KEY"
  }

  column {
    name = "PRODUCT_NAME"
    type = "STRING"
  }

  column {
    name = "CATEGORY"
    type = "STRING"
  }

  column {
    name = "PRICE"
    type = "DECIMAL(10, 2)"
  }

  column {
    name = "STOCK_QUANTITY"
    type = "INTEGER"
  }
}

// Orders Table
resource "snowflake_table" "orders" {
  name      = "ORDERS"
  database  = snowflake_database.terraform_database.name
  schema    = snowflake_schema.e_commerce_schema.name
  data_retention_time_in_days = snowflake_database.terraform_database.data_retention_time_in_days

  column {
    name = "ORDER_ID"
    type = "INTEGER AUTOINCREMENT PRIMARY KEY"
  }

  column {
    name = "CUSTOMER_ID"
    type = "INTEGER"
  }

  column {
    name = "ORDER_DATE"
    type = "DATE"
  }

  column {
    name = "TOTAL_AMOUNT"
    type = "DECIMAL(10, 2)"
  }
}

// Order Details Table
resource "snowflake_table" "order_details" {
  name      = "ORDER_DETAILS"
  database  = snowflake_database.terraform_database.name
  schema    = snowflake_schema.e_commerce_schema.name
  data_retention_time_in_days = snowflake_database.terraform_database.data_retention_time_in_days

  column {
    name = "ORDER_DETAIL_ID"
    type = "INTEGER AUTOINCREMENT PRIMARY KEY"
  }

  column {
    name = "ORDER_ID"
    type = "INTEGER"
  }

  column {
    name = "PRODUCT_ID"
    type = "INTEGER"
  }

  column {
    name = "QUANTITY"
    type = "INTEGER"
  }

  column {
    name = "PRICE"
    type = "DECIMAL(10, 2)"
  }
}

// Foreign Key for Orders Table and Customers Table
resource "snowflake_table_constraint" "fk_customer_id" {
    name = "FK_CUSTOMER_ID"
    type = "FOREIGN KEY"
    table_id = snowflake_table.orders.qualified_name
    columns = ["CUSTOMER_ID"]
    foreign_key_properties {
      references {
        table_id = snowflake_table.customers.qualified_name
        columns = ["CUSTOMER_ID"]
      }
    }
}

// Foreign Key for Order Details Table and Orders Table
resource "snowflake_table_constraint" "fk_order_id" {
    name = "FK_ORDER_ID"
    type = "FOREIGN KEY"
    table_id = snowflake_table.order_details.qualified_name
    columns = ["ORDER_ID"]
    foreign_key_properties {
      references {
        table_id = snowflake_table.orders.qualified_name
        columns = ["ORDER_ID"]
      }
    }
}

// Foreign Key for Order Details Table and Products Table
resource "snowflake_table_constraint" "fk_product_id" {
    name = "FK_PRODUCT_ID"
    type = "FOREIGN KEY"
    table_id = snowflake_table.order_details.qualified_name
    columns = ["PRODUCT_ID"]
    foreign_key_properties {
      references {
        table_id = snowflake_table.products.qualified_name
        columns = ["PRODUCT_ID"]
      }
    }
}

// File Format
resource "snowflake_file_format" "e_comm_csv_format" {
  name     = "E_COMM_CSV_FORMAT"
  database = snowflake_database.terraform_database.name
  schema   = snowflake_schema.e_commerce_schema.name
  comment = "CSV file format created and managed by Terraform"
  format_type = "CSV"
  skip_header = 1
}

// Internal Stage
resource "snowflake_stage" "e_comm_int_stage" {
  name     = "E_COMM_INT_STAGE"
  database = snowflake_database.terraform_database.name
  schema   = snowflake_schema.e_commerce_schema.name
  comment = "Internal stage created and managed by Terraform"
}

// Procedure
resource "snowflake_procedure" "load_customers" {
  name     = "LOAD_CUSTOMERS"
  database = snowflake_database.terraform_database.name
  schema   = snowflake_schema.e_commerce_schema.name
  language = "SQL"
  arguments {
    name = "FILE_NAME"
    type = "VARCHAR"
  }
  comment = "Procedure to load customers data"
  return_type = "VARCHAR"
  execute_as = "CALLER"
  statement = <<EOT
    COPY INTO CUSTOMERS
    FROM @E_COMM_INT_STAGE/FILE_NAME
    FILE_FORMAT = (FORMAT_NAME = E_COMM_CSV_FORMAT)
    ON_ERROR = 'CONTINUE';
  EOT
  
}