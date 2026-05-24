.PHONY: run build test clean db-setup db-reset

# Build the server
build:
	go build -o bin/server ./cmd/server

# Run the server
run:
	go run ./cmd/server

# Run tests
test:
	go test ./... -v

# Setup database
db-setup:
	@bash scripts/setup_db.sh

# Reset database (drop and recreate)
db-reset:
	@psql -U newswang -d postgres -c "DROP DATABASE IF EXISTS family_health;"
	@bash scripts/setup_db.sh

# Clean build artifacts
clean:
	rm -rf bin/

# Format code
fmt:
	go fmt ./...

# Vet code
vet:
	go vet ./...

# Tidy dependencies
tidy:
	go mod tidy
