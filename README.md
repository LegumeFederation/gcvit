 # GCViT
![GCViT](assets/readme_images/logo.png?raw=true)

## Table of Contents
+ [About](#about) 
+ [Getting Started](#getting-started)
+ [Setup](#setup)
    + [General](#general-setup)
    + [Docker](#docker-setup)
    + [Go + Node](#go-+-node-setup) 
+ [API](#api)
+ [Authentication](#authentication)

## About

GCViT is a tool for whole genome visualization of resequencing or SNP array data, which reads data in GFF and VCF format and allows a user to compare two or more accessions to visually identify regions of similarity and difference across the reference genome. Access to data sets can be controlled through authentication.

GCViT is built on top of [CViTjs](https://github.com/LegumeFederation/cvitjs), a Javascript application for viewing genomic features at the whole-genome scale. GCViT is implemented in [Go](https://golang.org/). A Docker image is available. GCViT exposes an API, and can be installed as a server only, with no UI.

![Williams Pedigree As Haplotype Blocks ](assets/readme_images/Williams_Pedigree2.png?raw=true)
Figure 1. An example of haplotype comparisons of 6 soybean accessions.

[Explore Soybean SNP data in GCViT](https://soybase.org/gcvit/)

## Getting Started
An example dataset has been provided to test cvitjs. To get started, it is reccomended that you use [Docker](https://www.docker.com/), though there are provisions to run [standalone](#go-+-node-setup). To run for the first time in docker:

First build the image: 
```
docker build -t gcvit:1.0 . -f Dockerfile
```

Then run the image:
```
docker run -d \
--name gcvit \
--mount type=bind,source="$(pwd)"/config,target=/app/config \
--mount type=bind,source="$(pwd)"/assets,target=/app/assets \
-p 8080:8080 \
gcvit:1.0
```

GCViT should now be available at `http://localhost:8080.`

If you are planning on developing and using gcvit on a server, the `docker-compose` branch has been made available with further optimisations for a CI environment.

## Setup
While GCViT is intended to be an online tool, it may also be run locally as a stand alone tool. In either case, there are two main approaches to running GCViT, in a Docker container, or using the built-in Go server. The configuration of the backend service and the UI stays mostly the same in either case.
A stand-alone [Electron](https://www.electronjs.org/) desktop app is in the process of being developed. 

Instructions for the UI are provided in the application itself.
 
### General Setup

The steps for setting up a GCViT instance consists of downloading and installing the application, configuring the server, and data preparation. The GCViT repository includes example data from soybean consisting of these files: SNP data is in `assets/SoySNP50k_TestFile_named.vcf,` the backbone chromosomes are defined in `ui/gcvit/public/cvitjs/data/soySnp/gm_backbone.gff,` and the CViTjs image is configured with `ui/gcvit/public/cvitjs/data/soySnp/soySnp.conf.` 


#### Configuring the Service
No matter which method you intend to run GCViT, configuration of the Go backend service is the same. The default configuration file is `config/assetsconfig.yaml` and it has the following format:

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

The server stanza is optional, and supports the following options:

| Option | Default | Use |
| ----- | ----- | ----- |
| port | 8080 | Changes the port GCViT listens on for HTTPS traffic. Defaults to 8080 only if no portTLS is provided. Otherwise ignores HTTP traffic. |
| portTLS | - | Changes the port GCViT listens for HTTPS traffic. No default provided as you need to set your own key/cert. |
| certFile | - | Cert file for HTTPS. config/testcert.cert is only for testing purposes and not a default. |
| keyFile | - | Key file for HTTPS. config/testcert.key is only for testing purposes and not a default. |
| apiOnly | False | If True, only serves the api routes, ignoring the GCViT frontend |
| source | gcvit | Value for Column 2 of generated gff files from /api/generateGFF |
| binSize | 500000 | Default number of bases used for bins |

The users stanza is also optional. Use this configuration option to set one-or-more users to password protect datasets.
Without proper credentials, users will never be presented with restricted datasets when using the gcvit ui.
The format is one-or more `<username> : <password>` pairs. Note this only uses BasicAuth headers, and isn't intended to 
be very secure. Future updates may include better practices if demand is present.

Finally you may have one or more data tracks, that have the following required fields:

```yaml
key: #internal key for API requests
  location: relative to root of server directory
  name: display name for dropdowns
  format: vcf (only option for now, automatically checks if gzipped)
  restricted: [optional] whitelist of users that may access this dataset, if not present, data may be accessed by anyone
    - username: username that can access this data
    - username2: another user that can access this datta
```

While it is recommended, the data file given for 'location' does not have to be in the `assets` folder to be read by GCViT.

### Preparing the data

**Reference Genome Assembly Backbone** You will need a GFF3 file that defines the chromosomes for the genome assembly backbone. This file must be added to the `ui/gcvit/public/cvitjs/data/` folder. An example file is included in the example, `ui/gcvit/public/cvitjs/data/soySnp/gm_backbone.gff`.

To link the GFF file to CViTjs, edit the file `ui/gcvit/public/cvitjs/cvit.conf` to indicate the file exists and which CViTjs UI configuration file to use (described in [CViTjs documentation](https://github.com/LegumeFederation/cvitjs)).

**Genotype Data Sets** Each genotype data set is represented by a single VCF file (which may be gzipped). By default, the files should go into the assets/ directory, but if you choose a different directory, it will be necessary to tell the application where to find the files. Information about connecting to a different the genotype data directory is described below. An example dataset is available at `/assets/SoySNP50k_TestFile_named.vcf.gz`

### Configuring the UI

Most aspects of the CViTjs display can be customized, including colors, fonts, and the popover box that appears when mousing over a feature. For more information on configuring the CViTjs component of GCViT, please see the documentation [here](https://github.com/LegumeFederation/cvitjs/wiki) and the example file `ui/gcvit/public/cvitjs/data/soySnp/soySnp.conf`.

Configuration files for the three glyphs used by GCViT *Haplotype Block*, *Heatmap* and *Histogram* are in `ui/gcvit/src/Components/[HaploConfig.js|HeatConfig.js|HistConfig.js]` respectively. Any changes made will require a rebuild of the gcvit ui.

Other display options (title, bin size, ruler tic interval) can be changed through editing the values in `ui/gcvit/src/Components/DefaultConfiguration.js`. After changes are made, the docker container will need to be rebuilt, or a manual build will need to be triggered through node, as described in the following sections. 

**Popover customization** The box that pops up when clicking on a glyph in the image can be customized by editing `ui/cvit/src/templates/Popover.js` if building in docker, if not using docker, you must rebuild the cvit component and moving the resulting build directory to `/ui/gcvit/public/cvitjs/`.

**Help box customizations** The text in in-app help can be customized. Edit the files `ui/gcvit/src/Components/HelpTopcs.`
  
**Note:** Configuration settings in `ui/gcvit/src/Components/DefaultConfiguration.js` override CViTjs equivalent configuration settings, for example, ruler tic interval.

### Docker Setup
For general use, it is easiest to get started with GCViT using [Docker](https://www.docker.com/). Before starting, make sure that docker is properly configured for your system.

The Docker build process will retrieve the most recent version of CViTjs during the build process. 

To add reference genome backbone files, or other configuration changes to cvit place the files in `ui/gcvit/public`. Any changes to the cvitjs source will be built and added to the container, including changes to popovers. 

To build through docker:
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

When starting the container, there are two mount points exposed to add configuration and data directories: `/app/config` and `/app/assets` respectively.

An example of starting an instance of GCViT inside the gcvit directory, binding the configuration and assets directory at run time: 

```
docker run -d \
--name gcvit \
--mount type=bind,source="$(pwd)"/config,target=/app/config \
--mount type=bind,source="$(pwd)"/assets,target=/app/assets \
-p 8080:8080 \
gcvit:1.0
```

If using the default server settings in assetconfig.yaml, GCViT will now be available at `http://localhost:8080.`

To update the data, you should be able to just add it directly to the mounted source, as GCViT checks for updated data when appropriate. 

##### Modifying the Docker container
After building the Docker container, you will see two important directories in the `ui` directory: `cvit/`, and `gcvit/`. 

Files under `/ui/cvit` should be modified to make changes to the cvit genome viewer container. Any changes to `css` or `src` require a rebuild of cvitjs. 

Files under `/ui/gcvit` should be modified to edit the view control section of the UI. Any changes to `src` require a rebuild of the gcvit component.

Rebuilding the docker container will automatically integrate changes to either `ui/cvit` or `ui/gcvit` otherwise there are options to change the ui component without rebuilding the container.

To make changes without rebuilding the GCViT container but that require rebuilding the GCViT ui (including changes to CViTjs), edit and add files to `ui/gcvit/public/`. then rebuild the gcvit component.

To make changes without rebuilding GCViT or CViTjs, edit and add files to `build/`. Not recommended unless testing changes.

The best practices are to make CViTjs changes in `public/`.


##### Adding data set files to Docker container
If data set files are located in the `/app/assets/` directory, you may want to build them into the container, especially for smaller datasets. To do so, edit `Dockerfile,` look for the line, `#Comment above and uncomment below if you would rather have assets built into container,` and follow the instructions.

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
