output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.csfle-demo-environment.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.standard.id}
  Kafka topic name: ${confluent_kafka_topic.orders.topic_name}
  Schema Registry URL: ${data.confluent_schema_registry_cluster.advanced.rest_endpoint}

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  ${confluent_service_account.csfle-env-admin.display_name}:                     ${confluent_service_account.csfle-env-admin.id}
  ${confluent_service_account.csfle-env-admin.display_name}'s Kafka API Key:     "${confluent_api_key.env-admin-kafka-api-key.id}"
  ${confluent_service_account.csfle-env-admin.display_name}'s Kafka API Secret:  "${confluent_api_key.env-admin-kafka-api-key.secret}"
  ${confluent_service_account.csfle-env-admin.display_name}'s Schema Registry API Key: "${confluent_api_key.env-admin-schema-registry-api-key.id}"
  ${confluent_service_account.csfle-env-admin.display_name}'s Schema RegistryAPI Secret: "${confluent_api_key.env-admin-schema-registry-api-key.secret}"

  ${confluent_service_account.csfle-app-producer.display_name}:                    ${confluent_service_account.csfle-app-producer.id}
  ${confluent_service_account.csfle-app-producer.display_name}'s Kafka API Key:    "${confluent_api_key.app-producer-kafka-api-key.id}"
  ${confluent_service_account.csfle-app-producer.display_name}'s Kafka API Secret: "${confluent_api_key.app-producer-kafka-api-key.secret}"
  ${confluent_service_account.csfle-app-producer.display_name}'s Schema Registry API Key: "${confluent_api_key.app-producer-schema-registry-api-key.id}"
  ${confluent_service_account.csfle-app-producer.display_name}'s Schema RegistryAPI Secret: "${confluent_api_key.app-producer-schema-registry-api-key.secret}"

  ${confluent_service_account.csfle-app-consumer-encrypted.display_name}:                    ${confluent_service_account.csfle-app-consumer-encrypted.id}
  ${confluent_service_account.csfle-app-consumer-encrypted.display_name}'s Kafka API Key:    "${confluent_api_key.csfle-app-consumer-encrypted-kafka-api-key.id}"
  ${confluent_service_account.csfle-app-consumer-encrypted.display_name}'s Kafka API Secret: "${confluent_api_key.csfle-app-consumer-encrypted-kafka-api-key.secret}"
  ${confluent_service_account.csfle-app-consumer-encrypted.display_name}'s Schema Registry API Key: "${confluent_api_key.csfle-app-consumer-encrypted-kafka-api-key.id}"
  ${confluent_service_account.csfle-app-consumer-encrypted.display_name}'s Schema RegistryAPI Secret: "${confluent_api_key.csfle-app-consumer-encrypted-kafka-api-key.secret}"

  ${confluent_service_account.csfle-app-consumer-decrypted.display_name}:                    ${confluent_service_account.csfle-app-consumer-decrypted.id}
  ${confluent_service_account.csfle-app-consumer-decrypted.display_name}'s Kafka API Key:    "${confluent_api_key.csfle-app-consumer-decrypted-kafka-api-key.id}"
  ${confluent_service_account.csfle-app-consumer-decrypted.display_name}'s Kafka API Secret: "${confluent_api_key.csfle-app-consumer-decrypted-kafka-api-key.secret}"
  ${confluent_service_account.csfle-app-consumer-decrypted.display_name}'s Schema Registry API Key: "${confluent_api_key.csfle-app-consumer-decrypted-kafka-api-key.id}"
  ${confluent_service_account.csfle-app-consumer-decrypted.display_name}'s Schema RegistryAPI Secret: "${confluent_api_key.csfle-app-consumer-decrypted-kafka-api-key.secret}"


  In order to use the Confluent CLI v2 to produce and consume messages from topic '${confluent_kafka_topic.orders.topic_name}' using Kafka API Keys
  of ${confluent_service_account.csfle-app-producer.display_name} and ${confluent_service_account.csfle-app-consumer-encrypted.display_name} service accounts
  run the following commands:

  # 1. Produce key-value records to topic '${confluent_kafka_topic.orders.topic_name}' by using ${confluent_service_account.csfle-app-producer.display_name}'s Kafka API Key
  export VAULT_ADDR='http://127.0.0.1:8200'
  export VAULT_TOKEN=root-token
  kafka-avro-console-producer --broker-list ${confluent_kafka_cluster.standard.bootstrap_endpoint} \
  --topic ${confluent_kafka_topic.orders.topic_name}  \
  --property auto.register.schemas=false --property use.latest.version=true \
  --producer-property security.protocol=SASL_SSL --producer-property sasl.mechanism=PLAIN \
  --producer-property sasl.jaas.config="org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${confluent_api_key.app-producer-kafka-api-key.id}\" password=\"${confluent_api_key.app-producer-kafka-api-key.secret}\";" \
  --producer-property client.dns.lookup=use_all_dns_ips --producer-property client.dns.lookup=use_all_dns_ips --producer-property acks=all \
  --property schema.registry.url=${data.confluent_schema_registry_cluster.advanced.rest_endpoint} \
  --property basic.auth.credentials.source=USER_INFO \
  --property basic.auth.user.info=${confluent_api_key.app-producer-schema-registry-api-key.id}:${confluent_api_key.app-producer-schema-registry-api-key.secret} \
  --property value.schema.id=${confluent_schema.orders.schema_identifier}

  # Enter a few records and then press 'Ctrl-C' when you're done.
  # Sample records:
  # {"number":1,"shipping_address":"899 W Evelyn Ave, Mountain View, CA 94041, USA","amount":15.00}
  # {"number":2,"shipping_address":"1 Bedford St, London WC2E 9HG, United Kingdom","amount":5.00}
  # {"number":3,"shipping_address":"3307 Northland Dr Suite 400, Austin, TX 78731, USA","amount":10.00}


  # 2. Consume records from topic '${confluent_kafka_topic.orders.topic_name}' by using ${confluent_service_account.csfle-app-consumer-encrypted.display_name}'s Kafka API Key
  kafka-avro-console-consumer --group confluent_cli_consumer_encrypted_fields --topic ${confluent_kafka_topic.orders.topic_name}  --bootstrap-server   ${confluent_kafka_cluster.standard.bootstrap_endpoint}   --property schema.registry.url=${data.confluent_schema_registry_cluster.advanced.rest_endpoint} --property basic.auth.user.info="${confluent_api_key.csfle-app-consumer-encrypted-schema-registry-api-key.id}:${confluent_api_key.csfle-app-consumer-encrypted-schema-registry-api-key.secret}" --property basic.auth.credentials.source=USER_INFO --from-beginning --consumer-property security.protocol=SASL_SSL --consumer-property sasl.mechanism=PLAIN --consumer-property sasl.jaas.config="org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${confluent_api_key.csfle-app-consumer-encrypted-kafka-api-key.id}\" password=\"${confluent_api_key.csfle-app-consumer-encrypted-kafka-api-key.secret}\";"

  # When you are done, press 'Ctrl-C'.

  # 3. Open another shell to consume records and see decrypted fields from topic '${confluent_kafka_topic.orders.topic_name}' by using ${confluent_service_account.csfle-app-consumer-decrypted.display_name}'s Kafka API Key
  export VAULT_ADDR='http://127.0.0.1:8200'
  export VAULT_TOKEN=root-token
  kafka-avro-console-consumer --group confluent_cli_consumer_decrypted_fields --topic ${confluent_kafka_topic.orders.topic_name}  --bootstrap-server   ${confluent_kafka_cluster.standard.bootstrap_endpoint}   --property schema.registry.url=${data.confluent_schema_registry_cluster.advanced.rest_endpoint} --property basic.auth.user.info="${confluent_api_key.csfle-app-consumer-decrypted-schema-registry-api-key.id}:${confluent_api_key.csfle-app-consumer-decrypted-schema-registry-api-key.secret}" --property basic.auth.credentials.source=USER_INFO --from-beginning --consumer-property security.protocol=SASL_SSL --consumer-property sasl.mechanism=PLAIN --consumer-property sasl.jaas.config="org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${confluent_api_key.csfle-app-consumer-decrypted-kafka-api-key.id}\" password=\"${confluent_api_key.csfle-app-consumer-decrypted-kafka-api-key.secret}\";"
  # When you are done, press 'Ctrl-C'.
  EOT

  sensitive = true
}