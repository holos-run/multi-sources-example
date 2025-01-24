// Usage:
//
//	go run ./generator
//
// Writes deployment config.json files to
// config/my-app/deployment/customers/*/clusters/*/config./json
//
// Writes helm value files as an 11 layer hierarchy to components/my-app/values
// organized by their position in the override hierarchy.
//
// Used to generate data for the following command:
//
//	holos render platform -t flatten -t step1
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"math/rand/v2"
	"os"
	"path"
	"strconv"
	"strings"

	"gopkg.in/yaml.v3"
)

const numCustomers = 1000
const numClusters = 25
const numDeployments = 4000
const appName = "my-app"

func main() {
	if err := Main(os.Args); err != nil {
		log.Fatal(err)
	}
}

// NOT random!  Deterministic by default for the tests and documentation.  Set
// the RANDOMIZE environment variable to randomize the data.
func newDeterministicPCG() *rand.PCG {
	if len(os.Getenv("RANDOMIZE")) > 0 {
		return rand.NewPCG(rand.Uint64(), rand.Uint64())
	}
	seed1, err := strconv.ParseUint(os.Getenv("SEED1"), 10, 64)
	if err != nil {
		seed1 = 42
	}

	seed2, err := strconv.ParseUint(os.Getenv("SEED2"), 10, 64)
	if err != nil {
		seed2 = 42
	}

	return rand.NewPCG(seed1, seed2)
}

type Layer struct {
	Name string `yaml:"name"`
	// ValuesMap indexed by a key into the layer.  For example,
	ValuesMap map[string]Values `yaml:"valuesMap,omitempty"`
	rand      *rand.Rand
}

func NewLayer(name string, keys []string, chance float64, rand *rand.Rand) Layer {
	layer := Layer{
		Name:      name,
		ValuesMap: make(map[string]Values),
		rand:      rand,
	}
	for _, key := range keys {
		values := Values{rand: rand}
		values.Fill(chance, "")
		layer.ValuesMap[key] = values
	}
	return layer
}

func NewCustomerLayer(name string, customers []string, chance float64, rand *rand.Rand) Layer {
	layer := Layer{
		Name:      name,
		ValuesMap: make(map[string]Values),
		rand:      rand,
	}
	for _, customerID := range customers {
		values := Values{rand: rand}
		values.Fill(chance, customerID)
		layer.ValuesMap[customerID] = values
	}
	return layer
}

type Values struct {
	CustomerID *string           `yaml:"customerID,omitempty"`
	Enabled    *bool             `yaml:"enabled,omitempty"`
	Image      *string           `yaml:"image,omitempty"`
	Version    *string           `yaml:"version,omitempty"`
	Domain     *string           `yaml:"domain,omitempty"`
	Replicas   *int              `yaml:"replicas,omitempty"`
	ClientID   *string           `yaml:"clientID,omitempty"`
	Issuer     *string           `yaml:"issuer,omitempty"`
	ProjectID  *string           `yaml:"projectID,omitempty"`
	AccountID  *uint64           `yaml:"accountID,omitempty"`
	ARN        *string           `yaml:"arn,omitempty"`
	Cores      *float64          `yaml:"cores,omitempty"`
	Memory     *int              `yaml:"memory,omitempty"`
	Labels     map[string]string `yaml:"labels,omitempty"`
	rand       *rand.Rand
}

func (v *Values) Fill(chance float64, customerID string) {
	random := v.rand
	if customerID != "" {
		v.CustomerID = &customerID
	}
	if random.Float64() < chance {
		enabled := random.Float64() < 0.5
		v.Enabled = &enabled
	}
	if random.Float64() < chance {
		image := "oci://example.com/" + randomString(8, random)
		v.Image = &image
	}
	if random.Float64() < chance {
		version := fmt.Sprintf("v%d.%d.%d", random.IntN(100), random.IntN(100), random.IntN(100))
		v.Version = &version
	}
	if random.Float64() < chance {
		domain := fmt.Sprintf("%s.example", randomString(10, random))
		v.Domain = &domain
	}
	if random.Float64() < chance {
		replicas := random.IntN(16) + 1
		v.Replicas = &replicas
	}
	if random.Float64() < chance {
		clientID := fmt.Sprintf("https://%s.example", randomString(10, random))
		v.ClientID = &clientID
	}
	if random.Float64() < chance {
		issuer := fmt.Sprintf("https://%s.example", randomString(10, random))
		v.Issuer = &issuer
	}
	if random.Float64() < chance {
		projectID := fmt.Sprintf("my-project-%d", random.IntN(899999)+100000)
		v.ProjectID = &projectID
	}
	if random.Float64() < chance {
		accountID := 100_000_000_000 + random.Uint64N(900_000_000_000)
		v.AccountID = &accountID
	}
	if random.Float64() < chance {
		arn := fmt.Sprintf("arn:partition:service:region:account-id:%s", randomString(8, random))
		v.ARN = &arn
	}
	if random.Float64() < chance {
		cores := math.Round(0.1+random.Float64()*(256-0.1)*10) / 10
		v.Cores = &cores
	}
	if random.Float64() < chance {
		memory := random.IntN(16384)
		v.Memory = &memory
	}
	if random.Float64() < chance {
		size := random.IntN(9) + 1
		v.Labels = make(map[string]string, size)
		for i := 0; i < size; i++ {
			v.Labels[fmt.Sprintf("label%d", random.IntN(10)+1)] = randomString(12, random)
		}
	}
}

