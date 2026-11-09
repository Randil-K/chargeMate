# ChargeMate — Spring Boot REST API Specification

Base URL (Android Emulator): `http://10.0.2.2:8080/api`

All endpoints correspond 1:1 with [`lib/core/constants/api_endpoints.dart`](../lib/core/constants/api_endpoints.dart) and the `Api...RemoteDataSource` implementations across the Flutter modules.

---

## 1. Authentication & User Profile

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Public | Register a new driver account and return JWT access/refresh tokens |
| `POST` | `/auth/login` | Public | Authenticate with `email` & `password` and return JWT tokens + `UserModel` |
| `POST` | `/auth/refresh` | Public | Exchange `refreshToken` for a new `accessToken` |
| `POST` | `/auth/logout` | Bearer | Invalidate active refresh token |
| `GET` | `/users/profile` | Bearer | Fetch current authenticated user's profile |
| `PUT` | `/users/profile` | Bearer | Update `firstName`, `lastName`, and `phone` |

---

## 2. Charging Stations (`Module 2`)

| Method | Endpoint | Query Params | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/stations/nearby` | `lat`, `lng`, `radiusKm` | Returns stations ordered by PostGIS spherical distance (`ST_Distance`) |
| `GET` | `/stations/search` | `q`, `connector`, `minKw` | Search and filter stations by city, operator, connector, or power |
| `GET` | `/stations/{id}` | — | Full station details including `points` (`ChargingPoint[]`) |
| `GET` | `/stations/{id}/reviews` | — | List community reviews for a station |
| `POST` | `/stations/{id}/reviews` | — | Submit a star rating, comment, EV model badge, and status report |

---

## 3. Vehicle Management (`Module 3`)

| Method | Endpoint | Auth | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/vehicles` | Bearer | List all EVs registered by the current user |
| `POST` | `/vehicles` | Bearer | Register a new EV (`manufacturer`, `model`, `batteryKwh`, `connectors`) |
| `PUT` | `/vehicles/{id}` | Bearer | Update vehicle details or set as primary EV |
| `DELETE` | `/vehicles/{id}` | Bearer | Remove a registered vehicle |

---

## 4. Charge & Explore (`Module 4`)

| Method | Endpoint | Query Params | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/places/nearby` | `stationId`, `lat`, `lng`, `radiusM`, `category` | Discover cafés, dining, shopping, entertainment, and sights around a charger |
| `GET` | `/places/recommendations` | `stationId`, `chargingMinutes` | Returns places filtered and ranked where `(2 * walkingMinutes) + avgVisitMinutes <= chargingMinutes + 5` |
