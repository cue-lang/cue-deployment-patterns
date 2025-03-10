# Application Abstraction

This pattern shows how you can define an application across several deployment targets (such as development and production environments).

## Concept

The application abstraction uses a unified configuration approach whereby the configuration for all possible states are represented within a shared context. Denoting differing configuration states as *environments*, this has several benefits:
- A declarative approach to defining environment-specific configuration
- Enhanced readability of configuration by sticking to CUE's core language design principles
- The ability to define cross-environment values, e.g. "This value in preprod should be the same in prod"
- Allows users to compose their abstracted configuration however they want

## Structure

The platform abstractions are defined in [platform](./platform/) under a seperate package. This package can be published within a module and distributed internally within your organisation.

The abstraction user defines their app as shown in [app.cue](./app.cue), with the [render](./render) script showing how you might choose to retrieve the rendered output from the configuration.

### Platform Package

The `platform` package contains two key definitions; `#Deployment`, and `#App`. `#Deployment` defines which deployment targets needs to be defined and how. It also puts these together into a lookup of deployment target to manifest list. `#App` is a union valid abstractions (in this case, only one called `#WebApp`). A user can choose this abstraction to populate their "desired" state for each deployment target.

## Usage

For example, to retrieve the YAML manifest stream for the preview environment:
```yaml
$ ./render preview
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: test-app
spec:
  hostnames:
    - test-app.example-dev.com
  parentRefs:
    - name: web-gateway-lb
  rules:
    - backendRefs:
        - name: test-app
          port: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: test-app
spec:
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  selector:
    app.kubernetes.io/name: test-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  labels:
    app.kubernetes.io/name: test-app
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: test-app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: test-app
    spec:
      containers:
        - name: test-app
          image: my-registry.com/test-app:v3
          ports:
            - containerPort: 8080
          env:
            - name: DEBUG
              value: "true"
          resources:
            requests:
              cpu: 1
              memory: 2Gi
            limits:
              memory: 4Gi
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: test-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: test-app
  minReplicas: 1
  maxReplicas: 1
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 0.7

```
