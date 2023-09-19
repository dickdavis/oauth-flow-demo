# Testing

## Getting Started

To get started testing, import the collections and environments within this directory into Postman.

## Processes

### Authorization Code Grant

This section documents how to test the authorization code grant process.

* Generate a URL for initiating the authorization process. Execute command:

```
bin/rails r script/generate_link_for_authorize_endpoint.rb
```

* Copy and paste the code verifier and code challenge into the Postman variable for the Local Development environment.
* Copy and paste the generated URL into the browser.
* Enter the client credentials into the prompt. These credentials are displayed in the output from the script.
* Authenticate the user, if necessary.
* Approve the authorization request.
* Copy and paste the authorization code from the redirect URL into the Postman variable for the Local Development environment.

### Authorization Code Redemption

This section documents how to test the authorization code redemption process.

* Ensure the authorization code and code verifier in the Postman variables are valid.
  * Repeat the Authorization Process steps to obtain a new authorization code and code verifier, if necessary.
* Send the `/oauth/token` request from Postman.
* Save the access and refresh tokens from the response.

### Current User Data Retrieval

This section documents how to retrieve current user data for a provided access token from the API.

* Ensure the access token in the Postman variable is valid.
  * Obtain a new access token by repeating the Authorization and Authorization Code Redemption processes.
* Send the `/api/v1/users/current` request from Postman.
* Save the user data from the response.
