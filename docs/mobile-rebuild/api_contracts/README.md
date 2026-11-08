# Deal One — API Contracts Repository

**Source Origin:** Live Production Server (`one-deal-cjjt-production.up.railway.app`)  
**Extraction Date:** November 8, 2026  
**OpenAPI Specification:** Version 3.0.0  
**Backend Framework:** NestJS 10 / Fastify / TypeScript / Prisma  

---

## 1. Directory Contents

- **`production_openapi.json`:** The raw, unadulterated OpenAPI 3.0.0 specification fetched directly from `GET /api/docs-json`.
  - Total Endpoints: 61 operations
  - Total Components/Schemas: 24 DTO schemas
  - Global Security Scheme: `BearerAuth` (HTTP Bearer JWT)

---

## 2. Regeneration Procedure

To re-fetch and verify the contract snapshot without mutating production:

```bash
curl -s https://one-deal-cjjt-production.up.railway.app/api/docs-json > docs/mobile-rebuild/api_contracts/production_openapi.json
```

To validate the downloaded specification structure:
```bash
python3 -c "
import json
with open('docs/mobile-rebuild/api_contracts/production_openapi.json') as f:
    spec = json.load(f)
print('Title:', spec['info']['title'])
print('Paths count:', len(spec['paths']))
"
```

---

## 3. Wire Contract Governance Rules

1. **Strict Immutability:** Mobile DTOs and field types must mirror the properties, types, and constraints defined in `production_openapi.json`.
2. **Zero Field Invention:** Never invent query parameters, header names, or enum variants not present in this specification.
3. **Response Envelope Enforcement:** All successful responses (except raw health probes) are wrapped inside `{ success: true, data: T, meta?: Record<string, unknown> }`.
4. **Error Envelope Enforcement:** All error responses follow `{ success: false, error: { code: string, message: string, details?: unknown, trace_id: string } }`.
