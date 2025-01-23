# Migrate from ApplicationSet Helm Hierarchy to Holos

This repository is a direct migration of the final [Helm Hierarchies - Saving
environment configurations on their own
files](https://medium.com/containers-101/using-helm-hierarchies-in-multi-source-argo-cd-applications-for-promoting-to-different-gitops-133c3bc93678)
recommended example to Holos.

## Why?

Multiple layers of yaml templates obfuscate the configuration, making it
difficult to comprehend changes.

1. The ApplicationSet loads config.json files and renders a yaml template to generate each Application.
2. The Application reads a hierarchy of value files, adding one layer for each.
3. The Helm chart is another layer of templated yaml.

For example, consider the final `ApplicationSet` recommended in the article.
The ApplicationSet uses a generator to render a Go template into an Application
resource.  There are 8 config.json files so we can expect 8 generated
Applications.

> [!NOTE]
> Maybe add a table here of the layers from TFA and follow it up with the layers in Holos.  Ideally there's just CUE, but we can talk about how in practice we have Kustomize so that's a layer, but the reason most people use Kustomize is to mix in resources and with Holos it's easy to mix in resources from CUE, so we can move closer to the ideal.

<details><summary>The ApplicationSet is one layer. 👈 Click me</summary>

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-my-envs-from-repo-with-version
  namespace: argocd
spec:
  goTemplate: true
  goTemplateOptions: ["missingkey=error"]
  generators:
  - git:
      repoURL: https://github.com/kostis-codefresh/multi-sources-example.git
      revision: HEAD
      files:
      - path: "appsets/4-final/env-config/**/config.json"
  template:
    metadata:
      name: '{{.env}}'
    spec:
      # The project the application belongs to.
      project: default
      sources:
        - repoURL: https://kostis-codefresh.github.io/multi-sources-example
          chart: my-chart
          targetRevision: '{{.chart}}'
          helm:
            valueFiles:
            - $values/my-values/common-values.yaml
            - $values/my-values/app-version/{{.version}}-values.yaml
            - $values/my-values/env-type/{{.type}}-values.yaml
            - $values/my-values/regions/{{.region}}-values.yaml
            - $values/my-values/envs/{{.env}}-values.yaml
        - repoURL: 'https://github.com/kostis-codefresh/multi-sources-example.git'
          targetRevision: HEAD
          ref: values
      # Destination cluster and namespace to deploy the application
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{.env}}'
      # Sync policy
      syncPolicy:
        syncOptions:
          - CreateNamespace=true
        automated:
          prune: true
          selfHeal: true
```

</details>

<details><summary>The config.json files are a second layer. 👈 Click me</summary>

```txt
❯ tree appsets/4-final/env-config/
appsets/4-final/env-config/
├── integration
│   ├── gpu
│   │   └── config.json
│   └── non-gpu
│       └── config.json
├── prod
│   ├── eu
│   │   └── config.json
│   └── us
│       └── config.json
├── qa
│   └── config.json
└── staging
    ├── asia
    │   └── config.json
    ├── eu
    │   └── config.json
    └── us
        └── config.json

12 directories, 8 files
```

</details>

<details><summary>The helm chart is a third layer. 👈 Click me</summary>

The manifest is mostly templated and we don't know what any of the values are.
They're hidden behind the ApplicationSet and the order in which Helm merges the
values files.

```yaml
# my-chart/templates/deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: trivial-go-web-app
  template:
    metadata:
      labels:
        app: trivial-go-web-app
    spec:
      containers:
      - name: webserver-simple
        imagePullPolicy: Always
        image: docker.io/kostiscodefresh/simple-env-app:{{ .Values.imageVersion }}
        ports:
        - containerPort: 8080
        env:
        - name: ENV
          value: {{ quote .Values.environment }}
        - name: ENV_TYPE
          value: {{ quote .Values.environmentType }}
        - name: REGION
          value: {{ quote .Values.region }}
        - name: PAYPAL_URL
          value: {{ quote .Values.paypalUrl }}
        - name: DB_USER
          value: {{ quote .Values.dbUser }}
        - name: DB_PASSWORD
          value: {{ quote .Values.dbPassword }}
        - name: GPU_ENABLED
          value: {{ quote .Values.gpuEnabled }}
        - name: UI_THEME
          value: {{ quote .Values.userInterfaceTheme }}
        - name: CACHE_SIZE
          value: {{ quote .Values.cacheSize }}
        - name: PAGE_LIMIT
          value: {{ quote .Values.pageLimit }}
        - name: SORTING
          value: {{ quote .Values.sorting }}
        - name: N_BUCKETS
          value: {{ quote .Values.nBuckets }}
