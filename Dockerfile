FROM alpine

Copy src ./tools

CMD ["ls"]

EXPOSE 80