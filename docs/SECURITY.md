# Tide Security Documentation

## API Authentication (Port 9051)

### Overview

The Tide API server provides both **read-only** and **write** operations. As of v1.2, write operations require Bearer token authentication to prevent unauthorized circuit manipulation.

### Endpoints

#### Public (No Authentication Required)

- `GET /status` - Gateway status information
- `GET /circuit` - Current Tor exit IP
- `GET /check` - Verify Tor connectivity
- `GET /discover` - Service discovery
- `GET /token` - Retrieve API token

#### Protected (Bearer Token Required)

- `GET /newcircuit` - Request new Tor circuit

### How It Works

1. **Token Generation**
   - On first startup, the gateway generates a secure random token (43 characters)
   - Token is saved to `/etc/tide/api_token` with 0600 permissions
   - Token persists across restarts

2. **Token Retrieval**
   - Clients fetch token from `GET /token` endpoint
   - Alternatively, set `TIDE_API_TOKEN` environment variable

3. **Making Authenticated Requests**
   ```bash
   # Get token
   TOKEN=$(curl -s http://10.101.101.10:9051/token | jq -r .token)
   
   # Use token
   curl -H "Authorization: Bearer $TOKEN" \
        http://10.101.101.10:9051/newcircuit
   ```

### Threat Model

#### Assumptions

- **Trusted Network**: Clients are on a trusted Docker/VM network
- **No Public Exposure**: API port 9051 is NOT exposed to the internet
- **Physical Security**: Host machine is physically secure

#### Risks Mitigated

✅ **Unauthorized Circuit Manipulation**
- Attackers on the network cannot force circuit changes
- Prevents DoS via circuit spam
- Reduces correlation attack surface

✅ **Rate Limiting** (Future)
- Token enables per-client rate limiting
- Can revoke/rotate tokens if abused

#### Remaining Risks

⚠️ **Information Disclosure**
- `/status` and `/circuit` still expose operational info
- Anyone on network can see Tor exit IPs
- **Mitigation**: Keep gateway on isolated network segment

⚠️ **Token Exposure**
- Token is transmitted in plaintext HTTP
- Anyone sniffing the network can capture tokens
- **Mitigation**: Use for lab/testing only, or add TLS for production

⚠️ **No Rate Limiting**
- Authenticated clients can still spam `/newcircuit`
- **Future Enhancement**: Add rate limiting per token

### Deployment Modes

#### Lab/Testing (Current)
```bash
# No special configuration needed
docker-compose up -d
```

#### Production (Recommended)
```bash
# Set custom token
export TIDE_API_TOKEN="your-custom-secure-token-here"
docker-compose up -d

# Or use .env file
echo "TIDE_API_TOKEN=your-token" >> .env
```

#### High Security
```bash
# Disable token endpoint (manual token distribution)
# Remove /token endpoint from API server
# Clients must set TIDE_API_TOKEN environment variable
```

### Best Practices

1. **Never expose port 9051 to the internet**
   ```bash
   # BAD - exposes API publicly
   docker run -p 9051:9051 tide-gateway
   
   # GOOD - internal network only
   docker run --network tide_tidenet tide-gateway
   ```

2. **Rotate tokens periodically**
   ```bash
   # Generate new token
   docker exec tide-gateway sh -c 'python3 -c "import secrets; print(secrets.token_urlsafe(32))" > /etc/tide/api_token'
   docker restart tide-gateway
   ```

3. **Use environment variables for tokens**
   ```bash
   # Client machines
   export TIDE_API_TOKEN="token-from-gateway"
   ```

4. **Monitor API access**
   ```bash
   # Check gateway logs for unauthorized attempts
   docker logs tide-gateway | grep "unauthorized"
   ```

### Future Enhancements

- [ ] TLS/HTTPS support for encrypted token transmission
- [ ] Per-client token generation with revocation
- [ ] Rate limiting on authenticated endpoints
- [ ] Audit logging of circuit changes
- [ ] Optional IP-based ACLs
- [ ] mTLS for client authentication

### Security Audit

Last reviewed: 2025-12-09  
Reviewer: OpenCode AI Agent  
Risk Level: **MEDIUM** (acceptable for lab/testing, requires hardening for production)

### Reporting Vulnerabilities

For security issues, please open a GitHub issue or contact the maintainers directly.

---

**Tide Project**: https://github.com/bodegga/tide  
**License**: MIT
