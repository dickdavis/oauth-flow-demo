# oauth-flow-demo

## System Design

### Token Refresh

Token refresh is the process by which a client provides a valid refresh token
in exchange for new access and refresh tokens.

```mermaid
---
title: Token Refresh
---
sequenceDiagram
autonumber

actor Client
participant Authorization Service
participant Data Layer

Client-->>Authorization Service: Calls the token endpoint with grant_type and refresh_token params
Note right of Client: POST /oauth/token
Authorization Service-->Authorization Service: Decodes refresh token
Authorization Service-->>Data Layer: Retrieves OAuth session via refresh token JTI
Authorization Service-->Authorization Service: Validates refresh token and OAuth session status
Authorization Service-->Authorization Service: Generates new access and refresh tokens
Authorization Service-->>Data Layer: Creates new OAuth Session record with token JTI's
Authorization Service-->>Data Layer: Marks previous OAuth session as refreshed
Authorization Service-->>Client: Returns access and refresh tokens to client
```

### Client

The Client entity represents a client application registered with the OAuth provider.

### Authorization Service

The Authorization Service entity represents the component of the application which is
responsible for validating the provided refresh token and issuing new access and refresh tokens.

### Data Layer

The Data Layer entity is a relational database used for storing data related to OAuth sessions.


## Endpoints

### POST /oauth/token

The client calls the `POST /oauth/token` endpoint to exchange a refresh token for new access and refresh
tokens. The endpoint responds with either an error code conforming to RFC-6749 or a JSON object containing
the access and refresh tokens.

**HTTP Method**: `POST`

**URL**: `/oauth/token`

**Params**:

| Param | Required? | Description |
| ----- | --------- | ----------- |
| grant_type | yes | The authorization grant type for the token refresh process. Must be 'refresh_token'. |
| refresh_token | yes | The valid refresh token corresponding to the OAuth session to be refreshed. |

**Example**:

```
/oauth/token

grant_type=refresh_token&
refresh_token=eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvYXBpLyIsImlhdCI6MTY5NTE0MDY1NiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwLyIsImp0aSI6IjUxMGJhNTdiLTgwNTQtNGQxYi1iYWQ1LTVmZmZjOWE0NzA4ZCIsImV4cCI6MTY5NjM1MDI1Nn0.6-7DgP4UFcA7hEkK7XRob_sRNEGH1QlvalysDJjBrko
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
