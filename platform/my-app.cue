@if(flatten && step1 || step2 || step3)
package holos

import (
	"encoding/json"
	"holos.example/config/my-app/deployment"
)

// #MyChart defines a re-usable way to manage my-chart across qa, staging, and
// production.
#MyApp: {
	name:    string | *"my-app"
	path:    "components/\(name)"
	_config: _
	// CUE supports constraints, here we constrain environment to one of three
	// possible values.
	parameters: {
		config: json.Marshal(_config)
		env:    _config.env

		// The output is the reverse of the deployment config filesystem structure,
		// cluster then app instead of app then cluster, reflecting the perspective
		// of the platform team compared with the perspective of the app team.
		outputBaseDir: "clusters/\(_config.cluster)/customers/\(_config.customer)"
	}
	// The app.holos.run/description annotation configures holos render platform
	// log messages.
	annotations: "app.holos.run/description": string | *"\(name) for \(_config.customer) cluster \(_config.cluster)"
	// Selector labels, useful since we're working with so much data.  4000
	// deployments render in 4 minutes.
	labels: customer: _config.customer
	labels: cluster:  _config.cluster
	labels: app:      _config.application
}

for KEY, CONFIG in deployment.config {
	// Add one holos component for each config.json file to the
	// Platform.spec.components list.
	Platform: Components: (KEY): #MyApp & {
		_config: CONFIG
	}
}
