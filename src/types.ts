export type User = {
  id: string;
  email: string;
  passwordHash: string;
  createdAt: string;
};

export type PublicUser = {
  id: string;
  email: string;
  createdAt: string;
};

export type Product = {
  id: string;
  name: string;
  description: string;
  price: number;
  productCode: string;
  createdAt: string;
};

export type AuthTokenPayload = {
  sub: string;
  email: string;
};
