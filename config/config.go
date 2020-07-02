package config

type (
	Server struct {
		Port           string `yaml:"port"`
		Endpoint       string `yaml:"endpoint"`
		SecureEndpoint bool   `yaml:"secureEndpoint"`
		RosettaVersion string `yaml:"rosettaVersion"`
	}
)