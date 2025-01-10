// Code generated by timoni. DO NOT EDIT.

//timoni:generate timoni vendor crd -f https://raw.githubusercontent.com/external-secrets/external-secrets/v0.10.5/deploy/crds/bundle.yaml

package v1alpha1

import "strings"

// ACRAccessToken returns a Azure Container Registry token
// that can be used for pushing/pulling images.
// Note: by default it will return an ACR Refresh Token with full
// access
// (depending on the identity).
// This can be scoped down to the repository level using
// .spec.scope.
// In case scope is defined it will return an ACR Access Token.
//
// See docs:
// https://github.com/Azure/acr/blob/main/docs/AAD-OAuth.md
#ACRAccessToken: {
	// APIVersion defines the versioned schema of this representation
	// of an object.
	// Servers should convert recognized schemas to the latest
	// internal value, and
	// may reject unrecognized values.
	// More info:
	// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources
	apiVersion: "generators.external-secrets.io/v1alpha1"

	// Kind is a string value representing the REST resource this
	// object represents.
	// Servers may infer this from the endpoint the client submits
	// requests to.
	// Cannot be updated.
	// In CamelCase.
	// More info:
	// https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds
	kind: "ACRAccessToken"
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

	// ACRAccessTokenSpec defines how to generate the access token
	// e.g. how to authenticate and which registry to use.
	// see:
	// https://github.com/Azure/acr/blob/main/docs/AAD-OAuth.md#overview
	spec!: #ACRAccessTokenSpec
}

// ACRAccessTokenSpec defines how to generate the access token
// e.g. how to authenticate and which registry to use.
// see:
// https://github.com/Azure/acr/blob/main/docs/AAD-OAuth.md#overview
#ACRAccessTokenSpec: {
	auth: {
		managedIdentity?: {
			// If multiple Managed Identity is assigned to the pod, you can
			// select the one to be used
			identityId?: string
		}
		servicePrincipal?: {
			// Configuration used to authenticate with Azure using static
			// credentials stored in a Kind=Secret.
			secretRef: {
				// The Azure clientId of the service principle used for
				// authentication.
				clientId?: {
					// The key of the entry in the Secret resource's `data` field to
					// be used. Some instances of this field may be
					// defaulted, in others it may be required.
					key?: string

					// The name of the Secret resource being referred to.
					name?: string

					// Namespace of the resource being referred to. Ignored if
					// referent is not cluster-scoped. cluster-scoped defaults
					// to the namespace of the referent.
					namespace?: string
				}

				// The Azure ClientSecret of the service principle used for
				// authentication.
				clientSecret?: {
					// The key of the entry in the Secret resource's `data` field to
					// be used. Some instances of this field may be
					// defaulted, in others it may be required.
					key?: string

					// The name of the Secret resource being referred to.
					name?: string

					// Namespace of the resource being referred to. Ignored if
					// referent is not cluster-scoped. cluster-scoped defaults
					// to the namespace of the referent.
					namespace?: string
				}
			}
		}
		workloadIdentity?: {
			// ServiceAccountRef specified the service account
			// that should be used when authenticating with WorkloadIdentity.
			serviceAccountRef?: {
				// Audience specifies the `aud` claim for the service account
				// token
				// If the service account uses a well-known annotation for e.g.
				// IRSA or GCP Workload Identity
				// then this audiences will be appended to the list
				audiences?: [...string]

				// The name of the ServiceAccount resource being referred to.
				name: string

				// Namespace of the resource being referred to. Ignored if
				// referent is not cluster-scoped. cluster-scoped defaults
				// to the namespace of the referent.
				namespace?: string
			}
		}
	}

	// EnvironmentType specifies the Azure cloud environment endpoints
	// to use for
	// connecting and authenticating with Azure. By default it points
	// to the public cloud AAD endpoint.
	// The following endpoints are available, also see here:
	// https://github.com/Azure/go-autorest/blob/main/autorest/azure/environments.go#L152
	// PublicCloud, USGovernmentCloud, ChinaCloud, GermanCloud
	environmentType?: "PublicCloud" | "USGovernmentCloud" | "ChinaCloud" | "GermanCloud" | *"PublicCloud"

	// the domain name of the ACR registry
	// e.g. foobarexample.azurecr.io
	registry: string

	// Define the scope for the access token, e.g. pull/push access
	// for a repository.
	// if not provided it will return a refresh token that has full
	// scope.
	// Note: you need to pin it down to the repository level, there is
	// no wildcard available.
	//
	// examples:
	// repository:my-repository:pull,push
	// repository:my-repository:pull
	//
	// see docs for details:
	// https://docs.docker.com/registry/spec/auth/scope/
	scope?: string

	// TenantID configures the Azure Tenant to send requests to.
	// Required for ServicePrincipal auth type.
	tenantId?: string
}
