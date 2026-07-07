// Money is stored in the backend as integer MINOR units (paise). Never do
// floating-point math on rupees — format from minor at the display edge only.
export function formatMoneyMinor(
  minor: number | null | undefined,
  currency = "INR"
): string {
  const value = (minor ?? 0) / 100;
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatNumber(n: number | null | undefined): string {
  return new Intl.NumberFormat("en-IN").format(n ?? 0);
}

export function formatDate(
  input: string | number | Date | null | undefined
): string {
  if (!input) return "—";
  const d = new Date(input);
  if (isNaN(d.getTime())) return "—";
  return d.toLocaleDateString("en-IN", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export function formatDateTime(
  input: string | number | Date | null | undefined
): string {
  if (!input) return "—";
  const d = new Date(input);
  if (isNaN(d.getTime())) return "—";
  return d.toLocaleString("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export function titleCase(s: string | null | undefined): string {
  if (!s) return "";
  return s
    .replace(/[_-]+/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}
