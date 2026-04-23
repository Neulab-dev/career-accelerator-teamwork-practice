# DynamoDB Module

Terraform module that provisions the DynamoDB table used by the Shortly URL shortener.

## Table: `{prefix}-shortly`

| Property      | Value           |
| ------------- | --------------- |
| Billing mode  | PAY_PER_REQUEST |
| Partition key | `hash` (String) |
| Sort key      | none            |
| GSIs / LSIs   | none            |

### Item Schema

| Attribute     | Type   | Key?          | Description                           |
| ------------- | ------ | ------------- | ------------------------------------- |
| `hash`        | String | Partition key | Short hash that identifies the URL    |
| `originalUrl` | String | -             | The full original URL being shortened |

## Access Patterns

### 1. Look up a URL by hash (read)

- **Operation:** `GetItem`
- **Key:** `hash`
- **Use case:** Collision detection before writing a new mapping, and redirect look-ups.

### 2. Create a new URL mapping (write)

- **Operation:** `PutItem`
- **Condition:** `attribute_not_exists(hash)`
- **Use case:** Persist a new `hash -> originalUrl` pair. The condition expression makes the write atomic — it fails if another process concurrently wrote the same hash, preventing silent overwrites.

## Inputs

| Name     | Type   | Description                                                         |
| -------- | ------ | ------------------------------------------------------------------- |
| `prefix` | string | Environment prefix prepended to the table name (e.g. `dev`, `prod`) |

## Outputs

| Name        | Description               |
| ----------- | ------------------------- |
| `table_arn` | ARN of the DynamoDB table |
