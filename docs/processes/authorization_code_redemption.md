# oauth-flow-demo

## System Design

### Authorization Code Redemption

Authorization code redemption is the process by which a client redeems a previously issued authorization code
in exchange for access and refresh tokens.

```mermaid
---
title: Authorization Code Redemption
---
sequenceDiagram
autonumber

actor Client
participant Authorization Service
participant Data Layer

Client-->>Authorization Service: Calls the token endpoint with authorization code and code verifier
Note right of Client: POST /oauth/token
Authorization Service-->>Data Layer: Retrieves authorization code and code challenge
Authorization Service-->Authorization Service: Verifies code verifier with code challenge
Authorization Service-->Authorization Service: Generates access and refresh tokens
Authorization Service-->>Data Layer: Creates an OAuth Session record with token JTI's
Authorization Service-->>Client: Returns access and refresh tokens to client
```

### Client

The Client entity represents a client application registered with the OAuth provider.

### Authorization Service

The Authorization Service entity represents the component of the application which is
responsible for redeeming the authorization code and issuing access and refresh tokens.

### Data Layer

The Data Layer entity is a relational database used for storing data related to authorization grants and
OAuth sessions.


## Endpoints

### POST /oauth/token

The client calls the `POST /oauth/token` endpoint to redeem an authorization code for access and refresh
tokens. The endpoint responds with either an error code conforming to RFC-6749 or a JSON object containing
the access and refresh tokens.

**HTTP Method**: `POST`

**URL**: `/oauth/token`

**Params**:

| Param | Required? | Description |
| ----- | --------- | ----------- |
| grant_type | yes | The authorization grant type for the authorization code grant process. Must be 'authorization_code'. |
| code_verifier | yes | The code verifier used to generate the code challenge provided during the authorization process. |
| code | yes | The authorization code previously issued to the client during the authorization process. |

**Example**:

```
/oauth/token

grant_type=authorization_code&
code_verifier=CR70DhqQkvzPL2JjlQNyiCNgoRDZj2jko0mW7CpEUXJPgK-uEeQoZCSJlBgup73MtqpdeYRLmA&
code=02a456ce-73a5-416d-8159-7c8bff9a19e5
```

**Example Response**:

```
{
    "access_token": "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvYXBpLyIsImlhdCI6MTY5NTE0MDY1NiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwLyIsImp0aSI6Ijc0YjVkZTlkLTQ4YmQtNDFjNC1hMGNiLWZjYzM0OWU3MTY2NyIsInVzZXJfaWQiOjMsImV4cCI6MTY5NTE0MDk1Nn0.aUhztv6x2-foSfp17W_7-mMC-w3HKUx25pMSWHYjzqY",
    "refresh_token": "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvYXBpLyIsImlhdCI6MTY5NTE0MDY1NiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwLyIsImp0aSI6IjUxMGJhNTdiLTgwNTQtNGQxYi1iYWQ1LTVmZmZjOWE0NzA4ZCIsImV4cCI6MTY5NjM1MDI1Nn0.6-7DgP4UFcA7hEkK7XRob_sRNEGH1QlvalysDJjBrko",
    "token_type": "bearer",
    "expires_in": 1695140956
}
```


## References

[RFC-6749: The OAuth 2.0 Authorization Framework](https://www.rfc-editor.org/rfc/rfc6749#section-3.1)

[RFC-7636: Proof Key for Code Exchange by OAuth Public Clients](https://datatracker.ietf.org/doc/html/rfc7636)


