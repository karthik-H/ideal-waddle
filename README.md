# ideal-waddle

TypeScript ecommerce API. Accounts register and log in with a bearer token. Authenticated callers add products to the catalog; anyone can read them.

Accounts and products stay in memory and reset when the process stops. Passwords are stored as hashes and are never returned.

## Run

```bash
npm install
npm run dev
```

`npm run build` then `npm start` serves the compiled output. Set `PORT` (default `3000`) and `JWT_SECRET` (default is a local-only value).

## Endpoints

| Method | Path | Auth | Body |
| --- | --- | --- | --- |
| POST | `/auth/register` | no | `{ "email", "password" }` |
| POST | `/auth/login` | no | `{ "email", "password" }` |
| POST | `/products` | bearer token | `{ "name", "description", "price", "productCode" }` |
| GET | `/products` | no | |
| GET | `/products/:id` | no | |
| GET | `/health` | no | |

Each email can be registered once. Passwords must be 8–72 characters. `price` is a non-negative number with at most two decimal places. `productCode` is unique and uses letters, numbers, `_`, or `-`.

```bash
curl -s -X POST localhost:3000/auth/register \
  -H 'content-type: application/json' \
  -d '{"email":"ada@example.com","password":"correct-horse"}'

curl -s -X POST localhost:3000/products \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer TOKEN' \
  -d '{"name":"Notebook","description":"Ruled, 80 pages","price":12.99,"productCode":"NB-80"}'

curl -s localhost:3000/products
```
