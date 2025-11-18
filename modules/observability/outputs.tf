output "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring resources"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "logging_namespace" {
  description = "Kubernetes namespace for logging resources"
  value       = kubernetes_namespace.logging.metadata[0].name
}

output "prometheus_service" {
  description = "Prometheus service name"
  value       = "kube-prometheus-stack-prometheus"
}

output "grafana_service" {
  description = "Grafana service name"
  value       = "kube-prometheus-stack-grafana"
}

output "alertmanager_service" {
  description = "AlertManager service name"
  value       = "kube-prometheus-stack-alertmanager"
}

output "elasticsearch_service" {
  description = "Elasticsearch service name"
  value       = "elasticsearch-master"
}

output "kibana_service" {
  description = "Kibana service name"
  value       = "kibana-kibana"
}

output "logstash_service" {
  description = "Logstash service name"
  value       = "logstash-logstash"
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = "admin"
}

output "monitoring_storage_class" {
  description = "Storage class name for monitoring"
  value       = kubernetes_storage_class.monitoring.metadata[0].name
}

output "logging_storage_class" {
  description = "Storage class name for logging"
  value       = kubernetes_storage_class.logging.metadata[0].name
}
