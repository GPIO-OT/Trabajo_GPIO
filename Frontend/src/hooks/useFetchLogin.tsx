import { useState } from "react"
import { LoginRequest, AuthResponse } from "../types/Auth"
import { apiHeaders, apiUrl } from "../api"

export const useFecthLogin = () => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fecthLogin = async (credentials: LoginRequest): Promise<AuthResponse | null> => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch(apiUrl("/login"), {
        method: "POST",
        headers: apiHeaders({
          "Content-Type": "application/json",
        }),
        body: JSON.stringify(credentials),
      })

      if (!res.ok) {
        throw new Error("Credenciales incorrectas")
      }

      const data: AuthResponse = await res.json()

      /*
      // Guardar tokens
      localStorage.setItem("accessToken", data.accessToken)
      localStorage.setItem("refreshToken", data.refreshToken)
      */

      return data
    } catch (err: any) {
      setError(err.message)
      return null
    } finally {
      setLoading(false)
    }
  }

  return { fecthLogin, loading, error }
}
