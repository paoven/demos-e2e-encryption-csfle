resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  topic_name    = "orders"
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.env-admin-kafka-api-key.id
    secret = confluent_api_key.env-admin-kafka-api-key.secret
  }
}

resource "confluent_api_key" "env-admin-schema-registry-api-key" {
  display_name = "${var.resources_prefix}env-admin-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'csfle-env-admin' service account"
  owner {
    id          = confluent_service_account.csfle-env-admin.id
    api_version = confluent_service_account.csfle-env-admin.api_version
    kind        = confluent_service_account.csfle-env-admin.kind
  }

  managed_resource {
    id          = confluent_schema_registry_cluster.advanced.id
    api_version = confluent_schema_registry_cluster.advanced.api_version
    kind        = confluent_schema_registry_cluster.advanced.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }

  # The goal is to ensure that confluent_role_binding.env-admin-environment-admin is created before
  # confluent_api_key.env-manager-schema-registry-api-key is used to create instances of
  # confluent_schema resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.env-admin-schema-registry-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_schema resources instead.
  depends_on = [
    confluent_role_binding.env-admin-role-binding
  ]
}



resource "confluent_tag" "pii" {
  name        = "PII"
  description = "PII tag description"
  rest_endpoint = confluent_schema_registry_cluster.advanced.rest_endpoint
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.advanced.id
  }

  credentials {
    key    = confluent_api_key.env-admin-schema-registry-api-key.id
    secret = confluent_api_key.env-admin-schema-registry-api-key.secret
  }
}

resource "confluent_schema_registry_kek" "hcvault_kek-rot1" {
  name        = "kek-csfle-hashicorp-rot1"
  kms_type    = "hcvault"
  kms_key_id  = "http://127.0.0.1:8200/transit/keys/csfle" #var.hashicorp_kms_key_arn
  shared      = false
  hard_delete = true

  schema_registry_cluster {
    id = confluent_schema_registry_cluster.advanced.id
  }

  rest_endpoint = confluent_schema_registry_cluster.advanced.rest_endpoint

  credentials {
    key    = confluent_api_key.env-admin-schema-registry-api-key.id
    secret = confluent_api_key.env-admin-schema-registry-api-key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_schema" "orders" {
  recreate_on_update = false
  hard_delete = true
  lifecycle {
    prevent_destroy = false
  }

  rest_endpoint = confluent_schema_registry_cluster.advanced.rest_endpoint
  schema_registry_cluster {
    id = confluent_schema_registry_cluster.advanced.id
  }

  credentials {
    key    = confluent_api_key.env-admin-schema-registry-api-key.id
    secret = confluent_api_key.env-admin-schema-registry-api-key.secret
  }

  # https://developer.confluent.io/learn-kafka/schema-registry/schema-subjects/#topicnamestrategy
  subject_name = "orders-value"
  format       = "AVRO"
  # tag is also explicitly defined in purchase.avsc ("confluent:tags": ["PII"]) "for customer_id" field
  schema       = file("./schemas/orders.avro")

 ruleset {
    domain_rules {
      name   = "encrypt"
      kind   = "TRANSFORM"
      type   = "ENCRYPT"
      mode   = "WRITEREAD"
      tags   = [confluent_tag.pii.name]
      params = {
        "encrypt.kek.name" = confluent_schema_registry_kek.hcvault_kek-rot1.name #change only this to rotate a dek
        "encrypt.kms.key.id": confluent_schema_registry_kek.hcvault_kek-rot1.kms_key_id #change only this along with name to rotate the kek
        "encrypt.kms.type": "hcvault",
      }
      on_failure = "ERROR,NONE"
    }
  }

}