FROM alpine

Copy src ./src

CMD ["ls"]

EXPOSE 80