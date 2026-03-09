{{- define "validateRequiredValues" -}}
{{- if not .Values.storage.blobStorageService }}
{{- required "Error: value storage.blobStorageService is required. Please see documentation for more details." .Values.storage.blobStorageService -}}
{{- else if not (typeOf .Values.storage.blobStorageService | eq "string") }}
{{- fail "Error: value storage.blobStorageService must be a string." -}}
{{- else if not (has .Values.storage.blobStorageService (list "s3" "azure-blob" "gcp-blob")) }}
{{- fail "Error: value storage.blobStorageService must be one of the following: s3, azure-blob, gcp-blob." -}}
{{- end }}
{{- end -}}

{{- define "storageLocationBucket" -}}
{{- if eq "s3" .Values.storage.blobStorageService -}}
{{- .Values.storage.s3.commonBucket -}}
{{- else if eq "gcp-blob" .Values.storage.blobStorageService -}}
{{- .Values.storage.gcpBlob.commonBucket -}}
{{- else if eq "azure-blob" .Values.storage.blobStorageService -}}
{{- .Values.storage.azureBlob.container -}}
{{- end  }}
{{- end -}}

{{- define "storageLocationPathPrefixWithNamespace" -}}
{{- if .Values.storage.pathPrefix -}}
{{- .Values.storage.pathPrefix | replace "%namespace%" .Release.Namespace -}}/
{{- end -}}
{{- end -}}

{{- define "blobStorage.s3.secretName" -}}
  {{- if .Values.secrets.blobStorage.s3.existingSecret -}}
    {{ .Values.secrets.blobStorage.s3.existingSecret }}
  {{- else -}}
    {{ "blob-storage-credentials" }}
  {{- end -}}
{{- end -}}

{{- define "azure.storage.secretName" -}}
  {{- if .Values.secrets.blobStorage.azure.existingSecret -}}
    {{ .Values.secrets.blobStorage.azure.existingSecret }}
  {{- else -}}
    {{ "azure-storage-credentials" }}
  {{- end -}}
{{- end -}}

{{- define "ssl.secretName" -}}
  {{- if .Values.ssl.existingSecret -}}
    {{ .Values.ssl.existingSecret }}
  {{- else -}}
    {{ "gw-proxy-ssl-secret" }}
  {{- end -}}
{{- end -}}

{{- define "operator.serviceAccount" -}}
  {{- if .Values.operator.existingServiceAccount -}}
    {{ .Values.operator.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-operator" }}
  {{- end -}}
{{- end -}}


{{- define "cache.serviceAccount" -}}
  {{- if .Values.cache.existingServiceAccount -}}
    {{ .Values.cache.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-cache" }}
  {{- end -}}
{{- end -}}

{{- define "compileBroker.serviceAccount" -}}
  {{- if .Values.compileBroker.existingServiceAccount -}}
    {{ .Values.compileBroker.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-compile-broker" }}
  {{- end -}}
{{- end -}}

{{- define "gateway.serviceAccount" -}}
  {{- if .Values.gateway.existingServiceAccount -}}
    {{ .Values.gateway.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-gateway" }}
  {{- end -}}
{{- end -}}

{{- define "logStore.serviceAccount" -}}
  {{- if .Values.logStore.existingServiceAccount -}}
    {{ .Values.logStore.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-log-store" }}
  {{- end -}}
{{- end -}}

{{- define "taskExecutor.serviceAccount" -}}
  {{- if .Values.taskExecutor.existingServiceAccount -}}
    {{ .Values.taskExecutor.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-task-executor" }}
  {{- end -}}
{{- end -}}

{{- define "mgmtGateway.serviceAccount" -}}
  {{- if .Values.mgmtGateway.existingServiceAccount -}}
    {{ .Values.mgmtGateway.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-mgmt-gateway" }}
  {{- end -}}
{{- end -}}
