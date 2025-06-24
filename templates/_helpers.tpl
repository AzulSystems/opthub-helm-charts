{{/*
These components do not scale and there is currently no
need for them to scale with the amount of compile brokers,
so this is the static value that will always be the same,
except when manually tuned.
*/}}
{{- define "_sizing.nonScalingComponents.vCores" -}}
{{- $dbCpu := .Values.db.resources.requests.cpu -}}
{{- $dbReplicas := .Values.db.replicas -}}
{{- mulf $dbCpu $dbReplicas -}}
{{- end -}}

{{- define "_sizing.broker.vCores" -}}
{{- .Values.compileBroker.resources.requests.cpu -}}
{{- end -}}

{{- define "_sizing.cache.vCores" -}}
{{- .Values.cache.resources.requests.cpu -}}
{{- end -}}

{{- define "_sizing.gateway.vCores" -}}
{{- .Values.gateway.resources.requests.cpu -}}
{{- end -}}

{{- define "sizing.compileBroker.replicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.compileBroker.replicas -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.vCores "type" "brokers") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.gateway.replicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.gateway.replicas -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.vCores "type" "gateways") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.cache.replicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.cache.replicas -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.vCores "type" "caches") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.compileBroker.minReplicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.compileBroker.autoscaler.min -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.minVCores "type" "brokers") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.compileBroker.maxReplicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.compileBroker.autoscaler.max -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.maxVCores "type" "brokers") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.gateway.minReplicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.gateway.autoscaler.min -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.minVCores "type" "gateways") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.gateway.maxReplicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.gateway.autoscaler.max -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.maxVCores "type" "gateways") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.cache.minReplicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.cache.autoscaler.min -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.minVCores "type" "caches") -}}
{{- end -}}
{{- end -}}

{{- define "sizing.cache.maxReplicas" -}}
{{- if .Values.simpleSizing.disabled -}}
{{- .Values.cache.autoscaler.max -}}
{{- else -}}
{{- include "_calculateReplicas" (dict "Values" .Values "inputCapacity" .Values.simpleSizing.maxVCores "type" "caches") -}}
{{- end -}}
{{- end -}}

{{/*
Calculates a suitable amount of replicas for the compile brokers, gateways or caches,
based on "type" input argument as returning a map from the template does not work.

Since there is no suitable way of doing condition-driven loops in the templates,
variables cannot be re-defined and are strictly scope-bound,
the formula uses recursion instead.

Expected input argumens in received context:
Values - passed in values from the root context
brokers - current iterated number of compile brokers, optional, defaults to 1
inputCapacity - amount of vCores that we need to fit into
type - one of "gateways", "caches" and "brokers" - indicates which replica amount to return
*/}}
{{- define "_calculateReplicas" -}}
{{- $brokers := max 1 (default 1 .brokers) -}}
{{- $caches := max .Values.cache.autoscaler.min (ceil (divf $brokers .Values.simpleSizing.relationships.brokersPerCache)) -}}
{{- $gateways := max .Values.gateway.autoscaler.min (ceil (divf $brokers .Values.simpleSizing.relationships.brokersPerGateway)) -}}
{{- $brokerVCores := mulf $brokers (include "_sizing.broker.vCores" .) -}}
{{- $cacheVCores := mulf $caches (include "_sizing.cache.vCores" .) -}}
{{- $gatewayVCores := mulf $gateways (include "_sizing.gateway.vCores" .) -}}
{{- $totalVCores := addf $brokerVCores $cacheVCores $gatewayVCores (include "_sizing.nonScalingComponents.vCores" .) -}}
{{- if lt $totalVCores (.inputCapacity | float64) -}}
{{- $newBrokers := add 1 $brokers -}}
{{- include "_calculateReplicas" (dict "Values" .Values "brokers" $newBrokers "type" .type "inputCapacity" .inputCapacity) -}}
{{- else -}}
{{/* If we no longer fit inside the alotted capacity, decrease compile brokers, so that we fit in. */}}
{{- $diff := subf $totalVCores .inputCapacity -}}
{{- $toSubtract := ceil (divf $diff (include "_sizing.broker.vCores" .)) -}}
{{- $updatedBrokers := max 0 (sub $brokers $toSubtract) -}}
{{- if eq .type "brokers" -}}
{{- $updatedBrokers -}}
{{- else if eq .type "caches" -}}
{{- $caches -}}
{{- else if eq .type "gateways" -}}
{{- $gateways -}}
{{- else -}}
{{- -1 -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Helper functions for calculating database size from given storage resource limits */}}
{{- define "_getBytesFromResourceString" -}}
{{- $sizes := dict "Gi" 1073_741_824 "G" 1000_000_000 "Mi" 1048_576 "M" 1000_000 "Ki" 1024 "K" 1000 "B" 1 -}}
{{- $suffix := regexFind "[A-Za-z]+" . -}}
{{- mulf (trimSuffix $suffix . ) (get $sizes $suffix) | int -}}
{{- end -}}

{{/* get apropriate volume size(persistent or ephemeral) and "reserve" 1G for system on shared ephemeral volume */}}
{{- define "_getDatabaseVolumeSpaceInB" -}}
{{- if .Values.db.persistentDataVolume.enabled -}}
{{- include "_getBytesFromResourceString" .Values.db.persistentDataVolume.size -}}
{{- else -}}
{{- sub (include "_getBytesFromResourceString" (get .Values.db.resources.requests "ephemeral-storage")) 1073741824 -}}
{{- end -}}
{{- end -}}

{{- define "_getDatabaseSizeInB" -}}
{{- mulf (include "_getDatabaseVolumeSpaceInB" .) 0.9 | int -}}
{{- end -}}

{{- define "_getCodecacheEvictionTargetSizeInB" -}}
{{- $targetSizeString := .Values.codeCache.cleaner.targetSize | toString -}}
{{- if eq $targetSizeString "0" -}}
{{- mulf (include "_getDatabaseVolumeSpaceInB" .) 0.9 0.6 | int -}}
{{- else -}}
{{- .Values.codeCache.cleaner.targetSize -}}
{{- end -}}
{{- end -}}


{{- define "_getProfilesSpaceInB" -}}
{{- include "_getBytesFromResourceString" .Values.readyNowOrchestrator.cleaner.externalPersistentStorageSoftLimit -}}
{{- end -}}

{{- define "_getProfilesWarningSizeInB" -}}
{{- if eq "0" (.Values.readyNowOrchestrator.cleaner.warningSize | toString) -}}
{{- mulf (include "_getProfilesSpaceInB" .) 0.9 | int -}}
{{- else -}}
{{- $warningSize := .Values.readyNowOrchestrator.cleaner.warningSize -}}
{{- $warningSize -}}
{{- end -}}
{{- end -}}

{{- define "_getProfilesEvictionTargetSizeInB" -}}
{{- if eq "0" (.Values.readyNowOrchestrator.cleaner.targetSize | toString) -}}
{{- mulf (include "_getProfilesSpaceInB" .) 0.9 0.6 | int -}}
{{- else -}}
{{- $targetSize := .Values.readyNowOrchestrator.cleaner.targetSize | toString -}}
{{- $targetSize -}}
{{- end -}}
{{- end -}}

{{- define "_getGwProxyOverloadManagerMaxHeapSize" -}}
{{- if eq "0" (.Values.gwProxy.overloadManager.maxHeapSizeBytes | toString) -}}
{{- if ((((.Values.gwProxy).resources).limits).memory) }}
{{- mulf (include "_getBytesFromResourceString" .Values.gwProxy.resources.limits.memory) .Values.gwProxy.overloadManager.maxHeapSizePodRatio | int -}}
{{- else -}}
104857600 {{- /* default 100 Mi if no setting is present*/ -}}
{{- end -}}
{{- else -}}
{{- include "_getBytesFromResourceString" .Values.gwProxy.overloadManager.maxHeapSizeBytes -}}
{{- end -}}
{{- end -}}

{{/*
Helpers below are introduced to calculate RNO per-generation properies. Helpers implementation
has hardcoded some defaults that should match the corresponding values at
readyNowOrchestrator.promotion.
*/}}

{{/* Derives MinProfileSizePerGeneration value */}}
{{- define "_getPromotionMinProfileSizePerGeneration" -}}
{{- $defaultMinSize := 1000000 | int64 -}}
{{- $defaultMinSizePerGeneration := print "0:" $defaultMinSize -}}
{{- $actualMinSize := .minProfileSize | int64 -}}
{{- $actualMinSizePerGeneration := .minProfileSizePerGeneration -}}
{{/*
  In case minProfileSize doesn't equal to the default, but minProfileSizePerGeneration is still equal to its
  default value, set changed minProfileSize for all generations. 
*/}}
{{- if and (ne $defaultMinSize $actualMinSize) (eq $defaultMinSizePerGeneration $actualMinSizePerGeneration) -}}
{{- print "0:" $actualMinSize -}}
{{- else -}}
{{- $actualMinSizePerGeneration -}}
{{- end -}}
{{- end -}}

{{/* Derives MinProfileDurationPerGeneration value */}}
{{- define "_getPromotionMinProfileDurationPerGeneration" -}}
{{- $defaultMinDuration := "PT2M" -}}
{{- $defaultMinDurationPerGeneration := print "0:" $defaultMinDuration -}}
{{- $actualMinDuration := .minProfileDuration -}}
{{- $actualMinDurationPerGeneration := .minProfileDurationPerGeneration -}}
{{/* Similar logic used in "_getPromotionMinProfileSizePerGeneration" function */}}
{{- if and (ne $defaultMinDuration $actualMinDuration) (eq $defaultMinDurationPerGeneration $actualMinDurationPerGeneration) -}}
{{- print "0:" $actualMinDuration -}}
{{- else -}}
{{- $actualMinDurationPerGeneration -}}
{{- end -}}
{{- end -}}

{{- define "getPromotionMinProfileSizePerGeneration" -}}
{{- $inputMinProfileSize := .Values.readyNowOrchestrator.promotion.minProfileSize | int64 -}}
{{- $inputMinProfileSizePerGeneration := .Values.readyNowOrchestrator.promotion.minProfileSizePerGeneration -}}
{{ include "_getPromotionMinProfileSizePerGeneration" (dict "minProfileSize" $inputMinProfileSize "minProfileSizePerGeneration" $inputMinProfileSizePerGeneration) }}
{{- end -}}

{{- define "getPromotionMinProfileDurationPerGeneration" -}}
{{- $inputMinProfileDuration := .Values.readyNowOrchestrator.promotion.minProfileDuration -}}
{{- $inputMinProfileDurationPerGeneration := .Values.readyNowOrchestrator.promotion.minProfileDurationPerGeneration -}}
{{ include "_getPromotionMinProfileDurationPerGeneration" (dict "minProfileDuration" $inputMinProfileDuration "minProfileDurationPerGeneration" $inputMinProfileDurationPerGeneration) }}
{{- end -}}


{{- define "validateRequiredValues" -}}
{{- if not .Values.storage.blobStorageService }}
{{- required "Error: value storage.blobStorageService is required. Please see documentation for more details." .Values.storage.blobStorageService -}}
{{- else if not (typeOf .Values.storage.blobStorageService | eq "string") }}
{{- fail "Error: value storage.blobStorageService must be a string." -}}
{{- else if not (has .Values.storage.blobStorageService (list "s3" "azure-blob" "gcp-blob")) }}
{{- fail "Error: value storage.blobStorageService must be one of the following: s3, azure-blob, gcp-blob." -}}
{{- end }}
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

{{- define "db.secretName" -}}
  {{- if .Values.secrets.db.existingSecret -}}
    {{ .Values.secrets.db.existingSecret }}
  {{- else -}}
    {{ "infrastructure-credentials" }}
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
    {{ "gateway-ssl-secret" }}
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

{{- define "mgmtGateway.serviceAccount" -}}
  {{- if .Values.mgmtGateway.existingServiceAccount -}}
    {{ .Values.mgmtGateway.existingServiceAccount }}
  {{- else if .Values.deployment.serviceAccount.existingServiceAccount -}}
    {{ .Values.deployment.serviceAccount.existingServiceAccount }}
  {{- else -}}
    {{ "opthub-mgmt-gateway" }}
  {{- end -}}
{{- end -}}

