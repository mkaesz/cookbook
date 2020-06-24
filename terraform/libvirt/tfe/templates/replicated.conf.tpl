{
    "DaemonAuthenticationType":          "password",
    "DaemonAuthenticationPassword":      "${replicated_password}",
    "TlsBootstrapType":                  "server-path",
    "TlsBootstrapHostname":              "${hostname}",
    "TlsBootstrapCert":                  "/opt/tfe/config/${hostname}.crt",
    "TlsBootstrapKey":                   "/opt/tfe/config/${hostname}.key",
    "BypassPreflightChecks":             true,
    "ImportSettingsFrom":                "/opt/tfe/config/settings.json",
    "LicenseFileLocation":               "/opt/tfe/config/tfe-license.rli",
    "LicenseBootstrapAirgapPackagePath": "/opt/tfe/config/tfe-bundle.airgap"
}
