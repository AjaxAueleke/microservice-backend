FROM alpine:latest
WORKDIR /app
COPY ./build /app/
EXPOSE 8080
Run the Go application.
CMD ["bash","/app/build"]
