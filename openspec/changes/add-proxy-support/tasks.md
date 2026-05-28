## 1. Proxy Detection Module

- [x] 1.1 Create `src/utils/proxy-detector.ts` module
- [x] 1.2 Implement environment variable detection (`ALL_PROXY`, `HTTP_PROXY`, `HTTPS_PROXY`)
- [x] 1.3 Implement common port scanning (7890, 7891, 1080, 10808)
- [x] 1.4 Implement macOS system proxy detection via `scutil --proxy`
- [x] 1.5 Add HTTP and SOCKS5 protocol support

## 2. Proxy Configuration

- [x] 2.1 Update `gitclone-config.json` schema to include `proxy` section
- [x] 2.2 Add `enabled`, `autoDetect`, `url` configuration options
- [x] 2.3 Implement config file loading and parsing
- [x] 2.4 Implement proxy configuration precedence logic

## 3. Proxy Health Check

- [x] 3.1 Create `src/utils/proxy-health-check.ts`
- [x] 3.2 Implement HTTP HEAD request with 3-second timeout
- [x] 3.3 Implement fallback to direct connection on failure
- [x] 3.4 Add warning logs for proxy unavailability

## 4. Git Clone Integration

- [x] 4.1 Modify `git clone` flow to apply proxy before operation
- [x] 4.2 Set `git config http.proxy` and `git config https.proxy`
- [x] 4.3 Handle cases where no proxy is available
- [x] 4.4 Add proxy information to clone output logs

## 5. Testing

- [x] 5.1 Add unit tests for proxy detection
- [x] 5.2 Add unit tests for proxy configuration
- [x] 5.3 Add integration test for git clone with proxy
