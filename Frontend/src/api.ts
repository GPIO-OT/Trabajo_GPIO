const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || "/api"
const API_KEY = process.env.REACT_APP_API_KEY || "gpio-api-key-2026"

export const apiUrl = (path: string) => `${API_BASE_URL}${path}`

export const apiHeaders = (headers?: HeadersInit): HeadersInit => ({
  "x-api-key": API_KEY,
  ...headers,
})
