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

{{/*
Render "true" when the workloads should get the blob storage credential env vars:
the matching storage backend (and auth method) is selected and credentials are
available, either from an existing Secret or from literal values (the chart then
creates the Secret).
*/}}
{{- define "blobStorage.s3.hasCredentials" -}}
  {{- if eq "s3" .Values.storage.blobStorageService -}}
    {{- if or .Values.secrets.blobStorage.s3.existingSecret (and .Values.secrets.blobStorage.s3.accesskey .Values.secrets.blobStorage.s3.secretkey) -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "blobStorage.azure.hasSasToken" -}}
  {{- if and (eq "azure-blob" .Values.storage.blobStorageService) (eq "sas-token" .Values.storage.azureBlob.authMethod) -}}
    {{- if or .Values.secrets.blobStorage.azure.existingSecret .Values.secrets.blobStorage.azure.sasToken -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "blobStorage.azure.hasConnectionString" -}}
  {{- if and (eq "azure-blob" .Values.storage.blobStorageService) (eq "connection-string" .Values.storage.azureBlob.authMethod) -}}
    {{- if or .Values.secrets.blobStorage.azure.existingSecret .Values.secrets.blobStorage.azure.connectionString -}}
      true
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Env vars with blob storage credentials for the selected storage backend. They
reference the Secret created by the chart or the one given via existingSecret.
Render nothing when no credentials are configured (e.g. default credentials).
Usage: {{- with include "blobStorage.envvars" . | trim }}{{- . | nindent <indent> }}{{- end }}
*/}}
{{- define "blobStorage.envvars" -}}
{{- if include "blobStorage.s3.hasCredentials" . }}
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "blobStorage.s3.secretName" . }}
      key: {{ .Values.secrets.blobStorage.s3.accessKeySecretKey }}
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "blobStorage.s3.secretName" . }}
      key: {{ .Values.secrets.blobStorage.s3.secretAccessKeySecretKey }}
{{- end }}
{{- if include "blobStorage.azure.hasSasToken" . }}
- name: BLOB_STORAGE_AZURE_BLOB_SASTOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "azure.storage.secretName" . }}
      key: {{ .Values.secrets.blobStorage.azure.sasTokenSecretKey }}
{{- end }}
{{- if include "blobStorage.azure.hasConnectionString" . }}
- name: BLOB_STORAGE_AZURE_BLOB_CONNECTIONSTRING
  valueFrom:
    secretKeyRef:
      name: {{ include "azure.storage.secretName" . }}
      key: {{ .Values.secrets.blobStorage.azure.connectionStringSecretKey }}
{{- end }}
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

{{- define "quarkus-config.name" -}}
quarkus-config-{{ include "opthub.properties.content" . | sha256sum | trunc 8 }}
{{- end -}}

{{- define "opthub.container.args" -}}
- "-Dsun.net.inetaddr.negative.ttl=1"
- "-Dsun.net.inetaddr.ttl=5"
{{- end -}}

{{/*
Built-in pod-level securityContext of the OptHub server components (everything except gwProxy).
The IDs are deliberately all 10001, matching the uid and gid of the cnc user in the base image.
*/}}
{{- define "opthub.podSecurityContext.default" -}}
runAsNonRoot: true
runAsUser: 10001
runAsGroup: 10001
fsGroup: 10001
{{- end -}}

{{/*
Built-in pod-level securityContext of gwProxy, which runs a different image.
*/}}
{{- define "opthub.podSecurityContext.gwProxy.default" -}}
runAsNonRoot: true
runAsUser: 65532
runAsGroup: 65532
fsGroup: 65532
{{- end -}}

{{/*
Built-in container-level securityContext, shared by all components.
*/}}
{{- define "opthub.containerSecurityContext.default" -}}
readOnlyRootFilesystem: true
allowPrivilegeEscalation: false
capabilities:
  drop:
    - ALL
{{- end -}}

{{/*
Renders a `securityContext:` field. The override <component>.<key> replaces the built-in default as a whole:
  - absent (or null)  -> the default
  - {} (empty map)    -> `securityContext: {}`, i.e. none of the defaults
  - non-empty map     -> exactly that map
Arguments (dict): name (component values key), component (its values), key, default (name of the
template that renders the default map).
A user-supplied null is dropped by Helm only for keys declared in values.yaml; the new keys are not
declared there, so null is handled here and treated like an absent override.
Top-level null fields inside a map are dropped, so a later -f file can remove one field of an earlier override.
*/}}
{{- define "opthub.securityContext" -}}
{{- $component := .component | default dict -}}
{{- $override := ternary (index $component .key) nil (hasKey $component .key) -}}
{{- if and (not (kindIs "invalid" $override)) (not (kindIs "map" $override)) -}}
{{- fail (printf "Error: value %s.%s must be a map (use {} to remove the default securityContext), got: %s" .name .key (toJson $override)) -}}
{{- end -}}
{{- if kindIs "invalid" $override -}}
securityContext:
{{ include .default . | indent 2 }}
{{- else -}}
{{- $fields := dict -}}
{{- range $field, $value := $override -}}
{{- if not (kindIs "invalid" $value) -}}
{{- $_ := set $fields $field $value -}}
{{- end -}}
{{- end -}}
{{- if $fields -}}
securityContext:
{{ toYaml $fields | indent 2 }}
{{- else -}}
securityContext: {}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Pod-level securityContext. Also rejects <component>.spec.securityContext, which would render a second
`securityContext` key; <component>.podSecurityContext is the only supported way to configure it.
Arguments (dict): name, component, default (template name).
*/}}
{{- define "opthub.podSecurityContext" -}}
{{- if hasKey ((.component).spec | default dict) "securityContext" -}}
{{- fail (printf "Error: value %s.spec.securityContext is not supported. Use %s.podSecurityContext instead (it replaces the default pod securityContext as a whole; {} removes it)." .name .name) -}}
{{- end -}}
{{- include "opthub.securityContext" (dict "name" .name "component" .component "key" "podSecurityContext" "default" .default) -}}
{{- end -}}

{{/*
Container-level securityContext. Arguments (dict): name, component.
*/}}
{{- define "opthub.containerSecurityContext" -}}
{{- include "opthub.securityContext" (dict "name" .name "component" .component "key" "containerSecurityContext" "default" "opthub.containerSecurityContext.default") -}}
{{- end -}}

{{/* Renders "true" unless rbac.create is false (bool or string), so unset values keep today's behavior. */}}
{{- define "rbac.create" -}}
{{- if ne (toString ((.Values.rbac).create)) "false" -}}true{{- end -}}
{{- end -}}
