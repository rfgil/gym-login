# gym-login

Web application that displays the login QR code to access VivaGym.

For some reason, their mobile app won't load with [microG's](https://microg.org/) version of google play services, so I built this to get the QR code using the browser.

## Build

1. Add credentials to the `.env` file.

2. Build the docker image.
```
docker build -t gym-login:1.0.0 .
```

3. Run the image
```
docker run -d -p 4567:4567 gym-login:1.0.0
```
