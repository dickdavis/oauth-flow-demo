# oauth-flow-demo

## System Design

### Authorization

Authorization is the process a client initiates to retrieve tokens for subsequent interactions with the application.

```mermaid
---
title: Authorization
---
sequenceDiagram
autonumber

actor Client
participant Authentication Service
participant Authorization Service
participant Data Layer
participant Token Issue Service

Client-->Client: Generates code verifier and code challenge
Client-->>Authorization Service: Calls the authorization endpoint with code challenge
Note right of Client: GET /authorize
Authorization Service-->Authorization Service: Encodes code challenge in state token
Authorization Service-->>Authentication Service: Redirects to sign-in page with state token
Authentication Service-->Authentication Service: Verifies user-supplied credentials
Authentication Service-->>Authorization Service: Redirects to callback endpoint with state token
Note left of Authentication Service: GET /callback
Authorization Service-->Authorization Service: Decodes state token
Authorization Service-->Authorization Service: Generates auth code
Authorization Service-->>Data Layer: Stores auth code and code challenge
Authorization Service-->>Client: Returns auth code to client
Client-->>Token Issue Service: Provides auth code and code verifier
Note right of Client: POST /token
Token Issue Service-->>Data Layer: Retrieves auth code and code challenge
Token Issue Service-->Token Issue Service: Verifies code verifier with code challenge
Token Issue Service-->Token Issue Service: Generates access and refresh tokens
Token Issue Service-->>Data Layer: Stores tokens in session data
Token Issue Service-->>Client: Returns access and refresh tokens to client
```

### Introspection

Introspection is the process a client initiates to retrieve user information associated with a token.

```mermaid
---
title: Introspection
---
sequenceDiagram
autonumber

actor Client
participant Introspection Service
participant Data Layer

Client-->>Introspection Service: Provides access token
Note right of Client: GET /introspect
Introspection Service-->>Data Layer: Retrieves session data
Introspection Service-->Introspection Service: Validates token
Introspection Service-->>Data Layer: Queries user information associated with token
Introspection Service-->>Client: Returns user information
```

### Refresh

Refresh is the process a client initiates to obtain new tokens for extending a user's access.

```mermaid
---
title: Refresh
---
sequenceDiagram
autonumber

actor Client
participant Refresh Service
participant Data Layer

Client-->>Refresh Service: Provides refresh token
Note right of Client: POST /refresh
Refresh Service-->>Data Layer: Retrieves session data
Refresh Service-->Refresh Service: Validates token
Refresh Service-->Refresh Service: Generates new token pair
Refresh Service-->>Data Layer: Stores tokens in session data
Refresh Service-->>Client: Provides newly-generated tokens
```

### Revocation

Revocation is the process initiated by a client for revoking tokens issued for a given user.

```mermaid
---
title: Revocation
---
sequenceDiagram
autonumber

actor Client
participant Revocation Service
participant Data Layer

Client-->>Revocation Service: Provides refresh token
Note right of Client: POST /revoke
Revocation Service-->>Data Layer: Retrieves session data
Revocation Service-->Revocation Service: Validates token
Revocation Service-->>Data Layer: Destroy session associated with token
Revocation Service-->>Client: Returns HTTP status code success
```

