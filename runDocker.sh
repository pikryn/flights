docker build . -t pikryn/flights
docker run -v $PWD/loty_dane:/loty_dane pikryn/flights
