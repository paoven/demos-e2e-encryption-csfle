resource "confluent_environment" "csfle-demo-environment" {
  display_name = "${var.resources_prefix}csfle-demo"

  stream_governance {
    package = "ADVANCED"
  }
}

data  "confluent_schema_registry_cluster" "advanced" {
 

  environment {
    id = confluent_environment.csfle-demo-environment.id
  }

  depends_on = [
    confluent_kafka_cluster.standard
  ]

}

# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster
resource "confluent_kafka_cluster" "standard" {
  display_name = "inventory"
  availability = "SINGLE_ZONE"
  cloud        = var.confluent_csp
  region       = var.confluent_csp_region
  standard {}
  environment {
    id = confluent_environment.csfle-demo-environment.id
  }
}

// 'app-manager' service account is required in this configuration to create 'orders' topic and assign roles
// to 'app-producer' and 'app-consumer' service accounts.
resource "confluent_service_account" "csfle-env-admin" {
  display_name = "${var.resources_prefix}csfle-env-admin"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "env-admin-role-binding" {
  principal   = "User:${confluent_service_account.csfle-env-admin.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.csfle-demo-environment.resource_name
}

resource "confluent_api_key" "env-admin-kafka-api-key" {
  display_name = "${var.resources_prefix}csfle-app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.csfle-env-admin.id
    api_version = confluent_service_account.csfle-env-admin.api_version
    kind        = confluent_service_account.csfle-env-admin.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.env-admin-role-binding
  ]
}


