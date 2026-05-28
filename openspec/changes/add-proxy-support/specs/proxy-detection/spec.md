## ADDED Requirements

### Requirement: Auto-detect system proxy
The system SHALL automatically detect available proxy settings from the following sources in priority order:
1. Environment variables `ALL_PROXY`, `HTTP_PROXY`, `HTTPS_PROXY`
2. Common proxy ports (7890, 7891, 1080, 10808)
3. macOS system proxy settings via `scutil --proxy`

#### Scenario: Detect proxy from environment variable
- **WHEN** environment variable `ALL_PROXY` is set to `http://127.0.0.1:7890`
- **THEN** system SHALL use `http://127.0.0.1:7890` as the proxy

#### Scenario: Detect proxy from HTTP_PROXY
- **WHEN** `HTTP_PROXY` is set but `ALL_PROXY` is not
- **THEN** system SHALL use `HTTP_PROXY` value for HTTP connections

#### Scenario: Detect Clash default port
- **WHEN** no environment proxy is set and port 7890 is open
- **THEN** system SHALL use `http://127.0.0.1:7890` as fallback proxy

#### Scenario: No proxy available
- **WHEN** no proxy is detected from any source
- **THEN** system SHALL proceed without proxy (direct connection)

### Requirement: Proxy type support
The system SHALL support HTTP and SOCKS5 proxy protocols.

#### Scenario: HTTP proxy detection
- **WHEN** proxy URL starts with `http://`
- **THEN** system SHALL configure git to use HTTP proxy

#### Scenario: SOCKS5 proxy detection
- **WHEN** proxy URL starts with `socks5://`
- **THEN** system SHALL configure git to use SOCKS5 proxy
