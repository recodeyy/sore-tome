# SERO Separate Role Login — Frontend/Backend API Contract

This document outlines the API request and response JSON payloads for all separate portal login capabilities.

## 1. Authentication Login (`POST /api/v1/auth/login`)

### Request Payload
```json
{
  "loginIdentifier": "admin@sero.com", // email, phone, or employee ID
  "password": "SecurePassword123",
  "portal": "admin" // super-admin | admin | staff | resident
}
```

### Response Payload: Single Workspace Destination
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOi...",
    "refreshToken": "7c8e9f...",
    "firebaseToken": "eyJhbGciOi...", // custom token for Firestore
    "user": {
      "id": "u-9912",
      "name": "Arjun Sharma",
      "email": "arjun@sero.com",
      "phone": "+919876543210"
    },
    "requiresWorkspaceSelection": false,
    "activeWorkspace": {
      "id": "ws-admin-1",
      "type": "admin",
      "societyId": "soc-4402",
      "societyName": "Green Heights",
      "role": "secretary",
      "unit": null,
      "permissions": ["notice.post", "member.approve", "complaint.assign"]
    }
  }
}
```

### Response Payload: Multiple Workspace Destinations
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOi...",
    "refreshToken": "7c8e9f...",
    "user": {
      "id": "u-9912",
      "name": "Arjun Sharma",
      "email": "arjun@sero.com",
      "phone": "+919876543210"
    },
    "requiresWorkspaceSelection": true,
    "destinations": [
      {
        "workspaceId": "ws-res-1",
        "type": "resident",
        "societyId": "soc-4402",
        "societyName": "Green Heights",
        "role": "resident_owner",
        "unit": "A-1204",
        "status": "approved"
      },
      {
        "workspaceId": "ws-admin-1",
        "type": "admin",
        "societyId": "soc-4402",
        "societyName": "Green Heights",
        "role": "secretary",
        "unit": null,
        "status": "approved"
      }
    ]
  }
}
```

### Response: Portal Mismatch (HTTP 403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "PORTAL_MISMATCH",
    "message": "This account does not have access to the Society Admin portal.",
    "allowedPortals": ["resident"]
  }
}
```

---

## 2. Workspace Selection (`POST /api/v1/auth/workspace/select`)

### Request Payload
```json
{
  "workspaceId": "ws-admin-1"
}
```

### Response Payload
```json
{
  "success": true,
  "data": {
    "token": "new-scoped-jwt-token",
    "refreshToken": "new-scoped-refresh-token",
    "firebaseToken": "new-scoped-firebase-token",
    "activeWorkspace": {
      "id": "ws-admin-1",
      "type": "admin",
      "societyId": "soc-4402",
      "societyName": "Green Heights",
      "role": "secretary",
      "unit": null,
      "permissions": ["notice.post", "member.approve"]
    }
  }
}
```

---

## 3. Account Suspended / Inactive (HTTP 403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "ACCOUNT_SUSPENDED",
    "message": "Your society membership has been suspended. Please contact the society admin.",
    "supportContact": "+91-80-4567-8910"
  }
}
```