```

</details>

The multiple layers of templating in combination with argocd-server rendering
the templates remotely results in difficult to comprehend configuration.  This
leads to production incidents and slows people down.

## What's the alternative?

`holos render` fully hydrates manifests so we can look directly at them.

```bash
holos render platform
```

```txt
rendered my-chart 0.2.0 for environment staging-eu in 180.208791ms
rendered my-chart 0.1.0 for environment prod-us in 180.674917ms
rendered my-chart 0.1.0 for environment prod-eu in 183.025667ms
rendered my-chart 0.1.0 for environment integration-gpu in 183.519375ms
rendered my-chart 0.2.0 for environment integration-non-gpu in 183.970084ms
rendered my-chart 0.2.0 for environment staging-us in 184.408459ms
rendered my-chart 0.2.0 for environment qa in 184.425041ms
rendered platform in 184.474ms
```

> [!IMPORTANT]
> Like an ApplicationSet, Holos generates Application resources from the data in
> the `config.json` files.  The main difference is `holos` does so locally and
> quickly (~200ms).

<details><summary>Holos renders legible Application resources. 👈 Click me</summary>

The fully rendered Application resources fully replace the more difficult to
read ApplicationSet.

```txt
❯ tree deploy/gitops
deploy/gitops
├── integration-gpu-my-chart-application.gen.yaml
├── integration-non-gpu-my-chart-application.gen.yaml
├── prod-eu-my-chart-application.gen.yaml
├── prod-us-my-chart-application.gen.yaml
├── qa-my-chart-application.gen.yaml
├── staging-eu-my-chart-application.gen.yaml
└── staging-us-my-chart-application.gen.yaml
```

```yaml
# deploy/gitops/prod-us-my-chart-application.gen.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
    labels:
        env: prod-us
    name: prod-us-my-chart
    namespace: argocd
spec:
    destination:
        server: https://kubernetes.default.svc
    project: default
    source:
        path: deploy/environments/prod-us/components/my-chart
        repoURL: https://github.com/holos-run/multi-sources-example.git
        targetRevision: main
```

</details>

<details><summary>Holos makes the config.json files visible. 👈 Click me</summary>

Holos makes it easy to inspect the `env-config/**/config.json` files we migrated without modification.

```bash
CUE_EXPERIMENT=embed holos cue export ./config/environments --out=yaml
```

Holos surfaces a hidden problem in the config data we migrated.  Note how
`staging/asia/config.json` duplicates `qa/config.json`, creating problems.

```yaml
config:
  qa/config.json:
    env: qa
    region: us
    type: non-prod
    version: qa
    chart: 0.2.0
  staging/asia/config.json:
    env: qa
    region: us
    type: non-prod
    version: qa
    chart: 0.2.0
  staging/eu/config.json:
    env: staging-eu
    region: eu
    type: non-prod
    version: staging
    chart: 0.2.0
  prod/eu/config.json:
    env: prod-eu
    region: eu
    type: prod
    version: prod
    chart: 0.1.0
  integration/gpu/config.json:
    env: integration-gpu
    region: us
    type: non-prod
    version: prod
    chart: 0.1.0
  staging/us/config.json:
    env: staging-us
    region: us
    type: non-prod
    version: staging
    chart: 0.2.0
  prod/us/config.json:
    env: prod-us
    region: us
    type: prod
    version: prod
    chart: 0.1.0
  integration/non-gpu/config.json:
    env: integration-non-gpu
    region: us
    type: non-prod
    version: qa
    chart: 0.2.0
```

</details>

<details><summary>Holos gives insight into the Helm chart. 👈 Click me</summary>

What you see is what you get.  The Application configures ArgoCD to reconcile
this manifest as-is in git with the cluster.  Hydration aids comprehension and
aligns more closely with GitOps principles than ApplicationSets and Helm
Hierarchies.

```yaml
# deploy/environments/prod-us/components/my-chart/my-chart.gen.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    argocd.argoproj.io/instance: prod-us-my-chart
  name: simple-service
  namespace: prod-us
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: trivial-go-web-app
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    argocd.argoproj.io/instance: prod-us-my-chart
  name: simple-deployment
  namespace: prod-us
spec:
  replicas: 10
  selector:
    matchLabels:
      app: trivial-go-web-app
  template:
    metadata:
      labels:
        app: trivial-go-web-app
    spec:
      containers:
      - env:
        - name: ENV
          value: prod-us
        - name: ENV_TYPE
          value: production
        - name: REGION
          value: us
        - name: PAYPAL_URL
          value: production.paypal.com
        - name: DB_USER
          value: prod_username
        - name: DB_PASSWORD
          value: prod_password
        - name: GPU_ENABLED
          value: "1"
        - name: UI_THEME
          value: dark
        - name: CACHE_SIZE
          value: 1024kb
        - name: PAGE_LIMIT
          value: "25"
        - name: SORTING
          value: Ascending
        - name: N_BUCKETS
          value: "42"
        image: docker.io/kostiscodefresh/simple-env-app:1.0
        imagePullPolicy: Always
        name: webserver-simple
        ports:
        - containerPort: 8080
