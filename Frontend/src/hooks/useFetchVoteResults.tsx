import { useEffect, useState } from "react"
import { VoteResult } from "../types/VoteResults"

export const useFetchVoteResults = () => {
  const [data, setData] = useState<VoteResult[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchVoteResults = async () => {
      try {
        const res = await fetch("http://localhost:5001/api/results")

        if (!res.ok) {
          throw new Error("Error al obtener Resultado de Votos")
        }

        const json: VoteResult[] = await res.json()
        setData(json)
      } catch (err: any) {
        setError(err.message)
      } finally {
        setLoading(false)
      }
    }

    fetchVoteResults()
  }, [])

  return { data, loading, error }
}
