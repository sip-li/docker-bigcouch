# Bigcouch from Cloudant

CouchDB with enhancements for clustering performance, for use in a kubernetes pod.

## Issues

### 1. Kubernetes Pod hostname's do not reflect it's PodIP assigned DNS. 

The hack I've done to work around this requires root privileges at runtime, effectively breaking the ability to set a non root user in the dockerfile.  `USER couchdb` has been commented out in the dockerfile for this reason.

Docker by design does not allow you to change the hostname of a container after creation.  It also manages the /etc/hosts file, which means chown's in the docker build process are set back to root again when a container is created.

EPMD requires that the environment variable: HOSTNAME and the executable: `env hostname` return a correct and resolvable hostname.

I've fixed this by creating a dummy hostname bash script and place it at the beginning of the path: '/opt/bigcouch/bin/hostname-fix'.  In the entrypoint script, if `KUBERNETES_HOSTNAME_FIX` is set, this script is linked at runtime to '/opt/bigcouch/sbin/hostname', and the environment variable `HOSTNAME` is set correctly, as well as creating an entry in /etc/hosts.  

Only the root user can modify /etc/hosts in a docker container because ownership changes in the build process aren't persisted during container initialization.

If anyone knows of a better way to do this, please submit a pull request with a short explanation of the process you used.

-Joe