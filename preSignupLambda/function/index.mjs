import {
    ListUsersCommand,
    CognitoIdentityProviderClient,
} from "@aws-sdk/client-cognito-identity-provider";

export const handler = async (event, context, callback) => {
    const userPoolId = "eu-west-2_AQejk3Z18";
    const email = event.request.userAttributes.email;

    // Call the ListUsers API to check if the email already exists in the user pool
    const params = {
        UserPoolId: userPoolId,
        Filter: `email = "${email}"`,
    };
    const client = new CognitoIdentityProviderClient({ region: 'eu-west-2' });
    const listUsersCommand = new ListUsersCommand(params);

    const data = await client.send(listUsersCommand);
    if (data?.Users?.length > 0) {
        callback(new Error("Email is already taken!"), event);
    } else {
        callback(null, event);
    }
};
