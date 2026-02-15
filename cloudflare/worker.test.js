import { describe, it, expect, vi, beforeEach } from 'vitest';

// Import the worker module
import worker from './worker.js';

// ============================================================================
// Mock factories
// ============================================================================

function mockD1(rows) {
    return {
        prepare: vi.fn().mockReturnValue({
            bind: vi.fn().mockReturnValue({
                first: vi.fn().mockResolvedValue(rows),
            }),
            first: vi.fn().mockResolvedValue(rows),
        }),
    };
}

function mockD1Error(error) {
    return {
        prepare: vi.fn().mockReturnValue({
            bind: vi.fn().mockReturnValue({
                first: vi.fn().mockRejectedValue(new Error(error)),
            }),
            first: vi.fn().mockRejectedValue(new Error(error)),
        }),
    };
}

function mockR2(body, size) {
    return {
        get: vi.fn().mockResolvedValue(body ? { body, size } : null),
    };
}

function mockR2Error(error) {
    return {
        get: vi.fn().mockRejectedValue(new Error(error)),
    };
}

function makeRequest(path, method = 'GET') {
    return new Request(`https://worker.test${path}`, { method });
}

// ============================================================================
// Tests
// ============================================================================

describe('Cloudflare Worker', () => {
    describe('CORS', () => {
        it('returns CORS headers on OPTIONS preflight', async () => {
            const env = { DB: mockD1(null), ZONE_BUCKET: mockR2(null, 0) };
            const res = await worker.fetch(makeRequest('/zone/abc', 'OPTIONS'), env);

            expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
            expect(res.headers.get('Access-Control-Allow-Methods')).toContain('GET');
        });
    });

    describe('GET /zone/:h3hex', () => {
        it('returns zone data when found in D1', async () => {
            const row = { zone: 5, radiance: 0.456789, sqm: 19.876 };
            const env = { DB: mockD1(row), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/zone/8a2a1072b59ffff'), env);
            const body = await res.json();

            expect(res.status).toBe(200);
            expect(body.bortle).toBe(5);
            expect(body.ratio).toBe(0.46);   // rounded to 2 decimals
            expect(body.sqm).toBe(19.88);    // rounded to 2 decimals
            expect(body.h3).toBe('8a2a1072b59ffff');
        });

        it('returns implicit Zone 1 when not found in D1', async () => {
            const env = { DB: mockD1(null), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/zone/8a2a1072b59ffff'), env);
            const body = await res.json();

            expect(res.status).toBe(200);
            expect(body.bortle).toBe(1);
            expect(body.ratio).toBe(0.0);
            expect(body.sqm).toBe(22.0);
            expect(body.implicit).toBe(true);
        });

        it('returns 500 on D1 error', async () => {
            const env = { DB: mockD1Error('DB offline'), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/zone/abc123'), env);
            const body = await res.json();

            expect(res.status).toBe(500);
            expect(body.error).toBe('Internal server error');
        });

        it('handles Cache-Control header for found zones', async () => {
            const row = { zone: 3, radiance: 0.1, sqm: 21.0 };
            const env = { DB: mockD1(row), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/zone/abc'), env);

            expect(res.headers.get('Cache-Control')).toContain('max-age=3600');
        });

        it('normalises hex to lowercase before lookup', async () => {
            const row = { zone: 4, radiance: 0.5, sqm: 20.0 };
            const db = mockD1(row);
            const env = { DB: db, ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/zone/ABC123'), env);
            const body = await res.json();

            expect(body.h3).toBe('abc123');
        });
    });

    describe('GET /health', () => {
        it('returns ok with record count', async () => {
            const env = { DB: mockD1({ count: 42000 }), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/health'), env);
            const body = await res.json();

            expect(res.status).toBe(200);
            expect(body.status).toBe('ok');
            expect(body.records).toBe(42000);
        });

        it('returns 503 on D1 error', async () => {
            const env = { DB: mockD1Error('connection lost'), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/health'), env);
            const body = await res.json();

            expect(res.status).toBe(503);
            expect(body.status).toBe('error');
        });
    });

    describe('GET /stats', () => {
        it('returns records and backend type', async () => {
            const env = { DB: mockD1({ count: 100000 }), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/stats'), env);
            const body = await res.json();

            expect(res.status).toBe(200);
            expect(body.records).toBe(100000);
            expect(body.backend).toBe('d1');
        });

        it('returns 500 on D1 error', async () => {
            const env = { DB: mockD1Error('timeout'), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/stats'), env);

            expect(res.status).toBe(500);
        });
    });

    describe('GET /download', () => {
        it('streams zones.db from R2', async () => {
            const fileBody = new ReadableStream();
            const env = { DB: mockD1(null), ZONE_BUCKET: mockR2(fileBody, 1048576) };

            const res = await worker.fetch(makeRequest('/download'), env);

            expect(res.status).toBe(200);
            expect(res.headers.get('Content-Type')).toBe('application/octet-stream');
            expect(res.headers.get('Content-Length')).toBe('1048576');
            expect(res.headers.get('Content-Disposition')).toContain('zones.db');
        });

        it('returns 404 when zones.db not in R2', async () => {
            const env = { DB: mockD1(null), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/download'), env);
            const body = await res.json();

            expect(res.status).toBe(404);
            expect(body.error).toContain('not found');
        });

        it('returns 500 on R2 error', async () => {
            const env = { DB: mockD1(null), ZONE_BUCKET: mockR2Error('R2 unavailable') };

            const res = await worker.fetch(makeRequest('/download'), env);

            expect(res.status).toBe(500);
        });
    });

    describe('Unknown routes', () => {
        it('returns 404 for unknown paths', async () => {
            const env = { DB: mockD1(null), ZONE_BUCKET: mockR2(null, 0) };

            const res = await worker.fetch(makeRequest('/unknown'), env);
            const body = await res.json();

            expect(res.status).toBe(404);
            expect(body.error).toBe('Not Found');
        });
    });
});
