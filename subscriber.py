import os
import json
import subprocess
import signal
from google.api_core import retry
from google.cloud import pubsub_v1

# Update the credentials file
credentials_path = 'credentials/iot-led-matrix-subscriber-credentials.json'
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credentials_path

subscriber = pubsub_v1.SubscriberClient()
#Update the subscription path
subscription_path = 'projects/iot-led-matrix/subscriptions/chat-bot-subscription'

NUM_MESSAGES = 1

print(f"Listening for messages on {subscription_path}...\n")

def processMessage(message):
    # Decode the message payload from JSON

    payload = json.loads(message.data.decode("utf-8"))

    # Extract data from the message payload
    space_name = payload["space"]["name"]
    user_name = payload["user"]["displayName"]
    text = payload["message"]["text"]

    print(f"Received message from {user_name} in {space_name}: {text}")
    firstName = user_name.split(" ")[0];
    displayText = firstName + " says " + text
    command = "sudo ./text-scroller -f ../fonts/texgyre-27.bdf -s2 -y-8 -B0,0,155 --led-cols=64 --led-slowdown-gpio=4 " +  displayText
    # Run the executable with sudo
    process = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True, preexec_fn=os.setsid)

    try:
        output, error = process.communicate(timeout=10)
    except subprocess.TimeoutExpired:
        print("Timeout expired")
        os.killpg(os.getpgid(process.pid), signal.SIGTERM)


while True:

    response = subscriber.pull(
        request={"subscription": subscription_path, "max_messages": NUM_MESSAGES},
        retry=retry.Retry(deadline=300),
    )

    ack_ids = []
    for received_message in response.received_messages:
        if (received_message.ack_id):
            ack_ids.append(received_message.ack_id)
            processMessage(received_message.message)

    # Acknowledges the received messages so they will not be sent again.
    if ack_ids:
        subscriber.acknowledge(
            request={"subscription": subscription_path, "ack_ids": ack_ids}
        )