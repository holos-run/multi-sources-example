package deployment

// #Config defines the schema of each deployment config marshalled to a
// config.json file.
#Config: {
	customer!:    string
	namespace!:   string
	application!: string
	cluster!:     string
	env!:         string
	tier!:        string
	scope!:       string
	zone!:        string
	region!:      string
	location!:    string
}
