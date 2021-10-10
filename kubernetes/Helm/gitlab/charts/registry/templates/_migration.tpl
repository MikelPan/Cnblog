{{/*
Return migration configuration.
*/}}
{{- define "registry.migration.config" -}}
migration:
{{-   if .Values.migration.disablemirrorfs }}
  disablemirrorfs: true
{{-   end }}
{{- end -}}