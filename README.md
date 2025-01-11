# Migrate from Helm Hierarchy AppSets to Holos

This repository is a direct migration of the final [Helm Hierarchies - Saving
environment configurations on their own
files](https://medium.com/containers-101/using-helm-hierarchies-in-multi-source-argo-cd-applications-for-promoting-to-different-gitops-133c3bc93678)
recommended example to Holos.

## Why?

1. ApplicationSets add a layer of obfuscation through yaml templates rendered remotely by ArgoCD.
2. Helm Hierarchies add multiple layers of obfuscation by merging values.
3. The Helm chart itself is a layer of obfuscated yaml rendered by ArgoCD.

All of this adds up to a large amount of unnecessary complexity.  It difficult
to comprehend changes because it's difficult to see how the system is actually
configured.

For example, consider the `ApplicationSet` generating a handful of `Application`
resources each passing values into the `my-chart` Helm chart.

<details><summary>The ApplicationSet is one layer of obfuscation. 👈 Click me</summary>

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

<details><summary>The config.json files are a second layer of obfuscation. 👈 Click me</summary>

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

<details><summary>The helm chart is a third layer of obfuscation. 👈 Click me</summary>

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
rendered namespaces for all environments in 153.780333ms
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
├── all-namespaces-application.gen.yaml
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

Holos implements the [rendered manifest pattern].  The migration is a two step
process.  We start at the [v0.1.0] tag, which is the unmodified upstream source
and end with the [v0.2.0] tag which has been migrated to holos.

 1. Migrate [all-my-envs-appset-with-version.yaml] to [Platform].spec.components
 2. Mix in an Application resource to each component using the
    `#ComponentConfig` described at [ArgoCD Application].
 3. Use the [holos-action] to render manifests when pull requests are opened.

Take a look at each step in the migration by following the commits in this repo.
We plan to publish a description of the migration from ApplicationSets and
hierarchical helm values as a blog post or docs topic at https://holos.run/

> [!NOTE]
> See the migration steps from [v0.1.0 to v0.2.0](https://github.com/holos-run/multi-sources-example/compare/v0.1.0...holos-run:multi-sources-example:v0.2.0?expand=1).

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
├── components
│   └── namespaces
│       └── namespaces.gen.yaml
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
    ├── all-namespaces-application.gen.yaml
    ├── integration-gpu-my-chart-application.gen.yaml
    ├── integration-non-gpu-my-chart-application.gen.yaml
    ├── prod-eu-my-chart-application.gen.yaml
    ├── prod-us-my-chart-application.gen.yaml
    ├── qa-my-chart-application.gen.yaml
    ├── staging-eu-my-chart-application.gen.yaml
    └── staging-us-my-chart-application.gen.yaml

26 directories, 16 files
```

[rendered manifest pattern]: https://holos.run/blog/the-rendered-manifests-pattern
[v0.1.0]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/
[v0.2.0]: https://github.com/holos-run/multi-sources-example/blob/v0.2.0/
[all-my-envs-appset-with-version.yaml]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml
[ApplicationSet]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml
[Platform]: https://holos.run/docs/v1alpha5/api/core/#Platform
[ArgoCD Application]: https://holos.run/docs/v1alpha5/topics/gitops/argocd-application/
[holos-action]: https://github.com/holos-run/holos-action
