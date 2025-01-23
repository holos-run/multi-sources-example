@if(flatten && step2)
package holos

#MyApp: {
	name:    "render-values"
	_config: _
	annotations: "app.holos.run/description": "flattened values for \(_config.customer) \(_config.cluster)"
}
