# Bigcouch from Cloudant

CouchDB with enhancements for clustering performance, for use in a kubernetes pod.

Now using a register-service init-container for automatic registration with the cluster

## Directions

* Create the necessary secrets listed in `bigcouch-petset.yaml`
* Create the PersistentVolumes in `bigcouch-pvs.yaml`
* Create the PersistentVolumeClaims in `bigcouch-pvcs.yaml`
* Create the Service in `bigcouch-service.yaml`
* Create the petset in `bigcouch-service.yaml`


## Issues

### Docker.hub automated builds don't tolerate COPY or ADD to root /

I've added a comment to the Dockerfile noting this and for now am copying to
/tmp and then copying to / in the next statement.

ref: https://forums.docker.com/t/automated-docker-build-fails/22831/28
