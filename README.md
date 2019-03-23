# auth-cognito

Demo of the OAuth2 flow with AWS Cognito using the implicit flow

You can see this running at http://leonyork.com/auth-demo

## Prerequisites

You'll need npm installed 

```bash
curl https://npmjs.com/install.sh | sh
```

And the AWS cli - see https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html

## Project setup
```
npm install
```

### Compiles and hot-reloads for development
It's not possible to run AWS Cognito locally, so you will have to setup your own cognito, then create a `.env.local` using `.env` as the template.
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Build and deploy
The first time this is deployed it takes a while as it provisions a CloudFront distribution (15 mins or so)
```
npm run deploy -- --stage some-stage
```
Note that it will try and set a domain for your instance of Cognito. If this domain is already taken, then it won't be able to use that domain. You may want to change the name of the service in serverless.yml if this is the case.

### Lints and fixes files
```
npm run lint
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).
