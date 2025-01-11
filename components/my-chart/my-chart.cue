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
		version: parameters.chart
		repository: {
			name: "multi-sources-example"
			url:  "https://kostis-codefresh.github.io/multi-sources-example"
		}
	}

	// Unify the values together.  Prior to the migration to holos, helm merged
	// the values together, writing over fields without error.  CUE is different,
	// it will error if the same field conflicts.  Migrated from [valueFiles].
	//
	// [valueFiles]: https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml#L27-L32
	Values: {
		// Define replicaCount as a required (!) unsigned 16 bit integer (uint16),
		// forcing the field to be defined in one of the valueFiles.
		replicaCount!: uint16

		// Note there is no precedence or hierarchy, all the values are unified
		// together into one structure.  Conflicts are errors by design.
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
valueFiles: _ @embed(glob=my-values/*/*-values.yaml)
