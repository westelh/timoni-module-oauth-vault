package templates

import (
	"strings"
	"encoding/yaml"
	corev1 "k8s.io/api/core/v1"
)

#ConfigMap: corev1.#ConfigMap & {
	#config: #Config
	apiVersion: "v1"
	kind: "ConfigMap"
	metadata: #config.metadata

	let auth_block = """
		auto_auth {
		  method {
		    type = "kubernetes"
		    config = {
		      role = "\(#config.vault.server.auth.kubernetes.role)"
		    }
		  }
		  sink_file {
		    config = {
		      path = "/home/vault/sink"
		    }
		  }
		}
		"""
	let vault_block = """
		vault {
		  address = "\(#config.vault.server.address)"
		}
		"""

	data: {
		"agent.config.hcl": """
			\(auth_block)
			\(vault_block)
			template {
				source = "/config/config.yaml.ctmpl"
			  destination = "/render/config.yaml"
			}
			"""

		"proxy.config.hcl": """
			\(auth_block)
			\(vault_block)
			api_proxy {
				use_auto_auth_token = true
			}
			listener "tcp" {
			  address = "\(#config.vault.sidecar.proxy.address)"
			  tls_disable = true
			}
			"""

			"config.yaml.ctmpl": """
			ktor:
			  application:
			    modules:
			    \(strings.Replace(yaml.Marshal(#config.oauthVault.modules),"\n","\n    ", -1))
			  deployment:
			    host: 0.0.0.0
			    port: 8080
			user:
			  oidc:
			    provider: \(#config.vault.server.oidc.provider)
			    client: \(#config.vault.server.oidc.client)
			    callback: "\(#config.oauthVault.publicUrl)/user/oidc/callback"
			    scopes:
			      - openid
			      - google
			{{ with secret "kv/data/secrets/oauth-vault" -}}
			oauth:
			  google:
			    clientId: {{ .Data.data.client_id }}
			    clientSecret: {{ .Data.data.client_secret }}
			    callback: "\(#config.oauthVault.publicUrl)/google/callback"
			{{- end }}
			api:
			  auth:
			    jwt:
			      issuer: "\(#config.vault.server.identity.jwt.issuer)"
			      audience: "\(#config.vault.server.identity.jwt.audience)"
			vault:
			  addr: "http://127.0.0.1:\(#config.vault.sidecar.proxy.port)"
			  kv: kv
			"""
	}
}

