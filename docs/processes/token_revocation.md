# oauth-flow-demo

## System Design

### Token Revocation

Token revocation is the process by which a client provides either an access token or refresh token which is
then invalidated by the server.

```mermaid
---
title: Token Revocation
---
sequenceDiagram
autonumber

actor Client
participant Authorization Service
participant Data Layer

Client-->>Authorization Service: Calls the revoke endpoint with token_type_hint and token params
Note right of Client: POST /oauth/revoke
Authorization Service-->Authorization Service: Determines most efficient OAuth session retrieval strategy for provided hint
Authorization Service-->Authorization Service: Decodes token
Authorization Service-->>Data Layer: Retrieves OAuth session via retrieval strategy
Authorization Service-->>Data Layer: Marks OAuth session as revoked
Authorization Service-->>Client: Returns HTTP ok status
```

### Client

The Client entity represents a client application registered with the OAuth provider.

### Authorization Service

The Authorization Service entity represents the component of the application which is
responsible for invalidating the OAuth session for the provided token.

### Data Layer

The Data Layer entity is a relational database used for storing data related to OAuth sessions.


## Endpoints

### POST /oauth/revoke

The client calls the `POST /oauth/revoke` endpoint to revoke the OAuth session associated with an access or refresh token.
The endpoint responds with HTTP status OK regardless of whether the token is successfully revoked or not.

**HTTP Method**: `POST`

**URL**: `/oauth/revoke`

**Params**:

| Param | Required? | Description |
| ----- | --------- | ----------- |
| token_type_hint | no | The type of token provided; used for efficient retrieval of OAuth session. Can be either 'access_token' or 'refresh_token'. |
| token | yes | The access or refresh token to be revoked. |

**Example**:

```
/oauth/revoke

token_type_hint=refresh_token&
token=eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvYXBpLyIsImlhdCI6MTY5NTE0MDY1NiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDozMDAwLyIsImp0aSI6IjUxMGJhNTdiLTgwNTQtNGQxYi1iYWQ1LTVmZmZjOWE0NzA4ZCIsImV4cCI6MTY5NjM1MDI1Nn0.6-7DgP4UFcA7hEkK7XRob_sRNEGH1QlvalysDJjBrko
```


## References

[RFC-6749: The OAuth 2.0 Authorization Framework](https://www.rfc-editor.org/rfc/rfc6749)

[RFC-7009: OAuth 2.0 Token Revocation](https://datatracker.ietf.org/doc/html/rfc7009)
