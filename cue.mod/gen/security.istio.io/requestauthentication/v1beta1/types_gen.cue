// Code generated by timoni. DO NOT EDIT.

//timoni:generate timoni vendor crd -f deploy/clusters/aws2/components/istio-base/istio-base.gen.yaml

package v1beta1

import "strings"

#RequestAuthentication: {
	// Request authentication configuration for workloads. See more
	// details at:
	// https://istio.io/docs/reference/config/security/request_authentication.html
	spec!:      #RequestAuthenticationSpec
	apiVersion: "security.istio.io/v1beta1"
	kind:       "RequestAuthentication"
	metadata!: {
		name!: strings.MaxRunes(253) & strings.MinRunes(1) & {
			string
		}
		namespace!: strings.MaxRunes(63) & strings.MinRunes(1) & {
			string
		}
		labels?: {
			[string]: string
		}
		annotations?: {
			[string]: string
		}
	}
}

// Request authentication configuration for workloads. See more
// details at:
// https://istio.io/docs/reference/config/security/request_authentication.html
#RequestAuthenticationSpec: {
	// Define the list of JWTs that can be validated at the selected
	// workloads' proxy.
	jwtRules?: [...{
		// The list of JWT
		// [audiences](https://tools.ietf.org/html/rfc7519#section-4.1.3)
		// that are allowed to access.
		audiences?: [...string]

		// If set to true, the original token will be kept for the
		// upstream request.
		forwardOriginalToken?: bool

		// List of cookie names from which JWT is expected.
		fromCookies?: [...string]

		// List of header locations from which JWT is expected.
		fromHeaders?: [...{
			// The HTTP header name.
			name: string

			// The prefix that should be stripped before decoding the token.
			prefix?: string
		}]

		// List of query parameters from which JWT is expected.
		fromParams?: [...string]

		// Identifies the issuer that issued the JWT.
		issuer: string

		// JSON Web Key Set of public keys to validate signature of the
		// JWT.
		jwks?: string

		// URL of the provider's public key set to validate signature of
		// the JWT.
		jwks_uri?: string

		// URL of the provider's public key set to validate signature of
		// the JWT.
		jwksUri?: string

		// This field specifies a list of operations to copy the claim to
		// HTTP headers on a successfully verified token.
		outputClaimToHeaders?: [...{
			// The name of the claim to be copied from.
			claim?: string

			// The name of the header to be created.
			header?: string
		}]

		// This field specifies the header name to output a successfully
		// verified JWT payload to the backend.
		outputPayloadToHeader?: string

		// The maximum amount of time that the resolver, determined by the
		// PILOT_JWT_ENABLE_REMOTE_JWKS environment variable, will spend
		// waiting for the JWKS to be fetched.
		timeout?: string
	}]
	selector?: {
		// One or more labels that indicate a specific set of pods/VMs on
		// which a policy should be applied.
		matchLabels?: {
			[string]: string
		}
	}
	targetRef?: {
		// group is the group of the target resource.
		group?: string

		// kind is kind of the target resource.
		kind?: string

		// name is the name of the target resource.
		name?: string

		// namespace is the namespace of the referent.
		namespace?: string
	}

	// Optional.
	targetRefs?: [...{
		// group is the group of the target resource.
		group?: string

		// kind is kind of the target resource.
		kind?: string

		// name is the name of the target resource.
		name?: string

		// namespace is the namespace of the referent.
		namespace?: string
	}]
}
