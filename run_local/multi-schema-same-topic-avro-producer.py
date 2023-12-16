import os
from confluent_kafka.schema_registry import  topic_record_subject_name_strategy
from confluent_kafka import SerializingProducer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka.avro import SerializerError
from avro.schema import parse
from faker import Faker

fake = Faker()

# Function to create a producer with a specific value serializer
def create_producer(value_schema_str):
    schema_registry_client = SchemaRegistryClient({'url': SCHEMA_REGISTRY_URL})
    key_schema_str = SCHEMAS.get('key')

    key_serializer = AvroSerializer(schema_str=key_schema_str, schema_registry_client=schema_registry_client)
    value_serializer = AvroSerializer(schema_str=value_schema_str, schema_registry_client=schema_registry_client, conf={'subject.name.strategy': topic_record_subject_name_strategy})

    producer_config = {
        'bootstrap.servers': BOOTSTRAP_SERVERS,
        'key.serializer': key_serializer,
        'value.serializer': value_serializer
    }

    return SerializingProducer(producer_config)

# Function to create and send a message with a specific value serializer
def send_message(producer, topic_name, value):
    try:
        key = {"timestamp": int(fake.unix_time())}
        producer.produce(topic=topic_name, value=value, key=key)
        print(f"Message sent successfully")
    except SerializerError as e:
        print(f"Message serialization failed: {str(e)}")
    except Exception as e:
        print(f"Message production failed: {str(e)}")

# Configurations
TOPIC_NAME = os.getenv('TOPIC_NAME', 'example-stream-avro')
SCHEMA_REGISTRY_URL = os.getenv('SCHEMA_REGISTRY_URL', 'http://localhost:8081')
BOOTSTRAP_SERVERS = os.getenv('BOOTSTRAP_SERVERS', 'localhost:9092')

# Define Avro schemas for the values
SCHEMAS = {
    'greeting': """ {
        "namespace": "my.test",
        "name": "value1",
        "type": "record",
        "fields" : [
          { "name" : "language", "type" : "string" },
          { "name" : "greeting", "type" : "string" }
        ]
      }
    """,
    'user': """ {
        "namespace": "my.test",
        "name": "value2",
        "type": "record",
        "fields" : [
          { "name" : "name", "type" : "string" },
          { "name" : "age", "type" : "int" }
        ]
      }
    """,
    'key': """ {
        "namespace": "my.test",
        "name": "key",
        "type": "record",
        "fields" : [
          { "name" : "timestamp", "type" : "long" }
        ]
    }
    """
}

# Send a message using the first value schema
greeting_schema_str = SCHEMAS.get('greeting')
greeting_producer = create_producer(greeting_schema_str)
greeting_message = f"Hello, {fake.country()}!"
greeting_value = {"language": "ENGLISH", "greeting": greeting_message}
send_message(greeting_producer, TOPIC_NAME,greeting_value)

# Send a message using the second value schema
user_schema_str = SCHEMAS.get('user')
user_producer = create_producer(user_schema_str)
user_message = {"name": fake.name(), "age": fake.pyint()}
send_message(user_producer, TOPIC_NAME,user_message)

greeting_producer.flush()
user_producer.flush()
