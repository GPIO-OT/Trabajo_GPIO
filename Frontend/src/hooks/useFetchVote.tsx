import { useState } from "react"
import { VoteInfo, RegisteredVoteInfo } from "../types/Votes"
import { apiHeaders, apiUrl } from "../api"

export const useFecthVote = () => {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fecthVote = async (vote: VoteInfo): Promise<RegisteredVoteInfo | null> => {
    setLoading(true)
    setError(null)

    try {
      const res = await fetch(apiUrl("/vote"), {
        method: "POST",
        headers: apiHeaders({
          "Content-Type": "application/json",
        }),
        body: JSON.stringify(vote),
      })

      if (!res.ok) {
        throw new Error("Voto no realizado")
      }

      const data: RegisteredVoteInfo = await res.json()

      return data
    } catch (err: any) {
      setError(err.message)
      return null
    } finally {
      setLoading(false)
    }
  }

  return { fecthVote, loading, error }
}
