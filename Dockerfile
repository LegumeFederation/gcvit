#Multistage build
#Build stage for cvit component
FROM node:12.18.0-alpine3.12 as cvitui
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
FROM node:12.18.0-alpine3.12 as gcvitui-dev
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
EXPOSE 8080

FROM api as api-ui
COPY --from=gcvitui /gcvit/build /app/ui/
COPY --from=cvitui /cvit/build/ /app/ui/cvitjs/build

#assets and config built directly into container
#This works best with smaller datasets
FROM api-ui as full
COPY ui/cvitjs/cvit.conf /app/ui/cvitjs/cvit.conf
COPY ui/cvitjs/data /app/ui/cvitjs/data
COPY /config /app/config
COPY /assets /app/assets
