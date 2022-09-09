printf  "stopping and deleting previous container..\n\n"
docker stop api_extract_ts
docker rm api_extract_ts

printf "building and running..\n\n"
docker build -t api_flask .
docker run --name api_extract_ts -d -p 8081:8081 api_flask

printf "starting\n\n"
docker logs api_extract_ts -f