func Main(args []string) error {
	random := rand.New(newDeterministicPCG())
	apps := make([]string, 0, 500)
	for i := 0; i < 500; i++ {
		apps = append(apps, fmt.Sprintf("myapp%d", i))
	}
	envs := []string{"dev", "test", "uat", "prod"}
	tiers := []string{"prod", "nonprod"}
	scopes := []string{"customer", "internal", "management"}
	locations := []string{"us", "eu", "ap"}
	regions := make([]string, 0, 8*len(locations))
	for _, location := range locations {
		for i := 1; i <= 4; i++ {
			regions = append(regions, fmt.Sprintf("%s-east%d", location, i))
			regions = append(regions, fmt.Sprintf("%s-west%d", location, i))
		}
	}
	suffixes := []string{"a", "b", "c", "d"}
	zones := make([]string, 0, len(regions)*3)
	for _, region := range regions {
		for _, suffix := range suffixes {
			zones = append(zones, fmt.Sprintf("%s-%s", region, suffix))
		}
	}
	common := []string{"common"}
	namespaces := make([]string, 0, len(apps)*len(envs))
	for _, app := range apps {
		for _, env := range envs {
			namespaces = append(namespaces, fmt.Sprintf("%s-%s", env, app))
		}
	}
	clusters := make([]string, 0, numClusters*len(envs)*len(scopes))
	for i := 1; i <= numClusters; i++ {
		for _, scope := range scopes {
			for _, env := range envs {
				clusters = append(clusters, fmt.Sprintf("%s%d-%s", env, i, scope))
			}
		}
	}
	customers := make([]string, 0, numCustomers)
	for i := 0; i < numCustomers; i++ {
		customers = append(customers, fmt.Sprintf("customer-%s", randomString(8, random)))
	}

	// Now that we have values for each of the layers, generate random data.
	layers := []Layer{
		// Always Set the customer ID at the customer layer.
		NewCustomerLayer("customers", customers, 0.15, random),
		// The rest are randomized.
		NewLayer("namespaces", namespaces, 0.15, random),
		NewLayer("applications", apps, 0.30, random),
		NewLayer("clusters", clusters, 0.20, random),
		NewLayer("environments", envs, 0.40, random),
		NewLayer("tiers", tiers, 0.50, random),
		NewLayer("scopes", scopes, 0.30, random),
		NewLayer("zones", zones, 0.10, random),
		NewLayer("regions", regions, 0.30, random),
		NewLayer("locations", locations, 0.30, random),
		NewLayer("common", common, 1.00, random),
	}

	for idx, layer := range layers {
		dir := path.Join("components", appName, "values", fmt.Sprintf("%02d-%s", idx+1, layer.Name))
		if err := os.MkdirAll(dir, 0777); err != nil {
			return err
		}
		for key, values := range layer.ValuesMap {
			file := path.Join(dir, fmt.Sprintf("%s-values.yaml", key))
			data, err := yaml.Marshal(values)
			if err != nil {
				return err
			}
			err = os.WriteFile(file, data, 0666)
			if err != nil {
				return fmt.Errorf("could not write values: %w", err)
			}
		}
	}

	// Now make the deployment configs that determine the hierarchy.
	deployments := make(map[string]Deployment, numDeployments)

	for len(deployments) < numDeployments {
		// Pick a customer
		customer := customers[random.IntN(len(customers))]
		// Pick an application
		application := apps[random.IntN(len(apps))]
		// Pick a scope
		scope := scopes[random.IntN(len(scopes))]

		// Deploy it to all envs
		for _, env := range envs {
			if len(deployments) == numDeployments {
				break
			}
			namespace := fmt.Sprintf("%s-%s", env, application)
			cluster := fmt.Sprintf("%s%d-%s", env, random.IntN(numClusters)+1, scope)
			tier := "nonprod"
			if env == "prod" {
				tier = "prod"
			}

			// Pick a zone, region, location
			zone := zones[random.IntN(len(zones))]
			parts := strings.Split(zone, "-")
			location := parts[0]
			region := fmt.Sprintf("%s-%s", parts[0], parts[1])

			deployment := Deployment{
				Customer:    customer,
				Namespace:   namespace,
				Application: application,
				Cluster:     cluster,
				Env:         env,
				Tier:        tier,
				Scope:       scope,
				Zone:        zone,
				Region:      region,
				Location:    location,
			}
			deployments[deployment.Path()] = deployment
		}
	}

	for file, config := range deployments {
		if err := os.MkdirAll(path.Dir(file), 0777); err != nil {
			return err
		}
		data, err := json.MarshalIndent(config, "", "  ")
		if err != nil {
			return err
		}
		data = append(data, '\n')
		err = os.WriteFile(file, data, 0666)
		if err != nil {
			return fmt.Errorf("could not write config: %w", err)
		}
	}

	return nil
}

type Deployment struct {
	Customer    string `json:"customer"`
	Namespace   string `json:"namespace"`
	Application string `json:"application"`
	Cluster     string `json:"cluster"`
	Env         string `json:"env"`
	Tier        string `json:"tier"`
	Scope       string `json:"scope"`
	Zone        string `json:"zone"`
	Region      string `json:"region"`
	Location    string `json:"location"`
}

func (d Deployment) Path() string {
	return path.Join("config", appName, "deployment", "customers", d.Customer, "clusters", d.Cluster, "config.json")
}

func randomString(n int, rand *rand.Rand) string {
	const letters = "abcdefghijklmnopqrstuvwxyz"
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[rand.IntN(len(letters))]
	}
	return string(b)
}
