const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PRODUCT_CODE_PATTERN = /^[A-Za-z0-9_-]{1,64}$/;

export function normalizeEmail(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const email = value.trim().toLowerCase();
  if (!EMAIL_PATTERN.test(email) || email.length > 254) return null;
  return email;
}

export function readPassword(value: unknown): string | null {
  if (typeof value !== "string") return null;
  if (value.length < 8 || value.length > 72) return null;
  return value;
}

function readPrice(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) return null;
  const cents = Math.round(value * 100);
  if (Math.abs(value * 100 - cents) > 1e-6) return null;
  return cents / 100;
}

export function readProductInput(body: unknown):
  | {
      name: string;
      description: string;
      price: number;
      productCode: string;
    }
  | { error: string } {
  if (!body || typeof body !== "object") {
    return { error: "Request body must be a JSON object" };
  }
  const record = body as Record<string, unknown>;

  if (typeof record.name !== "string" || record.name.trim().length === 0 || record.name.length > 200) {
    return { error: "name is required (1-200 characters)" };
  }
  if (typeof record.description !== "string" || record.description.length > 2000) {
    return { error: "description must be a string up to 2000 characters" };
  }
  const price = readPrice(record.price);
  if (price === null) {
    return { error: "price must be a non-negative number with at most 2 decimal places" };
  }
  if (typeof record.productCode !== "string" || !PRODUCT_CODE_PATTERN.test(record.productCode)) {
    return { error: "productCode must be 1-64 characters: letters, numbers, _ or -" };
  }

  return {
    name: record.name.trim(),
    description: record.description,
    price,
    productCode: record.productCode,
  };
}
