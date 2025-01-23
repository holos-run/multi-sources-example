@extern(embed)
package deployment

import "holos.example/schema/my-app/deployment"

// With CUE we can constrain the data with a schema.
config: [FILEPATH=string]: deployment.#Config

// Load the deployment configs, these are high level attributes (i.e. facts)
// used to determine the specific paths for the value files.
config: _ @embed(glob=customers/*/clusters/*/config.json)
