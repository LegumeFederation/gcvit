#Multistage build
#Build stage for cvit component
FROM docker.io/library/node:22-alpine AS cvitui
WORKDIR /cvit
#Doing package before build allows us to leverage docker caching.
COPY ui/cvitjs/package*.json ./
RUN npm ci
# avoid copying user-modified cvit.conf and data
COPY ui/cvitjs/css ./css
COPY ui/cvitjs/src ./src
COPY ui/cvitjs/rollup.config.js ui/cvitjs/.babelrc ./
RUN npm run build

#gcvit image with dependencies installed for interactive development
FROM docker.io/library/node:22-alpine AS gcvitui-dev
ARG apiauth=false
WORKDIR /gcvit
COPY ui/gcvit/package*.json ./
RUN npm ci
#Migrate over build artifacts from the cvitui stage
COPY --from=cvitui /cvit/build public/cvitjs/build/
COPY ui/gcvit/public ./public
ENTRYPOINT ["npm", "start"]
EXPOSE 3000

FROM gcvitui-dev AS gcvitui
COPY ui/gcvit ./
RUN npm run build && \
	if [ "$apiauth" = "true" ] ; then echo Building UI with Auth && npm run buildauth ; fi

#Build stage for golang API components
FROM docker.io/library/golang:1.23-alpine AS gcvitapi
RUN apk add --update --no-cache git
#add project to GOPATH/src so dep can run and make sure dependencies are right
ADD api/ /go/src/
WORKDIR /go/src/
#grab dependencies for golangdd
RUN go get
RUN CGO_ENABLED=0 go build -o server .

#Actual deployment container stage
FROM docker.io/library/busybox:musl AS api
COPY --from=gcvitapi /go/src/server /app/
#add mount points for config and assets
VOLUME ["/app/config","/app/assets"]
WORKDIR /app
#start server
ENTRYPOINT ["/app/server","--gcvitRoot=./", "--ui=/ui"]
EXPOSE 8080

FROM api AS api-ui
COPY --from=gcvitui /gcvit/build /app/ui/
COPY --from=cvitui /cvit/build/ /app/ui/cvitjs/build

#assets and config built directly into container
#This works best with smaller datasets
FROM api-ui AS full
COPY ui/cvitjs/cvit.conf /app/ui/cvitjs/cvit.conf
COPY ui/cvitjs/data /app/ui/cvitjs/data
COPY /config /app/config
COPY /assets /app/assets
# precompress files so fasthttp doesn't attempt to compress them
# (and fail due to lack of write permissions)
RUN find /app/ui -type f -exec sh -c 'gzip < {} > {}.fasthttp.gz' \;

# Run as "nobody" user (use uid for cf-for-k8s compatibility)
USER 65534
