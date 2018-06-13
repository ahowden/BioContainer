FROM alpine

RUN apk add --update python:3 perl

Copy src ./tools

CMD ["ls"]

EXPOSE 80