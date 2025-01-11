package holos

import "holos.example/config/environments"

// Produce a kubernetes objects build plan.
holos: Component.BuildPlan

// Migrated from https://github.com/holos-run/multi-sources-example/blob/v0.1.0/appsets/4-final/all-my-envs-appset-with-version.yaml#L45
Component: #Kubernetes & {
	// For each of the config/environments/**/config.json files ...
	for CONFIG in environments.config {
		// Manage a Kubernetes namespace using CUE directly.
		Resources: Namespace: (CONFIG.env): {
			// With holos and cue we can go one step further and set a label for each
			// config value.
			metadata: labels: CONFIG
		}
	}
}
