# Calrizzler API

Backend API for **Calrizzler**, a scheduling and client-management application for service-based businesses.

The API handles authentication, accounts, users, clients, services, resources, appointments, scheduling rules, and authorization for the Calrizzler web and mobile applications.

## Tech Stack

- Ruby on Rails
- PostgreSQL
- JWT authentication
- RSpec
- ActiveRecord

## Features

### Authentication

Calrizzler uses JWT-based authentication.

Authenticated requests include a bearer token:

```http
Authorization: Bearer <token>
```

Core authentication endpoints include:

```text
POST /api/v1/login
GET  /api/v1/me
```

### Accounts and Users

Users belong to an account representing a business.

Supported roles:

- `owner`
- `staff`
- `read_only`

Authorization is enforced at the API level.

Owners can manage account-level settings and user roles. Staff users can perform normal scheduling operations within their permissions. Read-only users can view data without modifying it.

### Clients

Clients are scoped to an account and can be created and managed by authorized users.

Client records are used throughout appointments and notes.

### Services

Services represent work offered by the business.

A service can include information such as:

- title
- price
- duration

Appointments can contain multiple services.

### Resources

Resources represent the person, room, chair, station, or other resource required for an appointment.

Examples might include:

- stylist
- massage room
- conference room
- equipment

Resources allow Calrizzler to prevent conflicting reservations.

### Appointments

Appointments connect:

- a client
- a resource
- one or more services
- a scheduled time
- a duration
- a status

Supported appointment statuses include:

```text
scheduled
completed
canceled
```

Appointment duration can be calculated from the selected services or manually overridden.

### Scheduling Conflict Detection

Scheduled appointments reserve their resource for the duration of the appointment.

The API prevents overlapping appointments from being booked against the same resource.

A composite database index on:

```text
account_id
resource_id
scheduled_at
```

supports scheduling queries and conflict detection.

### Notes

Notes can be associated with clients and are scoped through the authenticated user's account.

### Dashboard

The dashboard endpoint provides data needed by the frontend applications to display account and scheduling information.

## API Structure

API controllers are versioned under:

```text
/api/v1
```

The application uses account-scoped queries so authenticated users cannot access records belonging to another business.

For example, resources such as clients, appointments, services, notes, and users are retrieved within the current account rather than globally.

## Error Responses

The API returns structured JSON errors so the web and mobile clients can display useful feedback.

Example validation response:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed.",
    "details": {
      "first_name": [
        "First name can't be blank"
      ]
    }
  }
}
```

Common error codes include:

```text
unauthorized
forbidden
not_found
bad_request
validation_failed
```

## Testing

The API uses RSpec.

Tests cover areas including:

- authentication
- authorization
- validation errors
- account isolation
- appointment scheduling
- resource conflicts
- dashboard behavior
- API request behavior

Run the test suite with:

```bash
bundle exec rspec
```

## Development

Install dependencies:

```bash
bundle install
```

Set up the database:

```bash
bin/rails db:create
bin/rails db:migrate
```

Start the API:

```bash
bin/rails server
```

The local API is typically available at:

```text
http://localhost:3000
```

## Project Structure

```text
app/
├── controllers/
│   └── api/
│       └── v1/
├── models/
└── serializers/

spec/
├── factories/
├── models/
└── requests/
```

## Current Development Priorities

Calrizzler is being developed incrementally around production readiness, scheduling, and business functionality.

Current areas of work include:

- API request coverage
- validation and error handling
- scheduling conflict detection
- timezone handling
- calendar improvements
- search
- reminders
- production hardening

Future business functionality includes invoicing, subscriptions, reporting, resource categories, and multi-user scheduling.
