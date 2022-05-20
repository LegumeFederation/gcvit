 # GCViT
[![DOI](https://zenodo.org/badge/209399439.svg)](https://zenodo.org/badge/latestdoi/209399439)

![GCViT](assets/readme_images/logo.png?raw=true)

## Table of Contents
+ [About](#about) 
+ [Getting Started](#getting-started)
+ [Setup](#setup)
    + [Preparing data](#preparing-the-data)
    + [Configuring the API Service](#configuring-the-api-service)
    + [Configuring the UI](#configuring-the-ui-(optional))
    + [Running GCViT using Docker](#running-gcvit-using-docker)
+ [Running GCViT on a Production Server](#running-gcvit-on-a-production-server)
    + [Docker](#docker)
    + [Go + Node](#go-+-node-setup) 
+ [API](#api)
+ [Authentication](#authentication)

## About

GCViT is a tool for whole genome visualization of resequencing or SNP array data, which reads data in GFF and VCF format and allows a user to compare two or more accessions to visually identify regions of similarity and difference across the reference genome. Access to data sets can be controlled through authentication.

GCViT is built on top of [CViTjs](https://github.com/LegumeFederation/cvitjs), a Javascript application for viewing genomic features at the whole-genome scale. GCViT is implemented in [Go](https://golang.org/). A Docker image is available. GCViT exposes an API, and can be installed as a server only, with no UI.

![Williams Pedigree As Haplotype Blocks ](assets/readme_images/Williams_Pedigree2.png?raw=true)
Figure 1. An example of haplotype comparisons of 6 soybean accessions.

[Explore Soybean SNP data in GCViT (at SoyBase)](https://soybase.org/gcvit/)

## Getting Started
An example soybean dataset has been provided to test cvitjs. To get started, it is recommended that you use [Docker](https://www.docker.com/).

```
docker run -d -p 8080:8080 legumefederation/gcvit:v1.0.0
```

GCViT should now be available at `http://localhost:8080.`

## Setup

Setting up a local GCViT instance with your own data requires:
1. Preparing the data
2. Configuring the UI
3. Running GCViT

### Preparing the data

#### Reference Genome Assembly Backbone
1. Add a GFF3 file that defines the chromosomes for the genome assembly backbone to the `ui/cvitjs/data/` folder.
<br /><br />
An example GFF3 file is included at `ui/cvitjs/data/soySnp/gm_backbone.gff`.

2. Edit `ui/cvitjs/cvit.conf`, linking the GFF specified in #1 to CViTjs, and defining which CViTjs UI configuration file to use (described in [CViTjs documentation](https://github.com/LegumeFederation/cvitjs)).


#### Genotype Data Sets
Add one or more (optionally gzipped) VCF files representing genotype data to the `assets/` directory.

An example dataset is included at `assets/SoySNP50k_TestFile_named.vcf.gz`

#### Configuring the API Service
Add a stanza to `config/assetsconfig.yaml` for each genotype data set (VCF) file to serve it from the API server, and configure other options described below.

*Example config/assetsconfig.yaml*
```yaml
server:
  port: 8080
  portTLS: 8888
  certFile: config/testcert.cert
  keyFile: config/testcert.key
  apiOnly: False
  source: gcvit
  binSize: 500000

users:
  username : password

snptestLegacy:
  location: assets/SoySNP50k_TestFile_named.vcf.gz 
  name: soySNP 50k subset [named]
  format: vcf
  restricted:
    - username
```

The format for each VCF stanza (_snptestLegacy_ in the above example) is as follows:
```yaml
key: #user-defined unique name for internal key for API requests
  location: relative to root of server directory
  name: display name for dropdowns
  format: vcf (only option for now, automatically checks if gzipped)
  restricted: [optional] whitelist of users that may access this dataset, if not present, data may be accessed by anyone
    - username: username that can access this data
    - username2: another user that can access this datta
```

The **server** stanza is optional, and supports the following options:

| Option | Default | Use |
| ----- | ----- | ----- |
| port | 8080 | Changes the port GCViT listens on for HTTPS traffic. Defaults to 8080 only if no portTLS is provided. Otherwise ignores HTTP traffic. |
| portTLS | - | Changes the port GCViT listens for HTTPS traffic. No default provided as you need to set your own key/cert. |
| certFile | - | Cert file for HTTPS. config/testcert.cert is only for testing purposes and not a default. |
| keyFile | - | Key file for HTTPS. config/testcert.key is only for testing purposes and not a default. |
| apiOnly | False | If True, only serves the api routes, ignoring the GCViT frontend |
| source | gcvit | Value for Column 2 of generated gff files from /api/generateGFF |
| binSize | 500000 | Default number of bases used for bins |

The **users** stanza is also optional. Use this configuration option to set one-or-more users to password protect datasets.
Without proper credentials, users will never be presented with restricted datasets when using the gcvit ui.
The format is one-or more `<username> : <password>` pairs. Note this only uses BasicAuth headers, and isn't intended to 
be very secure. Future updates may include better practices if demand is present.

### Configuring the UI (optional)

* **Glyphs** for *Haplotype Block*, *Heatmap* and *Histogram* can be customized in `ui/gcvit/src/Components/[HaploConfig.js|HeatConfig.js|HistConfig.js]` respectively.

* **Popover** The box that pops up when clicking on a glyph in the image can be customized by editing `ui/cvit/src/templates/Popover.js`

* **Help box** The text for various in-app help can be customized by editing the appropriate file in `ui/gcvit/src/Components/HelpTopcs/`
  
* **CViTjs display options** Title, colors, fonts, bin size, ruler tic interval, and other CViTjs display options are defined in CViTjs configuration file (the default is `ui/cvitjs/data/soySnp/test-42219.conf`, as spedified in `ui/cvitjs/cvit.conf`).
For more information on configuring the CViTjs component of GCViT, please see the documentation [here](https://github.com/LegumeFederation/cvitjs/wiki) and the example file 
  - Configuration settings in `ui/gcvit/src/Components/DefaultConfiguration.js` override CViTjs equivalent configuration settings

### Running GCViT using Docker
The easiest way run a local GCViT instance is by using [Docker](https://docs.docker.com/engine/install/).

Setting the environment variables `DOCKER_BUILDKIT=1` and `COMPOSE_DOCKER_CLI_BUILD=1` to enable [BuildKit](https://github.com/moby/buildkit) is recommended for faster, more efficient builds.

To build CViTjs with any UI customizations, the GCViT API server, and start GCViT, execute the following command in the same directory as docker-compose.yml (i.e., in the root of the gcvit git working tree):
```
docker-compose up --build -d
```

If you wish to build the api with BasicAuth, append `--build-arg apiauth=true` to the above build command.

The GCViT UI is then accessible via web browser http://localhost:3000, while the GCViT API server is accessible at http://localhost:8080.

_Any changes to the files on the host in `assets/`, `data/`, `ui/cvitjs/data`, `gcvit/src`, or the `ui/cvitjs/cvit.conf` file will be immediately reflected in the browser_.
Changes to any other files will require rebuilding the container images and restarting the containers (`docker-compose up --build -d`).

To stop the GCViT service:

```
docker-compose down
```

## Running GCViT on a Production Server

#### Docker
To deploy a complete container image (UI + API, including the contents of `assets/` and `config/`) of GCViT in production:

1. (optional) Set the [Docker Context](https://docs.docker.com/engine/context/working-with-contexts/) to the production host (default localhost).

2. Build the complete container image on the host specified by the Docker context:
```
docker-compose -f docker-compose.prod.yml build
```

3. Deploy:
```
docker-compose -f docker-compose.prod.yml up -d
```

The GCViT UI (and API) will then be available at http://<hostname>:8080 , where _hostname_ is the host running the Docker Engine specified by the Docker context.

Alternatively, a complete container image can be built directly with `docker build`:
```
docker build -t gcvit:1.0 . -f Dockerfile
```

This command will produce a image with the tag of **gcvit:1.0** that can be used to build a container. If you want to save time with automated builds and only need the server API component, the build-arg:

```
--build-arg apionly=false
```

is provided to skip over the building of the UI components. Similarly, if you wish to build the tool with BasicAuth the build-arg:

```
--build-arg apiauth=true
```

Then to deploy using `docker run`:

```
docker run -d -p 8080:8080 gcvit:1.0
```

### Go + Node Setup
GCViT may also be built and served directly using [Go](https://golang.org/) and and [Node](https://nodejs.org/en/) together.
Before beginning, check that Go is set up and Node is configured to at least the most current LTS version (currently 12.14.0).

#### Building the backend component with Go
The following packages are used with this service:
```
github.com/awilkey/bio-format-tools-go/gff 
github.com/awilkey/bio-format-tools-go/vcf
github.com/buaazp/fasthttprouter v0.1.1
github.com/fsnotify/fsnotify v1.4.7
github.com/spf13/pflag v1.0.5
github.com/spf13/viper v1.6.2
github.com/valyala/fasthttp
```

There are several ways to obtain the dependencys, but the reccomended way is to run `go get` before running the software for the first time. After dependencies are satisfied you can use the internal go development server to test using:

`go run server.go`

from the `/api` directory of the project.

By default this will listen on port 8080, but you can change this in the configuration file.

Once up, you can test that the server is up using wget or curl:

| protocol | request |
| -------- | ------- |
| wget     | wget localhost:8080/api/experiment |
| curl     | curl localhost:8080/api/experiment |

Either protocol should return a JSON object that contains a list of all the configured VCF files.

If you wish to compile the server, Go has a robust set of tools for building and cross-compiling binaries.
In the most simple form:

`go build -o server .`

Will builds a binary that has statically linked libraries, making it portable.

If running on a server without a Go compiler configured, the language has support built-in for cross compiling built in. See [HERE](https://golangcookbook.com/chapters/running/cross-compiling/)
for details.

#### Building the frontend components with Node

This repository contains a pre-built version of both the UI component and CViTjs, so this section is mostly optional.

If you wish to add configuration data for CViT without re-building the tool, you may place the files directly in `ui/gcvit/build/cvitjs`.

If you want to use a custom build of CViTjs, navigate to `/ui/cvitjs/` and write and build your changes. This is most often used when wanting to change CViT's css or the click on feature Popover display. Place the resulting files from the build directory directly into `ui/gcvit/build/cvitjs/build` to test. These changes will last until you rebuild the GCViT ui component. 

To build the UI component of CViT:
```
#first time only
npm run install

#normal build
npm run build

```

To save changes to CViT, place the build compontent in `ui/gcvit/public/cvitjs` and rebuild the gcvit component.

To rebuild the UI component of GCViT:

```
#first time only
npm install

#normal build
npm run build

#with basic authentication elements
npm run buildauth
```

This will create a webpacked version of the GCViT UI. Most common reasons to rebuild is updating the Help documentation and
updating the CSS.


## API:

The following API is served by the GCViT service component:

| Path | Verb | Returns |
| ---- | ---- | ---- |
| /api/experiment| GET | JSON representation of all experiments in assetconfig.yaml |
| /api/experiment/{experiment} | GET | JSON representation of all PIs in VCF header |
| /api/generateGFF | POST | returns gff. Expected parameters of Ref={experiment:PI}&Variant={sameexperiment:PI}, with any number of variants |
| | | |
| / | GET | tool UI - Only if apiOnly is **False** |
|/login | GET | Attempts to authenticate a username and password. Returns status 200 if OK, 401 if not. | 

## Authentication:
To control access to data sets, create users and restrict access, see `assestconfig.yaml`. The files `config/testcert.*` are an example of a self-signed SSL certificate. Instruction for generating a new one and be found [here](
https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04)
