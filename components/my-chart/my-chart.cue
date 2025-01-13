@extern(embed)
package holos

import "holos.example/config/environments"

parameters: {
	environments.#Config & {
		env:     _ @tag(env)
		region:  _ @tag(region)
		type:    _ @tag(type)
		version: _ @tag(version)
		chart:   _ @tag(chart)
	}
}

// component represents the holos component definition, which produces a
// BuildPlan for holos to execute, rendering the manifests.
component: #Helm & {
	Chart: {
		// Migrated from https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml#L25
		version: parameters.chart
		repository: {
			name: "multi-sources-example"
			// Migrated from https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml#L23
			url: "https://kostis-codefresh.github.io/multi-sources-example"
		}
	}

	// Migrated from https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml#L40
	// We use kustomize to manage the namespace, similar to how the original
	// article uses the ApplicationSet template to specify the namespace.
	KustomizeConfig: Kustomization: namespace: parameters.env

	// Unified values.  Migrated from [valueFiles].  Conflicting values are errors.
	//
	// [valueFiles]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml#L27-L32
	Values: {
		valueFiles["my-values/app-version/\(parameters.version)-values.yaml"]
		valueFiles["my-values/env-type/\(parameters.type)-values.yaml"]
		valueFiles["my-values/regions/\(parameters.region)-values.yaml"]
		valueFiles["my-values/envs/\(parameters.env)-values.yaml"]
	}
}

// holos represents the output for the holos command line to process.  The holos
// command line processes a BuildPlan to render the helm chart component.
//
// Use the holos show buildplans command to see the BuildPlans that holos render
// platform renders.
holos: component.BuildPlan

// Migrated from https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml#L27-L32
valueFiles: _ @embed(glob=my-values/*/*.yaml)
