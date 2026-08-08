import { tokenStorage } from "./tokenStorage";

const BASE_URL = import.meta.env.VITE_API_URL ?? "http://localhost:4000/api/v1";

export interface AuthTokens {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
  user_id: string;
  role: string;
  tier: string;
}

export class ApiError extends Error {
  status: number;
  code?: string;

  constructor(status: number, body: unknown) {
    const parsed = (body ?? {}) as { error?: string; message?: string };
    super(
      parsed.message ?? parsed.error ?? `Request failed with status ${status}`,
    );
    this.status = status;
    this.code = parsed.error;
  }
}

type QueryValue = string | number | boolean | undefined;
type Query = Record<string, QueryValue>;

interface RequestOptions {
  method?: string;
  body?: unknown;
  query?: Query;
  auth?: boolean;
}

function buildUrl(path: string, query?: Query): string {
  const url = `${BASE_URL}${path}`;
  if (!query) return url;

  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined) params.set(key, String(value));
  }
  const qs = params.toString();
  return qs ? `${url}?${qs}` : url;
}

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = tokenStorage.getRefreshToken();
  if (!refreshToken) return false;

  const response = await fetch(`${BASE_URL}/auth/refresh`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh_token: refreshToken }),
  });

  if (!response.ok) {
    tokenStorage.clear();
    return false;
  }

  const { data } = (await response.json()) as { data: AuthTokens };
  tokenStorage.setTokens(data.access_token, data.refresh_token);
  return true;
}

export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { method = "GET", body, query, auth = true } = options;

  const doFetch = async () => {
    const headers: Record<string, string> = {};
    if (body !== undefined) headers["Content-Type"] = "application/json";
    if (auth) {
      const token = tokenStorage.getAccessToken();
      if (token) headers["Authorization"] = `Bearer ${token}`;
    }

    return fetch(buildUrl(path, query), {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  };

  let response = await doFetch();

  if (response.status === 401 && auth && tokenStorage.getRefreshToken()) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      response = await doFetch();
    }
  }

  const isJson = response.headers
    .get("content-type")
    ?.includes("application/json");
  const payload = isJson ? await response.json() : null;

  if (!response.ok) {
    throw new ApiError(response.status, payload);
  }

  return payload as T;
}

export const apiGet = <T>(
  path: string,
  query?: Query,
  options?: Omit<RequestOptions, "method" | "query">,
) => apiRequest<T>(path, { ...options, method: "GET", query });

export const apiPost = <T>(
  path: string,
  body?: unknown,
  options?: Omit<RequestOptions, "method" | "body">,
) => apiRequest<T>(path, { ...options, method: "POST", body });

export const apiPut = <T>(
  path: string,
  body?: unknown,
  options?: Omit<RequestOptions, "method" | "body">,
) => apiRequest<T>(path, { ...options, method: "PUT", body });

export const apiDelete = <T>(
  path: string,
  options?: Omit<RequestOptions, "method">,
) => apiRequest<T>(path, { ...options, method: "DELETE" });
