import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import app from '../src/index'

describe('Astr Proxy', () => {
    beforeEach(() => {
        global.fetch = vi.fn()
    })

    afterEach(() => {
        vi.restoreAllMocks()
    })

    it('GET / returns 200', async () => {
        const res = await app.request('/')
        expect(res.status).toBe(200)
        expect(await res.text()).toBe('Astr API Proxy is running!')
    })

    it('GET /api/weather returns data from upstream', async () => {
        const mockData = { current_weather: { temperature: 20 } }
        vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(mockData), { status: 200 }))

        const res = await app.request('/api/weather?latitude=10&longitude=10')
        expect(res.status).toBe(200)
        expect(await res.json()).toEqual(mockData)

        expect(fetch).toHaveBeenCalledWith(expect.stringContaining('api.open-meteo.com/v1/forecast'))
    })

    it('GET /api/weather returns 400 if params missing', async () => {
        const res = await app.request('/api/weather')
        expect(res.status).toBe(400)
    })

    it('GET /api/geocode returns data from upstream', async () => {
        const mockData = { results: [] }
        vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(mockData), { status: 200 }))

        const res = await app.request('/api/geocode?q=London')
        expect(res.status).toBe(200)
        expect(await res.json()).toEqual(mockData)

        expect(fetch).toHaveBeenCalledWith(expect.stringContaining('geocoding-api.open-meteo.com/v1/search'))
    })

    it('Rate limiter returns 429 after limit exceeded', async () => {
        // Mock IP header
        const req = new Request('http://localhost/api/weather?latitude=0&longitude=0', {
            headers: { 'CF-Connecting-IP': '1.2.3.4' }
        })

        // Send 100 requests (Limit is 100)
        for (let i = 0; i < 10; i++) {
            vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({}), { status: 200 }))
            const res = await app.request(req.url, { headers: req.headers })
            expect(res.status).toBe(200)
        }

        // 11th request should fail
        const res = await app.request(req.url, { headers: req.headers })
        expect(res.status).toBe(429)
        expect(await res.json()).toEqual({ error: 'Too Many Requests' })
    })
})
