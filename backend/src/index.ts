import { Hono } from 'hono'
import { cors } from 'hono/cors'

const app = new Hono()

// Simple In-Memory Rate Limiter
// Note: In a real production environment with multiple isolates, 
// this should use Cloudflare KV or Durable Objects.
const rateLimitMap = new Map<string, { count: number, lastReset: number }>()
const WINDOW_MS = 60 * 1000 // 1 minute
const LIMIT = 10

const rateLimiter = async (c: any, next: any) => {
    const ip = c.req.header('CF-Connecting-IP') || 'unknown'
    const now = Date.now()

    let record = rateLimitMap.get(ip)

    if (!record || (now - record.lastReset > WINDOW_MS)) {
        record = { count: 0, lastReset: now }
    }

    if (record.count >= LIMIT) {
        return c.json({ error: 'Too Many Requests' }, 429)
    }

    record.count++
    rateLimitMap.set(ip, record)

    await next()
}

// Middleware
app.use('/*', cors())
app.use('/api/*', rateLimiter)

// Root
app.get('/', (c) => c.text('Astr API Proxy is running!'))

// Weather Endpoint
app.get('/api/weather', async (c) => {
    const latitude = c.req.query('latitude')
    const longitude = c.req.query('longitude')

    if (!latitude || !longitude) {
        return c.json({ error: 'Missing latitude or longitude' }, 400)
    }

    // Pass through all query parameters to Open-Meteo
    // This allows the client to control fields (current_weather, hourly, etc.)
    const query = c.req.query()
    const params = new URLSearchParams(query as any).toString()

    const url = `https://api.open-meteo.com/v1/forecast?${params}`

    try {
        const response = await fetch(url, {
            headers: {
                'User-Agent': 'Astr-App/1.0 (https://astr.app)'
            }
        })
        if (!response.ok) {
            const text = await response.text()
            return c.json({ error: 'Upstream API error', status: response.status, details: text }, response.status as any)
        }
        const data = await response.json()
        return c.json(data)
    } catch (e) {
        return c.json({ error: 'Internal Server Error' }, 500)
    }
})

// Geocode Endpoint
app.get('/api/geocode', async (c) => {
    const q = c.req.query('q')
    if (!q) {
        return c.json({ error: 'Missing query parameter q' }, 400)
    }

    const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(q)}&count=10&language=en&format=json`

    try {
        const response = await fetch(url, {
            headers: {
                'User-Agent': 'Astr-App/1.0 (https://astr.app)'
            }
        })
        if (!response.ok) {
            return c.json({ error: 'Upstream API error' }, response.status as any)
        }
        const data = await response.json()
        return c.json(data)
    } catch (e) {
        return c.json({ error: 'Internal Server Error' }, 500)
    }
})

export default app
