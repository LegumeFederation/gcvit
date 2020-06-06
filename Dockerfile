#Multistage build
#Build stage for cvit component
FROM node:12.18.0-alpine3.11 as cvitui
ARG cvitjs_version=44fc7a98a78275014a547906a6f58bef1385e175
RUN set -o pipefail && wget -O - https://github.com/LegumeFederation/cvitjs/archive/${cvitjs_version}.tar.gz \
    | tar -xzf - && mv cvitjs-${cvitjs_version} /cvit
WORKDIR /cvit
#Doing package install before build allows us to leverage docker caching.
RUN npm install
COPY ui/cvit_assets/src/ src/
RUN npm run build

#Build stage for gcvit ui component
FROM node:12.18.0-alpine3.11 as gcvitui
ARG apiauth=false
WORKDIR /gcvit
COPY /ui/gcvit/package*.json ./
RUN npm install
COPY ui/gcvit/ ./
#Build UI components
RUN npm run build && \
	if [ "$apiauth" = "true" ] ; then echo Building UI with Auth && npm run buildauth ; else npm run build ; fi

#Build stage for golang API components
FROM golang:1.13.12-alpine3.12 as gcvitapi
RUN apk add --update --no-cache git
#add project to GOPATH/src so dep can run and make sure dependencies are right
ADD server/src /go/src/
WORKDIR /go/src/
#grab dependencies for golangdd
RUN go get
RUN CGO_ENABLED=0 go build -o server .

#Actual deployment container stage
FROM scratch AS api
COPY --from=gcvitapi /go/src/server /app/
#add mount points for config and assets
VOLUME ["/app/config","/app/assets"]
WORKDIR /app
#start server
ENTRYPOINT ["/app/server"]

#Default image (combined api + gcvitui image, no data sets)
#Migrate over build artifacts from the cvitui stage
FROM api AS api-ui
COPY --from=gcvitui /gcvit/build /app/ui/build/
COPY --from=cvitui  /cvit/build  /app/ui/build/cvitjs/build/ 
COPY ui/cvit_assets/cvit.conf    /app/ui/build/cvitjs/cvit.conf
COPY ui/cvit_assets/data         /app/ui/build/cvitjs/data

#assets built into container
#This works best with smaller datasets
FROM api-ui AS complete
COPY ./server/config /app/config
COPY ./server/assets /app/assets
