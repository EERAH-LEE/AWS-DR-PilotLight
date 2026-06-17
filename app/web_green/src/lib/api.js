export const PRODUCT_IMAGE_FALLBACK = "/assets/img/product-fallback.svg";

const defaultBaseUrl = import.meta.env.VITE_API_BASE_URL || "";

export function getApiBaseUrl() {
  const storedBaseUrl = localStorage.getItem("kbeautyApiBaseUrl");
  const baseUrl = defaultBaseUrl === "/canary" && (!storedBaseUrl || storedBaseUrl === "/") ? defaultBaseUrl : storedBaseUrl || defaultBaseUrl;
  return baseUrl.replace(/\/$/, "");
}

export function setApiBaseUrl(baseUrl) {
  localStorage.setItem("kbeautyApiBaseUrl", baseUrl.replace(/\/$/, ""));
}

export async function apiFetch(path, options = {}) {
  const response = await fetch(`${getApiBaseUrl()}${path}`, {
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
    ...options,
  });

  if (!response.ok) {
    throw new Error(`API ${response.status}: ${response.statusText}`);
  }

  if (response.status === 204) return null;
  return response.json();
}

export function toNumber(value) {
  if (typeof value === "number") return value;
  if (value == null) return 0;
  return Number(value);
}

export function getCurrentPrice(product) {
  if (product.currentPrice != null) return Math.floor(toNumber(product.currentPrice));
  const originalPrice = toNumber(product.originalPrice);
  const discountRate = toNumber(product.discountRate);
  return Math.floor(originalPrice * (1 - discountRate / 100));
}

export function formatWon(value) {
  return `${Math.floor(toNumber(value)).toLocaleString("ko-KR")}원`;
}

export function getStoredUser() {
  const raw = localStorage.getItem("kbeautyUser");
  return raw ? JSON.parse(raw) : null;
}

export function setStoredUser(user) {
  localStorage.setItem("kbeautyUser", JSON.stringify(user));
}

export function clearStoredUser() {
  localStorage.removeItem("kbeautyUser");
}

export function getStoredInquiries() {
  return JSON.parse(localStorage.getItem("kbeautyInquiries") || "[]");
}

export function addStoredInquiry(inquiry) {
  const next = [inquiry, ...getStoredInquiries()];
  localStorage.setItem("kbeautyInquiries", JSON.stringify(next));
  return next;
}

export function formatDateTime(value) {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("ko-KR");
}
