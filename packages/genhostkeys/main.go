package main

import (
	"bytes"
	"crypto/ed25519"
	"crypto/rand"
	"crypto/rsa"
	"encoding/pem"
	"flag"
	"log"
	"os"

	"golang.org/x/crypto/ssh"
	"gopkg.in/yaml.v3"
)

func main() {
	hostname := flag.String("hostname", "ojama", "hostname")
	comment := flag.String("comment", "", "private key comment")
	flag.Parse()

	ed25519PublicKey, ed25519PrivateKey, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		log.Fatalf("Error generating Ed25519 hostkey: %v", err)
	}
	ed25519PrivateKeyPem, err := ssh.MarshalPrivateKey(ed25519PrivateKey, *comment)
	if err != nil {
		log.Fatalf("Error marshalling private Ed25519 hostkey: %v", err)
	}
	ed25519PrivateKeyBuffer := bytes.Buffer{}
	if err := pem.Encode(&ed25519PrivateKeyBuffer, ed25519PrivateKeyPem); err != nil {
		log.Fatalf("Error encoding private Ed25519 hostkey to PEM: %v", err)
	}
	sshEd25519PublicKey, err := ssh.NewPublicKey(ed25519PublicKey)
	if err != nil {
		log.Fatalf("Error deriving public SSH Ed25519 hostkey: %v", err)
	}

	rsaPrivateKey, err := rsa.GenerateKey(rand.Reader, 3072)
	if err != nil {
		log.Fatalf("Error generating RSA hostkey: %v", err)
	}
	err = rsaPrivateKey.Validate()
	if err != nil {
		log.Fatalf("Error validating RSA hostkey: %v", err)
	}
	sshRSAPublicKey, err := ssh.NewPublicKey(&rsaPrivateKey.PublicKey)
	if err != nil {
		log.Fatalf("Error deriving public SSH RSA hostkey: %v", err)
	}
	rsaPrivateKeyPem, err := ssh.MarshalPrivateKey(rsaPrivateKey, *comment)
	if err != nil {
		log.Fatalf("Error marshalling private RSA hostkey: %v", err)
	}
	rsaPrivateKeyBuffer := bytes.Buffer{}
	if err := pem.Encode(&rsaPrivateKeyBuffer, rsaPrivateKeyPem); err != nil {
		log.Fatalf("Error encoding private RSA hostkey to PEM: %v", err)
	}

	ed25519PrivateKeyText := ed25519PrivateKeyBuffer.String()
	ed25519PublicKeyText := string(ssh.MarshalAuthorizedKey(sshEd25519PublicKey))
	rsaPrivateKeyText := rsaPrivateKeyBuffer.String()
	rsaPublicKeyText := string(ssh.MarshalAuthorizedKey(sshRSAPublicKey))

	yaml.NewEncoder(os.Stdout).Encode(map[any]any{
		*hostname: map[any]any{
			"ssh_host_ed25519_key":     ed25519PrivateKeyText,
			"ssh_host_ed25519_key.pub": ed25519PublicKeyText,
			"ssh_host_rsa_key":         rsaPrivateKeyText,
			"ssh_host_rsa_key.pub":     rsaPublicKeyText,
		},
	})
}
