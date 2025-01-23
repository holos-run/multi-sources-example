@extern(embed)
package holos

import (
	"encoding/json"

	"github.com/holos-run/holos/api/core/v1alpha5:core"

	"holos.example/schema/my-app/deployment"
	myApp "holos.example/components/my-app:holos"
)

parameters: {
	config: _ @tag(config)
}
config: deployment.#Config & json.Unmarshal(parameters.config)

// component represents the holos component definition, which produces a
// BuildPlan for holos to execute, rendering the manifests.
component: #MyHelm & {
	Chart: {
		version: "0.1.0"
		repository: {
			name: "render-values"
			url:  "https://chart.holos.example/render-values"
		}
	}

	ValueFiles: [
		{
			name:   "common-values.yaml"
			values: valueFiles["values/11-common/common-values.yaml"]
		},
		{
			name:   "location-values.yaml"
			values: valueFiles["values/10-locations/\(config.location)-values.yaml"]
		},
		{
			name:   "region-values.yaml"
			values: valueFiles["values/09-regions/\(config.region)-values.yaml"]
		},
		{
			name:   "zone-values.yaml"
			values: valueFiles["values/08-zones/\(config.zone)-values.yaml"]
		},
		{
			name:   "scope-values.yaml"
			values: valueFiles["values/07-scopes/\(config.scope)-values.yaml"]
		},
		{
			name:   "tier-values.yaml"
			values: valueFiles["values/06-tiers/\(config.tier)-values.yaml"]
		},
		{
			name:   "env-values.yaml"
			values: valueFiles["values/05-environments/\(config.env)-values.yaml"]
		},
		{
			name:   "cluster-values.yaml"
			values: valueFiles["values/04-clusters/\(config.cluster)-values.yaml"]
		},
		{
			name:   "application-values.yaml"
			values: valueFiles["values/03-applications/\(config.application)-values.yaml"]
		},
		{
			name:   "namespace-values.yaml"
			values: valueFiles["values/02-namespaces/\(config.namespace)-values.yaml"]
		},
		{
			name:   "customer-values.yaml"
			values: valueFiles["values/01-customers/\(config.customer)-values.yaml"]
		},
	]
}

valueFiles: myApp.valueFiles

// holos represents the output for the holos command line to process.  The holos
// command line processes a BuildPlan to render the helm chart component.
//
// Use the holos show buildplans command to see the BuildPlans that holos render
// platform renders.
holos: component.BuildPlan

// #MyHelm is a fork of the author.#Helm definition to remove the kustomize
// transformer.
#MyHelm: {
	#MyComponentConfig

	Name: _

	// Chart represents a Helm chart.
	Chart: core.#Chart
	Chart: {
		name:    string | *Name
		release: string | *name
	}

	// Values represents data to marshal into a values.yaml for helm.
	Values: core.#Values

	// ValueFiles represents value files for migration from helm value
	// hierarchies.  Use Values instead.
	ValueFiles?: [...core.#ValueFile] @go(,[]core.ValueFile)

	// EnableHooks enables helm hooks when executing the `helm template` command.
	EnableHooks: bool & (true | *false)

	// Namespace sets the helm chart namespace flag if provided.
	Namespace?: string

	// APIVersions represents the helm template --api-versions flag
	APIVersions?: [...string] @go(,[]string)

	// KubeVersion represents the helm template --kube-version flag
	KubeVersion?: string

	// BuildPlan represents the derived BuildPlan produced for the holos render
	// component command.
	BuildPlan: core.#BuildPlan

	Artifacts: {
		HolosComponent: {
			artifact: _
			let HelmOutput = artifact
			generators: [
				{
					kind:   "Helm"
					output: HelmOutput
					helm: core.#Helm & {
						chart:  Chart
						values: Values
						if ValueFiles != _|_ {
							valueFiles: ValueFiles
						}
						enableHooks: EnableHooks
						if Namespace != _|_ {
							namespace: Namespace
						}
						if APIVersions != _|_ {
							apiVersions: APIVersions
						}
						if KubeVersion != _|_ {
							kubeVersion: KubeVersion
						}
					}
				},
			]
		}
	}
}

#MyComponentConfig: {
	// Name represents the BuildPlan metadata.name field.  Used to construct the
	// fully rendered manifest file path.
	Name:      _Tags.component.name
	Path:      _Tags.component.path
	Resources: #Resources

	// Labels represent the BuildPlan metadata.labels field.
	Labels: {[string]: string} @go(,map[string]string)

	// Annotations represent the BuildPlan metadata.annotations field.
	Annotations: {[string]: string} @go(,map[string]string)

	// Parameters are useful to reuse a component with various parameters.
	// Injected as CUE @tag variables.  Parameters with a "holos_" prefix are
	// reserved for use by the Holos Authors.
	Parameters: {[string]: string} @go(,map[string]string)

	// OutputBaseDir represents the output base directory used when assembling
	// artifacts.  Useful to organize components by clusters or other parameters.
	// For example, holos writes resource manifests to
	// {WriteTo}/{OutputBaseDir}/components/{Name}/{Name}.gen.yaml
	OutputBaseDir: string | *"" @tag(outputBaseDir, type=string)

	// Validators represent checks that must pass for output to be written.
	Validators: {[string]: core.#Validator} @go(,map[NameLabel]core.Validator)

	// Artifacts represents additional artifacts to mix in.  Useful for adding
	// GitOps resources.  Each Artifact is unified without modification into the
	// BuildPlan.
	Artifacts: {[string]: core.#Artifact} @go(,map[NameLabel]core.Artifact)

	Artifacts: HolosComponent: {
		// Write the normalized value files as a reflection of the deployment
		// config.json files.  The key idea here is the dimensionality of the
		// deployment configs (customer, cluster) should be the same as the
		// dimensionality of the flattened values file.  This way we're guaranteed
		// to preserve all information without introducing any unnecessary override
		// layers.
		artifact: "values/customers/\(config.customer)/clusters/\(config.cluster)/values.yaml"
	}

	BuildPlan: {
		metadata: name: Name
		if len(Labels) != 0 {
			metadata: labels: Labels
		}
		if len(Annotations) != 0 {
			metadata: annotations: Annotations
		}
		spec: artifacts: [for x in Artifacts {x}]
	}
}