```

</details>

## How?

Holos implements the [rendered manifest pattern].  We'll convert each function
of the [ApplicationSet] to the Holos equivalent changing as little as possible.

| ApplicationSet                                                                                        | Holos                                                                         |
| ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| generators.git to generate Applications                                                               | Load `env-config/**/config.json` files into one cue struct.                   |
| generated Application                                                                                 | Renders an Application for each component using ComponentConfig.              |
| Application template.metadata.name: '{{.env}}'                                                        | For each config.json file, add a component to Platform.spec.components.       |
| Multiple Sources for Application.template.spec.sources referring to a Helm chart and to Values files. | Single source Application referring to the fully rendered manifests.          |
| Helm hierarchy with Application.template.spec.sources.helm.valueFiles.                                | [Helm](https://holos.run/docs/v1alpha5/api/author/#Helm) valueFiles hierarchy |


## Result

 1. We have fully rendered Application resources which are clearly legible.
 2. Each Application reconciles fully rendered manifests which are also clearly legible.
 3. The configuration is _unified_ with CUE.  We can easily mix in additional
    resources like Kargo Stages for Progressive Delivery, which is the subject
    of the next article in the series.

We get fully rendered manifests for both the Application resources and the
variations of `my-chart`.  We no longer need to think about the order in which values are merged, CUE will complain quickly if there's a conflict.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    argocd.argoproj.io/instance: prod-us-my-chart
  name: simple-deployment
  namespace: prod-us
spec:
  replicas: 10
  selector:
    matchLabels:
      app: trivial-go-web-app
  template:
    metadata:
      labels:
        app: trivial-go-web-app
    spec:
      containers:
      - env:
        - name: ENV
          value: prod-us
        - name: ENV_TYPE
          value: production
        - name: REGION
          value: us
        - name: PAYPAL_URL
          value: production.paypal.com
        - name: DB_USER
          value: prod_username
        - name: DB_PASSWORD
          value: prod_password
        - name: GPU_ENABLED
          value: "1"
        - name: UI_THEME
          value: dark
        - name: CACHE_SIZE
          value: 1024kb
        - name: PAGE_LIMIT
          value: "25"
        - name: SORTING
          value: Ascending
        - name: N_BUCKETS
          value: "42"
        image: docker.io/kostiscodefresh/simple-env-app:1.0
        imagePullPolicy: Always
        name: webserver-simple
        ports:
        - containerPort: 8080
```

```txt
deploy
├── environments
│   ├── integration-gpu
│   │   └── components
│   │       └── my-chart
│   │           └── my-chart.gen.yaml
│   ├── integration-non-gpu
│   │   └── components
│   │       └── my-chart
│   │           └── my-chart.gen.yaml
│   ├── prod-eu
│   │   └── components
│   │       └── my-chart
│   │           └── my-chart.gen.yaml
│   ├── prod-us
│   │   └── components
│   │       └── my-chart
│   │           └── my-chart.gen.yaml
│   ├── qa
│   │   └── components
│   │       └── my-chart
│   │           └── my-chart.gen.yaml
│   ├── staging-eu
│   │   └── components
│   │       └── my-chart
│   │           └── my-chart.gen.yaml
│   └── staging-us
│       └── components
│           └── my-chart
│               └── my-chart.gen.yaml
└── gitops
    ├── integration-gpu-my-chart-application.gen.yaml
    ├── integration-non-gpu-my-chart-application.gen.yaml
    ├── prod-eu-my-chart-application.gen.yaml
    ├── prod-us-my-chart-application.gen.yaml
    ├── qa-my-chart-application.gen.yaml
    ├── staging-eu-my-chart-application.gen.yaml
    └── staging-us-my-chart-application.gen.yaml

26 directories, 16 files
```

## Flattening the Hierarchy

Flattening the hierarchy disables `my-chart` and switches to `my-app` using CUE
build tags.  Execute the following process.

Generate the deployment configs and the 11 layer helm value files hierarchy.

    go run ./generator

Step 1 - Render the manifests using the helm hierarchy.

    holos render platform --selector customer=customer-emchwmlo -t flatten -t step1

Step 2 - Flatten the hierarchy into values.yaml files organized along the same
two dimensions as the deployment config.json files.

    holos render platform --selector customer=customer-emchwmlo -t flatten -t step2

Step 3 - Render the manifests using the flattened values.  Observe no changes
are made to the deploy directory.

    holos render platform --selector customer=customer-emchwmlo -t flatten -t step3

Rendering all 4000 build plans takes a few minutes and creates thousands of
files.  The generator is deterministic, so we've left most of these files out of
the commit history. The rendered artifacts for customer-emchwmlo are included as
an example to browse.

[rendered manifest pattern]: https://holos.run/blog/the-rendered-manifests-pattern
[v0.1.0]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/
[v0.2.0]: https://github.com/holos-run/multi-sources-example/blob/v0.2.0/
[all-my-envs-appset-with-version.yaml]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml
[ApplicationSet]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml
[Platform]: https://holos.run/docs/v1alpha5/api/core/#Platform
[ArgoCD Application]: https://holos.run/docs/v1alpha5/topics/gitops/argocd-application/
[holos-action]: https://github.com/holos-run/holos-action
