# Migrate from Helm Hierarchy AppSets to Holos

This repository is a direct migration of the final [Helm Hierarchies - Saving
environment configurations on their own
files](Helm%20Hierarchies%20-%20Saving%20environment%20configurations%20on%20their%20own%20files.md)
recommended example to Holos.

## Why?

1. ApplicationSets add a layer of obfuscation through yaml templates rendered remotely by ArgoCD.
2. Helm Hierarchies add multiple layers of obfuscation by merging values.
3. The Helm chart itself is a layer of obfuscated yaml rendered by ArgoCD.

All of this adds up to a large amount of unnecessary complexity.  It becomes
impossible to reason about changes because it's impossible to hold the
configuration in our mind.

## What's the alternative?

We can use `holos render` to fully hydrate the manifests so we can look directly
at them.

## How?

Holos implements the [rendered manifest pattern].  The migration is a two step
process.  We start at the [v0.1.0] tag, which is the unmodified upstream source
and end with the [v0.2.0] tag which has been migrated to holos.

 1. Migrate [all-my-envs-appset-with-version.yaml] to [Platform].spec.components
 2. Mix in an Application resource to each component using the
    `#ComponentConfig` described at [ArgoCD Application].
 3. Use the [holos-action] to render manifests when pull requests are opened.

## Result

 1. We have fully rendered Application resources which are clearly legible.
 2. Each Application reconciles fully rendered manifests which are also clearly legible.
 3. The configuration is _unified_ with CUE.  We can easily mix in additional
    resources like Kargo Stages for Progressive Delivery, which is the subject
    of the next article in the series.

[rendered manifest pattern]: https://holos.run/blog/the-rendered-manifests-pattern
[v0.1.0]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/
[v0.2.0]: https://github.com/holos-run/multi-sources-example/blob/v0.2.0/
[all-my-envs-appset-with-version.yaml]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml
[Platform]: https://holos.run/docs/v1alpha5/api/core/#Platform
[ArgoCD Application]: https://holos.run/docs/v1alpha5/topics/gitops/argocd-application/
[holos-action]: https://github.com/holos-run/holos-action
