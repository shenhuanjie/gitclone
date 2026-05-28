## ADDED Requirements

### Requirement: Configurable proxy settings
The system SHALL support user-defined proxy configuration via config file.

#### Scenario: Custom proxy URL in config
- **WHEN** user sets `"proxy": { "url": "http://127.0.0.1:8080" }` in config
- **THEN** system SHALL use `http://127.0.0.1:8080` as proxy

#### Scenario: Proxy disabled in config
- **WHEN** user sets `"proxy": { "enabled": false }` in config
- **THEN** system SHALL NOT use any proxy

#### Scenario: Auto-detect can be disabled
- **WHEN** user sets `"proxy": { "autoDetect": false }` with custom URL
- **THEN** system SHALL use the configured URL without auto-detection

### Requirement: Proxy configuration precedence
The system SHALL respect the following precedence for proxy settings:
1. Explicit config `proxy.url` (highest priority)
2. Environment variables
3. Auto-detected common ports
4. No proxy (lowest priority)

#### Scenario: Config URL overrides environment
- **WHEN** both config URL and environment variable are set
- **THEN** system SHALL use the config URL
