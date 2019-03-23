const {
    execSync
} = require('child_process');


function handler(data, serverless, options) {
    console.log(`data = ${JSON.stringify(data)}`);
    console.log(`options = ${JSON.stringify(options)}`);

    const callbackUrl = `https://${data.DomainName}`;
    runCommand(`aws cognito-idp update-user-pool-client ` +
        `--user-pool-id ${data.UserPoolId} ` +
        `--client-id ${data.UserPoolClientId} ` +
        `--region=${options.region} ` +
        `--callback-urls '["${callbackUrl}"]' ` +
        `--logout-urls '["${callbackUrl}"]' ` +
        `--supported-identity-providers '["COGNITO"]' ` +
        `--allowed-o-auth-flows-user-pool-client ` +
        `--allowed-o-auth-flows '["implicit"]' ` +
        `--allowed-o-auth-scopes '["openid"]' `);


    runCommand(`aws cognito-idp create-user-pool-domain ` +
        `--user-pool-id ${data.UserPoolId} ` +
        `--domain ${data.ResourceName} ` +
        `--region=${options.region} `);

    const authUrl = `${data.ResourceName}.auth.${options.region}.amazoncognito.com`;
    runCommand(`VUE_APP_COGNITO_HOST=${authUrl} ` +
        `VUE_APP_CLIENT_ID=${data.UserPoolClientId} ` +
        `VUE_APP_REDIRECT_URL=${callbackUrl} ` +
        `npm run build && npm run sync`);

    runCommand(`aws cloudfront create-invalidation ` +
        `--distribution-id ${data.CloudFrontDistributionId} ` +
        `--paths /index.html ` +
        `--region=${options.region} `);

}

function runCommand(command) {
    console.log(command);
    try {
        execSync(command, (err, stdout, stderr) => {
            // the *entire* stdout and stderr (buffered)
            console.log(err);
            console.log(`stdout: ${stdout}`);
            console.log(`stderr: ${stderr}`);
        });
    } catch (err) {
        console.log(err);
    }
}

module.exports = {
    handler
};