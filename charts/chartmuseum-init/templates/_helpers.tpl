{{/*
Expand the name of the chart.
*/}}
{{- define "chartmuseum-init.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{- define "chartmuseum-init.fullname" -}}
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
{{- define "chartmuseum-init.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chartmuseum-init.labels" -}}
helm.sh/chart: {{ include "chartmuseum-init.chart" . }}
{{ include "chartmuseum-init.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chartmuseum-init.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chartmuseum-init.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{- define "chartmuseum-init.jobSpec" -}}
spec:
  {{ toYaml .Values.jobSpec | nindent 2 }}
  template:
    spec:
      containers:
        - name: init-charts
          {{ with .Values.image }}
          image: "{{ .repository }}:{{ .tag | default $.Chart.AppVersion }}"
          imagePullPolicy: {{ .pullPolicy }}
          {{ end }}
          command: ["/bin/sh", "-c"]
          {{ with .Values.chartsRepository }}
          args:
            - git clone {{ .url }} -b {{ .branch }};
              cd {{ .path }};
              {{ .command }};
          {{ end }}
          env:
            - name: HELM_REPO_USERNAME
              valueFrom:
                secretKeyRef:
                  {{ toYaml .Values.usernameSecretKeyRef | nindent 18 }}
            - name: HELM_REPO_PASSWORD
              valueFrom:
                secretKeyRef:
                  {{ toYaml .Values.passwordSecretKeyRef | nindent 18 }}
            - name: HELM_REPO_URL
              value: "{{ .Values.chartmuseumUrl }}"
          {{ with .Values.resources }}
          resources:
            {{ toYaml . | nindent 12 }}
          {{ end}}
      {{ with .Values.nodeSelector }}
      nodeSelector:
        {{ toYaml . | nindent 8 }}
      {{ end }}
      restartPolicy: Never
      automountServiceAccountToken: false
{{ end }}