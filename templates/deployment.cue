package templates

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

#Deployment: appsv1.#Deployment & {
	#config:    #Config
	apiVersion: "apps/v1"
	kind:       "Deployment"
	metadata:   #config.metadata
	spec: appsv1.#DeploymentSpec & {
		replicas: #config.replicas
		selector: matchLabels: #config.selector.labels
		template: {
			metadata: {
				labels: #config.selector.labels
				if #config.pod.annotations != _|_ {
					annotations: #config.pod.annotations
				}
			}
			spec: corev1.#PodSpec & {
				containers: [
					{
						name:            #config.metadata.name
						image:           #config.image.reference
						imagePullPolicy: #config.image.pullPolicy
						args: [
							"-config=/render/config.yaml"
						]
						ports: [
							{
								name:          "http"
								containerPort: 8080
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							{
								name: "config"
								mountPath: "/config"
							},
							{
								name: "render"
								mountPath: "/render"
							}
						]
						readinessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
							initialDelaySeconds: 5
							periodSeconds:       10
						}
						livenessProbe: {
							tcpSocket: {
								port: "http"
							}
							initialDelaySeconds: 5
							periodSeconds:       5
						}
						if #config.resources != _|_ {
							resources: #config.resources
						}
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
					},
					{
						name:            "vault-proxy"
						image:					 #config.vault.sidecar.image.reference
						imagePullPolicy: #config.vault.sidecar.image.pullPolicy
						command: [
							"/bin/sh",
							"-c",
							"vault proxy -config=/config/proxy.config.hcl"
						]
						ports: [
							{
								name:          "proxy"
								containerPort: #config.vault.sidecar.proxy.port
								protocol:      "TCP"
							},
						]
						volumeMounts: [
							{
								name:	"config"
								mountPath: "/config"
							},
						]
						readinessProbe: {
							httpGet: {
								path: "/"
								port: "http"
							}
							initialDelaySeconds: 5
							periodSeconds:       10
						}
						livenessProbe: {
							tcpSocket: {
								port: "http"
							}
							initialDelaySeconds: 5
							periodSeconds:       5
						}
						if #config.resources != _|_ {
							resources: #config.resources
						}
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
					},
					{
						name:            "vault-agent"
						image:					 #config.vault.sidecar.image.reference
						imagePullPolicy: #config.vault.sidecar.image.pullPolicy
						command: [
							"/bin/sh",
							"-c",
							"vault agent -config=/config/agent.config.hcl"
						]
						volumeMounts: [
							{
								name:	"config"
								mountPath: "/config"
							},
							{
								name: "render"
								mountPath: "/render"
							},
						]
						if #config.resources != _|_ {
							resources: #config.resources
						}
						if #config.securityContext != _|_ {
							securityContext: #config.securityContext
						}
					},
				]
				if #config.pod.affinity != _|_ {
					affinity: #config.pod.affinity
				}
				if #config.pod.imagePullSecrets != _|_ {
					imagePullSecrets: #config.pod.imagePullSecrets
				}
				volumes: [
					{
						name: "config"
						configMap: {
						  name: #config.metadata.name
					  }
					},
					{
						name: "render"
						emptyDir: {}
					}
				]
			}
		}
	}
}
