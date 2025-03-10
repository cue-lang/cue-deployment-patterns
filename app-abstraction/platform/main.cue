package platform

#ConstrainedString: string & =~"^[A-Za-z-]{1,253}$"
#Port: int & >=1024 & <=65535

#Deployment: {
    preview: #App
    preprod: #App
    prod: #App

    let deploymentTargets = {
        "preview": preview
        "preprod": preprod
        "prod": prod
    }

    for deploymentTargetName, appDefinition in deploymentTargets {
        let httpRoute = {
            apiVersion: "gateway.networking.k8s.io/v1"
            kind: "HTTPRoute"
            metadata: name: appDefinition.name
            spec: {
                hostnames: [appDefinition.hostname]
                parentRefs: [{name: "web-gateway-lb"}]
                rules: [{
                    backendRefs: [{
                        name: service.metadata.name
                        port: service.spec.ports[0].port
                    }]
                }]
            }
        }

        let service = {
            apiVersion: "v1"
            kind: "Service"
            metadata: name: appDefinition.name
            spec: {
                ports: [{
                    protocol: "TCP"
                    port: appDefinition.port
                    targetPort: port
                }]
                selector: deployment.metadata.labels
            }
        }

        let deployment = {
            apiVersion: "apps/v1"
            kind: "Deployment"
            DeploymentMetadata=metadata: {
                name: appDefinition.name
                labels: "app.kubernetes.io/name": appDefinition.name
            }
            spec: {
                selector: matchLabels: DeploymentMetadata.labels
                template: {
                    metadata: labels: DeploymentMetadata.labels
                    spec: containers: [{
                        name: DeploymentMetadata.name
                        let imageRef = appDefinition.image
                        image: "\(imageRef.registry)/\(imageRef.name):\(imageRef.tag)"
                        ports: [{containerPort: appDefinition.port}]
                        env: [for k, v in appDefinition.env {name: k, value: v}]
                        resources: {
                            requests: {
                                cpu: 1
                                memory: "2Gi"
                            }
                            limits: {
                                memory: "4Gi"
                            }
                        }
                    }]
                }
            }
        }

        let autoscaler = {
            apiVersion: "autoscaling/v2"
            kind: "HorizontalPodAutoscaler"
            metadata: name: appDefinition.name
            spec: {
                scaleTargetRef: {
                    apiVersion: deployment.apiVersion
                    kind: deployment.kind
                    name: deployment.metadata.name
                }
                minReplicas: appDefinition.scaling.minReplicas
                maxReplicas: appDefinition.scaling.maxReplicas
                metrics: [{
                    type: "Resource"
                    resource: {
                        name: "cpu"
                        target: {
                            type: "Utilization"
                            averageUtilization: appDefinition.scaling.cpuUtilizationThreshold
                        }
                    }
                }]
            }
        }
        
        manifests: (deploymentTargetName): [httpRoute, service, deployment, autoscaler]
    }
}

#App: #WebApp // | #OtherApp

#WebApp: {
    name: #ConstrainedString
    image: {
        registry: string
        name: #ConstrainedString
        tag: string
    }
    port: #Port
    env: [EnvName=string]: string
    hostname: string
    healthCheck: {
        path: string | *"/healthz"
        port: #Port
    }
    scaling: {
        minReplicas: int & >0 //& <=maxReplicas
        maxReplicas: int & <=999 | *minReplicas //& >=minReplicas 
        cpuUtilizationThreshold: float & >=0.1 & <=0.95
    }
}
