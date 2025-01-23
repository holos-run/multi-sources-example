@if(!NoArgoCD)
package holos

import (
	"path"
	app "argoproj.io/application/v1alpha1"

	"holos.example/config/platform"
)

parameters: {
	env: string @tag(env)
}

// #ComponentConfig composes configuration into every Holos Component.  Here we
// compose an ArgoCD Application resource along side each component to reconcile
// the hydrated manifests with the cluster.
#ComponentConfig: {
	Name:          _
	OutputBaseDir: _
	// Application resources are Environment scoped.  Note the combination of
	// component name and environment must be unique.
	_ArgoAppName: string | *"\(parameters.env)-\(Name)"

	// Allow other aspects of the platform configuration to refer to
	// `Component._ArgoApplication` to get a handle on the Application resource
	// and mix additional configuration in.
	_ArgoApplication: app.#Application & {
		metadata: name:      _ArgoAppName
		metadata: namespace: "argocd"
		metadata: labels:    Labels
		// Label the Application with the env so we can easily filter in the UI.
		metadata: labels: env: parameters.env
		spec: {
			destination: server: "https://kubernetes.default.svc"
			project: "default"
			source: {
				path:           string | *ResourcesPath
				repoURL:        platform.organization.repoURL
				targetRevision: string | *"main"
			}
		}
	}

	// We combine all Application resources into the deploy/gitops/ folder
	// assuming Application.metadata.name is unique.  This makes it easy to apply
	// all of the hydrated Application resources in one shot.
	let ArtifactPath = path.Join(["gitops", "\(_ArgoApplication.metadata.name)-application.gen.yaml"], path.Unix)
	// Alternatively we could write the Applications along side the OutputBaseDir
	// let ArtifactPath = path.Join([OutputBaseDir, "gitops", "\(Name)-application.gen.yaml"], path.Unix)

	// ResourcesPath represents the configuration path the Application is
	// configured to read as a source.  This path contains the fully rendered
	// manifests produced by Holos and written to the GitOps repo.
	//
	// For example, to reconcile my-chart.gen.yaml for prod-us:
	//  let ResourcesPath = "deploy/environments/prod-us/components/my-chart"
	let ResourcesPath = path.Join(["deploy", OutputBaseDir, "components", Name], path.Unix)

	// Add the argocd Application instance label to GitOps so resources are in sync.
	// This is an example of how Holos makes it easy to add common labels to all
	// resources regardless of if they come from Helm, CUE, Kustomize, plain YAML
	// manifests, etc...
	KustomizeConfig: CommonLabels: "argocd.argoproj.io/instance": _ArgoAppName

	// Labels for the Application itself.  We filter the argocd application
	// instance label so ArgoCD doesn't think the Application resource manages
	// itself.
	let Labels = {
		for k, v in KustomizeConfig.CommonLabels {
			if k != "argocd.argoproj.io/instance" {
				(k): v
			}
		}
	}

	_GitOpsArtifact: {
		artifact: string | *ArtifactPath
		generators: [{
			kind:   "Resources"
			output: artifact
			resources: Application: (_ArgoAppName): _ArgoApplication
		}]
	}

	Artifacts: "\(Name)-application": _GitOpsArtifact
}
