{{/*
Expand the name of the chart.
*/}}
{{- define "infisical.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "infisical.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "infisical.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "infisical.labels" -}}
helm.sh/chart: {{ include "infisical.chart" . }}
{{ include "infisical.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "infisical.selectorLabels" -}}
app.kubernetes.io/name: {{ include "infisical.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "infisical.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "infisical.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the PostgreSQL connection URI
*/}}
{{- define "infisical.databaseUri" -}}
{{- if .Values.postgresql.enabled }}
{{- $host := printf "%s-postgresql" .Release.Name }}
{{- $port := "5432" }}
{{- $database := .Values.postgresql.auth.database }}
{{- $username := .Values.postgresql.auth.username }}
{{- printf "postgresql://%s:$(POSTGRES_PASSWORD)@%s:%s/%s" $username $host $port $database }}
{{- else if .Values.externalDatabase.uri }}
{{- .Values.externalDatabase.uri }}
{{- end }}
{{- end }}

{{/*
Get the Redis connection URL
*/}}
{{- define "infisical.redisUrl" -}}
{{- if .Values.redis.enabled }}
{{- $host := printf "%s-redis-master" .Release.Name }}
{{- printf "redis://:%s@%s:6379" "$(REDIS_PASSWORD)" $host }}
{{- else if .Values.externalRedis.url }}
{{- .Values.externalRedis.url }}
{{- end }}
{{- end }}

{{/*
Get the name of the secret containing Infisical secrets
*/}}
{{- define "infisical.secretName" -}}
{{- if .Values.infisical.existingSecret }}
{{- .Values.infisical.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "infisical.fullname" .) }}
{{- end }}
{{- end }}
