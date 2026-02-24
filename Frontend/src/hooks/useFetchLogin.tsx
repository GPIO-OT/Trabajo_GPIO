import { useState } from "react"
import { LoginRequest, AuthResponse } from "../types/Auth"

export const useFecthLogin = () => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fecthLogin = async (credentials: LoginRequest): Promise<AuthResponse | null> => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch("http://localhost:5001/api/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
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