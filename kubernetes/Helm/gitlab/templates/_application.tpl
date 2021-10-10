{{/* vim: set filetype=mustache: */}}

{{- define "gitlab.application.labels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- end -}}

{{- define "gitlab.standardLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- if .Values.global.application.create }}
{{ include "gitlab.application.labels" . }}
{{- end -}}
{{- end -}}

{{- define "gitlab.immutableLabels" -}}
app: {{ template "name" . }}
chart: {{ .Chart.Name }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{ if .Values.global.application.create -}}
{{ include "gitlab.application.labels" . }}
{{- end -}}
{{- end -}}

{{- define "gitlab.commonLabels" -}}
{{- $commonLabels := (merge .Values.common.labels .Values.global.common.labels) }}
{{- if $commonLabels }}
{{-   range $key, $value := $commonLabels }}
{{ $key }}: {{ $value }}
{{-   end }}
{{- end -}}
{{- end -}}

{{- define "gitlab.nodeSelector" -}}
{{- $nodeSelector := default .Values.global.nodeSelector .Values.nodeSelector -}}
{{- if $nodeSelector }}
nodeSelector:
  {{- toYaml $nodeSelector | nindent 2 }}
{{- end }}
{{- end -}}
