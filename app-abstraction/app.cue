package app

import "github.com/cue-lang/cue-deployment-patterns/app-abstraction/platform"

platform.#Deployment & {
    let base = platform.#WebApp & {
        AppName=name: "test-app"
        image: {
            registry: "my-registry.com"
            name: AppName
        }
        AppPort=port: 8080
        healthCheck: port: AppPort
        scaling: cpuUtilizationThreshold: 0.7
    }

    preview: base & {
        image: tag: "v3"
        hostname: "test-app.example-dev.com"
        env: DEBUG: "true"
        scaling: minReplicas: 1
    }
    preprod: base & {
        image: tag: "v2"
        hostname: "test-app.example-preprod.com"
        scaling: prod.scaling
    }
    prod: base & {
        image: tag: "v1"
        hostname: "test-app.example.com"
        scaling: {
            minReplicas: 3
            maxReplicas: minReplicas * 10
        }
    }
}
