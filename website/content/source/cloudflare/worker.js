/**
 * Cloudflare Worker for ASTR Zone API
 * 
 * Serves zone data from Cloudflare D1 (SQLite) database.
 * Fallback zones.db download served from R2 for offline mode.
 * 
 * API:
 *   GET /zone/{h3_index_hex}  → { bortle, ratio, sqm } or implicit Zone 1
 *   GET /health               → { status: "ok", records: N }
 *   GET /stats                → { records, version }
 *   GET /download             → streams zones.db from R2 (for offline mode)
 * 
 * wrangler.toml bindings:
 *   DB          → D1 database "astr-zones-db"
 *   ZONE_BUCKET → R2 bucket "astr-zones" (for /download endpoint)
 */

// Cache zone data for 1 hour (it's static satellite data)
const CACHE_TTL = 3600;

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
};

function jsonResponse(data, status = 200, extraHeaders = {}) {
    return new Response(JSON.stringify(data), {
        status,
        headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            ...extraHeaders,
        },
    });
}

export default {
    async fetch(request, env) {
        const url = new URL(request.url);
        const path = url.pathname;

        // CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        // Route: GET /zone/{h3_hex}
        const zoneMatch = path.match(/^\/zone\/([0-9a-fA-F]+)$/);
        if (zoneMatch) {
            const h3Hex = zoneMatch[1].toLowerCase();
            return handleZoneLookup(h3Hex, env);
        }

        // Route: GET /health
        if (path === '/health') {
            return handleHealth(env);
        }

        // Route: GET /stats
        if (path === '/stats') {
            return handleStats(env);
        }

        // Route: GET /download — stream zones.db from R2 for offline mode
        if (path === '/download') {
            return handleDownload(env);
        }

        return jsonResponse({ error: 'Not Found' }, 404);
    },
};


// ============================================================================
// Route Handlers
// ============================================================================

/**
 * Look up zone data for a given H3 hex index.
 * 
 * D1 table schema:
 *   zones(h3 INTEGER PRIMARY KEY, zone INTEGER, radiance REAL, sqm REAL)
 * 
 * "h3" is stored as a signed 64-bit integer (SQLite INTEGER).
 * We convert the hex string to a BigInt, then to a signed int for SQL.
 */
async function handleZoneLookup(h3Hex, env) {
    try {
        // Convert hex to BigInt, then to signed 64-bit for D1 (SQLite stores signed)
        const h3BigInt = BigInt('0x' + h3Hex);

        // Convert unsigned to signed 64-bit representation
        const h3Signed = toSigned64(h3BigInt);

        const row = await env.DB.prepare(
            'SELECT zone, radiance, sqm FROM zones WHERE h3 = ?'
        ).bind(h3Signed.toString()).first();

        if (row) {
            return jsonResponse({
                bortle: row.zone,
                ratio: Math.round(row.radiance * 100) / 100,
                sqm: Math.round(row.sqm * 100) / 100,
                h3: h3Hex,
            }, 200, {
                'Cache-Control': `public, max-age=${CACHE_TTL}`,
            });
        }

        // Not found → Zone 1 (pristine dark sky)
        return jsonResponse({
            bortle: 1,
            ratio: 0.0,
            sqm: 22.0,
            h3: h3Hex,
            implicit: true,
        }, 200, {
            'Cache-Control': `public, max-age=${CACHE_TTL}`,
        });

    } catch (error) {
        console.error('Zone lookup error:', error);
        return jsonResponse({ error: 'Internal server error' }, 500);
    }
}


async function handleHealth(env) {
    try {
        const result = await env.DB.prepare(
            'SELECT count(*) as count FROM zones'
        ).first();

        return jsonResponse({
            status: 'ok',
            records: result?.count ?? 0,
        });
    } catch (e) {
        return jsonResponse({ status: 'error', message: e.message }, 503);
    }
}


async function handleStats(env) {
    try {
        const result = await env.DB.prepare(
            'SELECT count(*) as count FROM zones'
        ).first();

        return jsonResponse({
            records: result?.count ?? 0,
            backend: 'd1',
        });
    } catch (e) {
        return jsonResponse({ error: e.message }, 500);
    }
}


/**
 * Stream zones.db from R2 for offline download.
 * 
 * Sends the file with Content-Length header so clients can show progress.
 * Uses R2's streaming response to avoid loading the full file into memory.
 */
async function handleDownload(env) {
    try {
        const obj = await env.ZONE_BUCKET.get('zones.db');

        if (!obj) {
            return jsonResponse({ error: 'zones.db not found in R2' }, 404);
        }

        return new Response(obj.body, {
            headers: {
                ...corsHeaders,
                'Content-Type': 'application/octet-stream',
                'Content-Length': obj.size.toString(),
                'Content-Disposition': 'attachment; filename="zones.db"',
            },
        });
    } catch (e) {
        console.error('Download error:', e);
        return jsonResponse({ error: 'Download failed' }, 500);
    }
}


// ============================================================================
// Helpers
// ============================================================================

/**
 * Convert an unsigned 64-bit BigInt to signed 64-bit representation.
 * 
 * SQLite/D1 stores INTEGER as signed. H3 indices use the full unsigned
 * 64-bit range, so values with the high bit set appear negative in SQL.
 */
function toSigned64(unsigned) {
    const MAX_UINT64 = (1n << 64n) - 1n;
    const MAX_INT64 = (1n << 63n) - 1n;

    if (unsigned > MAX_UINT64) {
        throw new Error('Value exceeds uint64 range');
    }

    if (unsigned > MAX_INT64) {
        // High bit set → negative in signed representation
        return unsigned - (1n << 64n);
    }

    return unsigned;
}
