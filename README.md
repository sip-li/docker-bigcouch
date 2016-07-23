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

#### 1. Bigcouch not picking up admin user created in local.ini config file. 

I don't feel like spending too much time on this because bigcouch is ridiculously obsolete and I doubt CouchDB has this problem.  I don't reccomend running Bigcouch at all if you can help it, run CouchDB instead. 
