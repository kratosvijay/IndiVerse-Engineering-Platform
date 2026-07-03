# API Contract: [Endpoint Name]

- **Method**: [GET / POST / PUT / DELETE]
- **Path**: `/api/v1/resource`
- **Auth Required**: [Yes/No]

## 📥 Request Parameters

### Headers
```json
{
  "Authorization": "Bearer <token>"
}
```

### Body
```json
{
  "param1": "value1"
}
```

## 📤 Response Payloads

### HTTP 200 OK (Success)
```json
{
  "success": true,
  "data": {}
}
```

### HTTP 400 Bad Request (Error)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_PARAMETERS",
    "message": "Required fields are missing"
  }
}
```
