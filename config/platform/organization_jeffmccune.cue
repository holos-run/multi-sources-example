@if(jeff || jeffmccune)
package platform

// The @if(jeff) build tag allows us to easily reconfigure the GitOps URL from
// one well known place.  For example, set a build tag for your user name to
// activate this file which replaces the default value of the
// platform.organization.repoURL field.
//
//  holos render platform -t $USER
organization: repoURL: "https://github.com/jeffmccune/multi-sources-example.git"
