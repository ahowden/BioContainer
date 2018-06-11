FROM alpine

Copy src .

CMD ["ls"]

EXPOSE 80