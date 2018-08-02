set -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=e4cash
# image name
IMAGE=db
# version postgresql
VERSION=10.4

docker build --tag=$IMAGE-postgresql-$VERSION -t $USERNAME/$IMAGE-postgresql-$VERSION:latest .