#Multistage build
#Build stage for cvit component
FROM node:12.18.0-alpine3.12 as cvitui
ARG apionly=false
WORKDIR /cvit
#Doing package before build allows us to leverage docker caching.
COPY ui/cvitjs/package*.json ./
RUN if [ "$apionly" = "false" ] ; then npm ci; fi
COPY ui/cvitjs/ ./
RUN if [ "$apionly" = "false" ] ; then 	npm run build && \
	echo Built cvitjs ; else echo Skipping cvitjs component; fi

#Build stage for gcvit ui component
FROM node:12.18.0-alpine3.12 as gcvitui
ARG apionly=false
ARG apiauth=false
WORKDIR /gcvit
COPY ui/gcvit/package*.json ./
RUN if [ "$apionly" = "false" ] ; then npm ci; fi
#Migrate over build artifacts from the cvitui stage
COPY ui/gcvit ./
#Build UI components
RUN if [ "$apionly" = "false" ] ; then 	npm run build && \
	if [ "$apiauth" = "true" ] ; then echo Building UI with Auth && npm run buildauth ; else npm run build ; fi && \
	echo Built UI components  ; else echo Skipping UI Components; fi

#Build stage for golang API components
FROM golang:1.13.12-alpine3.12 as gcvitapi
RUN apk add --update --no-cache git
#add project to GOPATH/src so dep can run and make sure dependencies are right
ADD api/ /go/src/
WORKDIR /go/src/
#grab dependencies for golangdd
RUN go get
RUN CGO_ENABLED=0 go build -o server .

#Actual deployment container stage
FROM scratch as api
#Good practice to not run deployed container as root
COPY --from=gcvitapi /go/src/server /app/
#add mount points for config and assets
VOLUME ["/app/config","/app/assets"]
WORKDIR /app
#start server
ENTRYPOINT ["/app/server","--gcvitRoot=./", "--ui=/ui"]

FROM api as api-ui
COPY --from=gcvitui /gcvit/build /app/ui/
COPY --from=cvitui /cvit/build/ /app/ui/cvitjs/build
COPY --from=cvitui /cvit/cvit.conf /app/ui/cvitjs/cvit.conf
COPY --from=cvitui /cvit/data/ /app/ui/cvitjs/data

#uncomment to build assets directly into container
#This works best with smaller datasets
#FROM api-ui AS complete
#COPY /config /app/config
#COPY /assets /app/assets

