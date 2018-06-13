FROM alpine

RUN apk add --update python perl

Copy src ./tools

CMD ["ls"]

EXPOSE 80