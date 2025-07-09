import type { LiveSocket } from 'phoenix_live_view'

declare global {
  interface Window {
    liveSocket?: LiveSocket | undefined
    liveReloadeliveSocketr?: unknown
  }
}
