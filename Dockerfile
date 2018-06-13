FROM alpine

RUN apk add --update python3 perl

Copy src ./tools

CMD ["ls"]

EXPOSE 80