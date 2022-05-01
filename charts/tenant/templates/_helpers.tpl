{{- define "tenant.name" -}}
{{- $name := default .Release.Name .Values.nameOverride }}
{{- printf "flux-tenant-%s" $name | trunc 63 | trimSuffix "-" }}
{{- end }}