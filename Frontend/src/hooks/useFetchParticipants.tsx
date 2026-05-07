import { useEffect, useState } from "react"
import { Participant } from "../types/Participants"
import { apiHeaders, apiUrl } from "../api"

export const useParticipants = () => {
  const [data, setData] = useState<Participant[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchParticipants = async () => {
      try {
        const res = await fetch(apiUrl("/participants"), {
          headers: apiHeaders(),
        })

        if (!res.ok) {
          throw new Error("Error al obtener participantes")
        }

        const json: Participant[] = await res.json()
        setData(json)
      } catch (err: any) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    fetchParticipants()
  }, [])

  return { data, loading, error }
}
