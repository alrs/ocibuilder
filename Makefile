PACKAGE=github.com/ocibuilder/ocibuilder/provenance
CURRENT_DIR=$(shell pwd)
DIST_DIR=${CURRENT_DIR}/dist

VERSION                = $(shell cat ${CURRENT_DIR}/VERSION)
BUILD_DATE             = $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
GIT_COMMIT             = $(shell git rev-parse HEAD)

override LDFLAGS += \
  -X ${PACKAGE}.version=${VERSION} \
  -X ${PACKAGE}.buildDate=${BUILD_DATE} \
  -X ${PACKAGE}.gitCommit=${GIT_COMMIT} \

.PHONY: clean test ocictl

ocibuilder:
	go build -o ${DIST_DIR}/ocibuilder -v .

ocibuilder-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 make ocibuilder

ocictl:
	packr build -v -ldflags '${LDFLAGS}' -o ${DIST_DIR}/ocictl ${CURRENT_DIR}/ocictl/main.go

ocictl-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 make ocictl

ocictl-mac:
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 make ocictl

ocictl-package-build:
	make ocictl-linux
	tar -czvf dist/ocictl-linux-${VERSION}.tar.gz ./dist/ocictl
	rm ${CURRENT_DIR}/dist/ocictl
	make ocictl-mac
	tar -czvf dist/ocictl-mac-${VERSION}.tar.gz ./dist/ocictl
	rm ${CURRENT_DIR}/dist/ocictl

test:
	go test $(shell go list ./... | grep -v /vendor/ | grep -v /testing/) -race -short -v -coverprofile=coverage.text

lint:
	golangci-lint run

e2e:
	go test testing/e2e

clean:
	-rm -rf ${CURRENT_DIR}/dist

dep:
	dep ensure -v

openapigen:
	hack/update-openapigen.sh

codegen:
	hack/update-codegen.sh
	hack/verify-codegen.sh
