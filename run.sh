set -ex
# run docker
# enviroment local
docker run --name=db-postgresql --hostname=db.e4cash.local -m 1GB -p 5432:5432 -d e4cash/db-postgresql-10.4:latest


docker ps