resource "confluent_service_account" "csfle-app-consumer-encrypted" {
  display_name = "${var.resources_prefix}csfle-app-consumer-encrypted"
  description  = "Service account to consume from 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_service_account" "csfle-app-consumer-decrypted" {
  display_name = "${var.resources_prefix}csfle-app-consumer-decrypted"
  description  = "Service account to consume from 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_api_key" "csfle-app-consumer-decrypted-kafka-api-key" {
  display_name = "${var.resources_prefix}csfle-app-consumer-decrypted-kafka-api-key"
  description  = "Kafka API Key that is owned by 'csfle-app-consumer-decrypted' service account"
  owner {
    id          = confluent_service_account.csfle-app-consumer-decrypted.id
    api_version = confluent_service_account.csfle-app-consumer-decrypted.api_version
    kind        = confluent_service_account.csfle-app-consumer-decrypted.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }
}

resource "confluent_api_key" "csfle-app-consumer-encrypted-kafka-api-key" {
  display_name = "${var.resources_prefix}csfle-app-consumer-encrypted-kafka-api-key"
  description  = "Kafka API Key that is owned by 'csfle-app-consumer-encrypted' service account"
  owner {
    id          = confluent_service_account.csfle-app-consumer-encrypted.id
    api_version = confluent_service_account.csfle-app-consumer-encrypted.api_version
    kind        = confluent_service_account.csfle-app-consumer-encrypted.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }
}


resource "confluent_service_account" "csfle-app-producer" {
  display_name = "${var.resources_prefix}csfle-app-producer"
  description  = "Service account to produce to 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "app-producer-developer-write" {
  principal   = "User:${confluent_service_account.csfle-app-producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.orders.topic_name}"
}

resource "confluent_role_binding" "app-producer-kek-developer-write" {
  principal   = "User:${confluent_service_account.csfle-app-producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.hcvault_kek-rot1.name}"
}

resource "confluent_role_binding" "app-producer-subject-developer-read" {
  principal   = "User:${confluent_service_account.csfle-app-producer.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/subject=${confluent_schema.orders.subject_name}"
}

resource "confluent_api_key" "app-producer-kafka-api-key" {
  display_name = "${var.resources_prefix}csfle-app-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'csfle-app-producer' service account"
  owner {
    id          = confluent_service_account.csfle-app-producer.id
    api_version = confluent_service_account.csfle-app-producer.api_version
    kind        = confluent_service_account.csfle-app-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }

}

resource "confluent_api_key" "app-producer-schema-registry-api-key" {
  display_name = "${var.resources_prefix}app-producer-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'csfle-app-producer' service account"
  owner {
    id          = confluent_service_account.csfle-app-producer.id
    api_version = confluent_service_account.csfle-app-producer.api_version
    kind        = confluent_service_account.csfle-app-producer.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.advanced.id
    api_version = data.confluent_schema_registry_cluster.advanced.api_version
    kind        = data.confluent_schema_registry_cluster.advanced.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }
}


// Note that in order to consume from a topic, the principal of the consumer ('app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
resource "confluent_role_binding" "csfle-app-consumer-decrypted-developer-read-from-topic" {
  principal   = "User:${confluent_service_account.csfle-app-consumer-decrypted.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.orders.topic_name}"
}

resource "confluent_role_binding" "csfle-app-consumer-decrypted-developer-read-from-group" {
  principal = "User:${confluent_service_account.csfle-app-consumer-decrypted.id}"
  role_name = "DeveloperRead"
  // The existing value of crn_pattern's suffix (group=confluent_cli_consumer_*) are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update it to match your target consumer group ID.
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=confluent_cli_consumer_*"
}

resource "confluent_role_binding" "csfle-app-consumer-decrypted-developer-read-from-kek" {
  principal   = "User:${confluent_service_account.csfle-app-consumer-decrypted.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.hcvault_kek-rot1.name}"
}

resource "confluent_role_binding" "csfle-app-consumer-decrypted-subject-developer-read" {
  principal   = "User:${confluent_service_account.csfle-app-consumer-decrypted.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/subject=${confluent_schema.orders.subject_name}"
}

resource "confluent_api_key" "csfle-app-consumer-decrypted-schema-registry-api-key" {
  display_name = "${var.resources_prefix}csfle-app-consumer-decrypted-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'csfle-app-consumer-decrypted' service account"
  owner {
    id          = confluent_service_account.csfle-app-consumer-decrypted.id
    api_version = confluent_service_account.csfle-app-consumer-decrypted.api_version
    kind        = confluent_service_account.csfle-app-consumer-decrypted.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.advanced.id
    api_version = data.confluent_schema_registry_cluster.advanced.api_version
    kind        = data.confluent_schema_registry_cluster.advanced.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }
}



// Note that in order to consume from a topic, the principal of the consumer ('app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
resource "confluent_role_binding" "csfle-app-consumer-encrypted-developer-read-from-topic" {
  principal   = "User:${confluent_service_account.csfle-app-consumer-encrypted.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/topic=${confluent_kafka_topic.orders.topic_name}"
}

resource "confluent_role_binding" "csfle-app-consumer-encrypted-developer-read-from-group" {
  principal = "User:${confluent_service_account.csfle-app-consumer-encrypted.id}"
  role_name = "DeveloperRead"
  // The existing value of crn_pattern's suffix (group=confluent_cli_consumer_*) are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update it to match your target consumer group ID.
  crn_pattern = "${confluent_kafka_cluster.standard.rbac_crn}/kafka=${confluent_kafka_cluster.standard.id}/group=confluent_cli_consumer_*"
}

resource "confluent_role_binding" "csfle-app-consumer-encrypted-developer-read-from-kek" {
  principal   = "User:${confluent_service_account.csfle-app-consumer-encrypted.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/kek=${confluent_schema_registry_kek.hcvault_kek-rot1.name}"
}

resource "confluent_role_binding" "csfle-app-consumer-encrypted-subject-developer-read" {
  principal   = "User:${confluent_service_account.csfle-app-consumer-encrypted.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_schema_registry_cluster.advanced.resource_name}/subject=${confluent_schema.orders.subject_name}"
}

resource "confluent_api_key" "csfle-app-consumer-encrypted-schema-registry-api-key" {
  display_name = "csfle-app-consumer-encrypted-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'csfle-app-consumer-encrypted' service account"
  owner {
    id          = confluent_service_account.csfle-app-consumer-encrypted.id
    api_version = confluent_service_account.csfle-app-consumer-encrypted.api_version
    kind        = confluent_service_account.csfle-app-consumer-encrypted.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.advanced.id
    api_version = data.confluent_schema_registry_cluster.advanced.api_version
    kind        = data.confluent_schema_registry_cluster.advanced.kind

    environment {
      id = confluent_environment.csfle-demo-environment.id
    }
  }
}