@extern(embed)
package environments

// We use cue embed functionality as an equivalent replacement for
// ApplicationSet generators.
config: _ @embed(glob=*/config.json)
config: _ @embed(glob=staging/*/config.json)
config: _ @embed(glob=prod/*/config.json)
config: _ @embed(glob=integration/*/config.json)

// With CUE we can constrain the data with a schema.
config: [FILEPATH=string]: #Config

// #Config defines the schema of each config.json file.
#Config: {
	env:     "qa" | "integration-gpu" | "integration-non-gpu" | "staging-us" | "staging-eu" | "prod-us" | "prod-eu"
	region:  "us" | "eu"
	type:    "prod" | "non-prod"
	version: "qa" | "staging" | "prod"
	chart:   =~"^[0-9]+\\.[0-9]+\\.[0-9]+$"
}

// Inspect the config struct using:
//
//  CUE_EXPERIMENT=embed holos cue export ./config/environments --out=yaml -e config
//
// For example:
//
//  qa/config.json:
//    env: qa
//    region: us
//    type: non-prod
//    version: qa
//    chart: 0.2.0
//  staging/asia/config.json:
//    env: qa
//    region: us
//    type: non-prod
//    version: qa
//    chart: 0.2.0
//  integration/gpu/config.json:
//    env: integration-gpu
//    region: us
//    type: non-prod
//    version: prod
//    chart: 0.1.0
//  prod/us/config.json:
//    env: prod-us
//    region: us
//    type: prod
//    version: prod
//    chart: 0.1.0
