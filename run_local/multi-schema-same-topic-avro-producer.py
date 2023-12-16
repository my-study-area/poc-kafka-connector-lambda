from confluent_kafka.schema_registry import  topic_record_subject_name_strategy
from confluent_kafka import SerializingProducer
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka.avro import SerializerError
from avro.schema import parse
from faker import Faker

fake = Faker()
TOPIC_NAME = 'example-stream-avro'
SCHEMA_REGISTRY_URL = 'http://localhost:8081'
BOOTSTRAP_SERVERS = 'localhost:9092'
SCHEMA_REGISTRY_CLIENT = SchemaRegistryClient({'url': SCHEMA_REGISTRY_URL })

# Define multiple Avro schemas for the values
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

# Create AvroSerializers using the parsed schemas and the Schema Registry client
SERIALIZER = {
    'greeting': AvroSerializer(schema_str=SCHEMAS.get('greeting'), schema_registry_client=SCHEMA_REGISTRY_CLIENT, conf={'subject.name.strategy': topic_record_subject_name_strategy}),
    'user': AvroSerializer(schema_str=SCHEMAS.get('user'), schema_registry_client=SCHEMA_REGISTRY_CLIENT, conf={'subject.name.strategy': topic_record_subject_name_strategy}),
    'key': AvroSerializer(schema_str=SCHEMAS.get('key'), schema_registry_client=SCHEMA_REGISTRY_CLIENT)
}

# Configuration dictionary for Kafka producers.
PRODUCER_CONFIG = {
    'user': {
        'bootstrap.servers': BOOTSTRAP_SERVERS,
        'key.serializer': SERIALIZER.get('key'),
        'value.serializer': SERIALIZER.get('user')
    },
    'greeting': {
        'bootstrap.servers': BOOTSTRAP_SERVERS,
        'key.serializer': SERIALIZER.get('key'),
        'value.serializer': SERIALIZER.get('greeting')
    }
}

# Create a SerializingProducer instance with the configuration
PRODUCER = {
    'user': SerializingProducer(PRODUCER_CONFIG.get('user')),
    'greeting': SerializingProducer(PRODUCER_CONFIG.get('greeting'))
}

# Function to create and send a message with a specific value serializer
def send_message(producer, value):
    try:
        key = {"timestamp": int(fake.unix_time())}
        producer.produce(topic=TOPIC_NAME, value=value, key=key)
        producer.flush()
        print(f"Message sent successfully")
    except SerializerError as e:
        print(f"Message serialization failed: {str(e)}")
        raise e
    except Exception as e:
        print(f"Message production failed: {str(e)}")
        raise e

# Send a message using the first value schema
greeting_producer = PRODUCER.get('greeting')        
greeting_message = f"Hello, {fake.country()}!"
greeting_value = {"language": "ENGLISH", "greeting": greeting_message}
send_message(greeting_producer, greeting_value)

# Send a message using the second value schema
user_producer = PRODUCER.get('user')
user_message = {"name": fake.name(), "age": fake.pyint()}
send_message(user_producer, user_message)
