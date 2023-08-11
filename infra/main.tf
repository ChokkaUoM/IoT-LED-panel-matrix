# topics

resource "google_pubsub_topic" "topic_chatbot" {
  name = "chat-bot-topic"

  message_retention_duration = var.topic_retention_time
  project = var.project_id
}

# subscriptions

resource "google_pubsub_subscription" "subscription_chatbot" {
  name  = "chat-bot-subscription"
  topic = google_pubsub_topic.topic_chatbot.name
  project = var.project_id

  labels = {
    location = "melbourne"
  }

  message_retention_duration = var.topic_retention_time
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = var.subscription_expiration_time
  }
  retry_policy {
    minimum_backoff = var.subscription_retry_backoff_time
  }

  enable_message_ordering    = false
}

data "google_iam_policy" "publisher" {
  binding {
    role = "roles/pubsub.publisher"
    members = [
      "serviceAccount:chat-api-push@system.gserviceaccount.com",
    ]
  }
}

resource "google_pubsub_topic_iam_policy" "publisher_policy" {
  project = var.project_id
  topic = google_pubsub_topic.topic_chatbot.name
  policy_data = data.google_iam_policy.publisher.policy_data
}


resource "google_service_account" "chatbot_sub_sa" {
  project = var.project_id
  account_id = "chatbot-subscriber-sa"
  display_name = "chatbot subscriber service account"
}

resource "google_service_account_key" "chatbot_key" {
  service_account_id = google_service_account.chatbot_sub_sa.name
}


data "google_iam_policy" "subscriber" {
  binding {
    role = "roles/pubsub.subscriber"
    members = [
      "serviceAccount:chatbot-subscriber-sa@iot-led-matrix.iam.gserviceaccount.com",
    ]
  }
}

resource "google_pubsub_subscription_iam_policy" "subscriber_policy" {
  project = var.project_id
  subscription = google_pubsub_subscription.subscription_chatbot.name
  policy_data  = data.google_iam_policy.subscriber.policy_data
}








