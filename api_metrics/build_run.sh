printf  "stopping and deleting previous container..\n\n"
docker stop api_r
docker rm api_r

printf "building and running..\n\n"
docker build -t api_r_geo .
docker run -d --restart unless-stopped --name api_r -p 8080:8080 -v ${PWD}:/home/rstudio/my-documents api_r_geo

printf "starting\n\n"
docker logs api_r -f

