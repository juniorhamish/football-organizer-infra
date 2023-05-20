# IaC for Football Organizer Project
Terraform creates the Cognito User Pool and assigns the pre-signup lambda that ensures the email address is not already in use.
There is currently an unsolved circular dependency in the config. The lambda needs to be granted access to the user pool to be able to check for the existing email addresses in use, the user pool needs to be told about the lambda as part of the pre-signup configuration.
Given the user pool was already set up manually, then imported to terraform, the lambda has been hardcoded with the ARN of the user pool.
To recreate the infrastructure from scratch I'll need to either find a solution to this cycle or split out the config to create the user pool first without the lambda.
