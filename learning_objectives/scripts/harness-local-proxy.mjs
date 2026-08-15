#!/usr/bin/env node
import fs from 'node:fs';
import http from 'node:http';
import https from 'node:https';
import net from 'node:net';
import { URL } from 'node:url';

function fail(
  message,
  code = 'LOCAL_ROUTING/INVALID_INPUT',
  fix = 'Fix the local routing config or command arguments, then rerun the gate.',
  sample = 'templates/local-routing.yml',
) {
  console.error(`FAIL: ${message}`);
  console.error(`CODE: ${code}`);
  console.error(`FIX: ${fix}`);
  console.error(`SAMPLE: ${sample}`);
  process.exit(1);
}

function expandEnvVars(value) {
  return value.replace(/\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/g, (match, name) => {
    if (Object.prototype.hasOwnProperty.call(process.env, name)) {
      return process.env[name];
    }
    fail(`environment variable ${name} is required by local routing config`);
  });
}

function cleanValue(value) {
  const trimmed = value.trim();
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return expandEnvVars(trimmed.slice(1, -1));
  }
  return expandEnvVars(trimmed);
}

function parseConfig(path) {
  const content = fs.readFileSync(path, 'utf8');
  const config = { proxy_listen: {}, routes: [] };
  let section = null;
  let currentRoute = null;

  for (const rawLine of content.split(/\r?\n/)) {
    if (rawLine.trim().startsWith('#')) continue;
    const withoutComment = rawLine.replace(/\s+#.*$/, '');
    if (!withoutComment.trim()) continue;

    const top = withoutComment.match(/^([A-Za-z0-9_]+):(?:\s*(.*))?$/);
    if (top) {
      const [, key, value = ''] = top;
      section = key;
      if (key !== 'routes' && key !== 'proxy_listen') {
        config[key] = cleanValue(value);
      }
      continue;
    }

    const proxyValue = withoutComment.match(/^  ([A-Za-z0-9_]+):\s*(.*)$/);
    if (section === 'proxy_listen' && proxyValue) {
      config.proxy_listen[proxyValue[1]] = cleanValue(proxyValue[2]);
      continue;
    }

    const routeStart = withoutComment.match(/^  - ([A-Za-z0-9_]+):\s*(.*)$/);
    if (section === 'routes' && routeStart) {
      currentRoute = {};
      currentRoute[routeStart[1]] = cleanValue(routeStart[2]);
      config.routes.push(currentRoute);
      continue;
    }

    const routeValue = withoutComment.match(/^    ([A-Za-z0-9_]+):\s*(.*)$/);
    if (section === 'routes' && currentRoute && routeValue) {
      currentRoute[routeValue[1]] = cleanValue(routeValue[2]);
      continue;
    }

    fail(`unsupported local-routing.yml line: ${rawLine}`);
  }

  return config;
}

function isLocalTarget(value) {
  try {
    const url = new URL(value);
    return (
      url.protocol === 'http:' &&
      ['localhost', '127.0.0.1', '::1', '[::1]'].includes(url.hostname)
    );
  } catch {
    return false;
  }
}

function validateConfig(config, path) {
  const errors = [];
  for (const key of ['change_id', 'frontend_repo', 'fallback_base_url']) {
    if (!config[key] || config[key].startsWith('<')) {
      errors.push(`missing or placeholder top-level key: ${key}`);
    }
  }

  try {
    const fallback = new URL(config.fallback_base_url || '');
    if (!['http:', 'https:'].includes(fallback.protocol)) {
      errors.push('fallback_base_url must use http or https');
    }
  } catch {
    errors.push('fallback_base_url must be a valid URL');
  }

  if (!Array.isArray(config.routes) || config.routes.length === 0) {
    errors.push('routes must contain at least one local service route');
  }

  const prefixes = new Set();
  config.routes.forEach((route, index) => {
    const label = route.id || `route[${index}]`;
    const isMockRoute = Object.prototype.hasOwnProperty.call(route, 'mock_response');
    for (const key of ['id', 'frontend_prefix', 'source_contract', 'reason']) {
      if (!route[key] || route[key].startsWith('<')) {
        errors.push(`${label}: missing or placeholder key ${key}`);
      }
    }
    if (!isMockRoute) {
      for (const key of ['strip_prefix', 'backend_prefix', 'backend_repo', 'local_target']) {
        if (!route[key] || route[key].startsWith('<')) {
          errors.push(`${label}: missing or placeholder key ${key}`);
        }
      }
    }

    if (route.frontend_prefix === '/' || route.frontend_prefix === '/*') {
      errors.push(`${label}: frontend_prefix must not be catch-all`);
    }
    if (route.frontend_prefix?.includes('*')) {
      errors.push(`${label}: frontend_prefix must not contain wildcard`);
    }
    if (!route.frontend_prefix?.startsWith('/')) {
      errors.push(`${label}: frontend_prefix must start with /`);
    }
    if (!isMockRoute && !route.strip_prefix?.startsWith('/')) {
      errors.push(`${label}: strip_prefix must start with /`);
    }
    if (
      !isMockRoute &&
      route.frontend_prefix &&
      route.strip_prefix &&
      !route.frontend_prefix.startsWith(route.strip_prefix)
    ) {
      errors.push(`${label}: frontend_prefix must start with strip_prefix`);
    }
    if (!isMockRoute && !route.backend_prefix?.startsWith('/')) {
      errors.push(`${label}: backend_prefix must start with /`);
    }
    if (!isMockRoute && !isLocalTarget(route.local_target || '')) {
      errors.push(`${label}: local_target must be an http localhost URL`);
    }
    if (isMockRoute) {
      try {
        JSON.parse(route.mock_response);
      } catch {
        errors.push(`${label}: mock_response must be valid JSON`);
      }
    }
    if ((route.reason || '').length < 12) {
      errors.push(`${label}: reason must explain why this route is in scope`);
    }
    if (prefixes.has(route.frontend_prefix)) {
      errors.push(`${label}: duplicate frontend_prefix ${route.frontend_prefix}`);
    }
    prefixes.add(route.frontend_prefix);
  });

  if (errors.length > 0) {
    console.error(`FAIL: invalid local routing config: ${path}`);
    console.error('CODE: LOCAL_ROUTING/INVALID_CONFIG');
    console.error('FIX: Use narrow frontend_prefix routes, localhost local_target values, and contract-backed reasons for each active backend route.');
    console.error('SAMPLE: templates/local-routing.yml');
    errors.forEach((error) => console.error(` - ${error}`));
    process.exit(1);
  }

  return config;
}

function joinPath(prefix, suffix) {
  const safePrefix = prefix.endsWith('/') ? prefix.slice(0, -1) : prefix;
  const safeSuffix = suffix.startsWith('/') ? suffix : `/${suffix}`;
  const joined = `${safePrefix}${safeSuffix}`;
  return joined === '' ? '/' : joined;
}

function routeMatches(route, pathname) {
  const prefix = route.frontend_prefix;
  return pathname === prefix || pathname.startsWith(`${prefix}/`);
}

function resolveTarget(config, incomingUrl) {
  const incoming = new URL(incomingUrl, 'http://harness.local');
  const route = [...config.routes]
    .sort((a, b) => b.frontend_prefix.length - a.frontend_prefix.length)
    .find((candidate) => routeMatches(candidate, incoming.pathname));

  if (!route) {
    if (/^https?:\/\//i.test(incomingUrl)) {
      return {
        type: 'passthrough',
        target: new URL(incomingUrl),
      };
    }
    return {
      type: 'fallback',
      target: new URL(`${incoming.pathname}${incoming.search}`, config.fallback_base_url),
    };
  }

  if (Object.prototype.hasOwnProperty.call(route, 'mock_response')) {
    return {
      type: 'mock',
      route,
      response: JSON.parse(route.mock_response),
    };
  }

  const remainder = incoming.pathname.slice(route.strip_prefix.length) || '/';
  const targetPath = joinPath(route.backend_prefix, remainder);
  return {
    type: 'local',
    route,
    target: new URL(`${targetPath}${incoming.search}`, route.local_target),
  };
}

function logLine(config, event) {
  const redactForLog = (value) =>
    String(value)
      .replace(/\b1[3-9]\d{9}\b/g, '<ACCOUNT_ID>')
      .replace(
        /((?:password|token|authorization|credential|securitytoken)(?:=|%3D))[^&\s"]+/gi,
        '$1<REDACTED>',
      );
  const sanitizedEvent = Object.fromEntries(
    Object.entries(event).map(([key, value]) => [
      key,
      typeof value === 'string' ? redactForLog(value) : value,
    ]),
  );
  const line = JSON.stringify({
    time: new Date().toISOString(),
    change_id: config.change_id,
    ...sanitizedEvent,
  });
  console.log(line);
  if (process.env.SFA_HARNESS_PROXY_LOG) {
    fs.appendFileSync(process.env.SFA_HARNESS_PROXY_LOG, `${line}\n`);
  }
}

function appendVary(existing, values) {
  const current = String(existing || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  for (const value of values) {
    if (!current.some((item) => item.toLowerCase() === value.toLowerCase())) {
      current.push(value);
    }
  }
  return current.join(', ');
}

function withCorsHeaders(clientReq, baseHeaders = {}) {
  const origin = clientReq.headers.origin;
  if (!origin) return baseHeaders;

  const headers = { ...baseHeaders };
  const corsHeaderNames = new Set([
    'access-control-allow-origin',
    'access-control-allow-credentials',
    'access-control-allow-methods',
    'access-control-allow-headers',
    'access-control-expose-headers',
  ]);

  for (const key of Object.keys(headers)) {
    if (corsHeaderNames.has(key.toLowerCase())) {
      delete headers[key];
    }
  }

  headers['access-control-allow-origin'] = origin;
  headers['access-control-allow-credentials'] = 'true';
  headers['access-control-allow-methods'] = 'GET,POST,PUT,PATCH,DELETE,OPTIONS';
  headers['access-control-allow-headers'] =
    clientReq.headers['access-control-request-headers'] ||
    'authorization,content-type,x-requested-with,ww-timezone,ww-language,ww-region,channel,organizationtype,positiontypeid,businessgroup';
  headers['access-control-expose-headers'] = 'authorization,content-type,x-auth-token,x-total-count';
  headers.vary = appendVary(headers.vary, [
    'Origin',
    'Access-Control-Request-Method',
    'Access-Control-Request-Headers',
  ]);
  return headers;
}

function startProxy(config) {
  const host = process.env.SFA_HARNESS_PROXY_HOST || config.proxy_listen.host || '127.0.0.1';
  const port = Number(process.env.SFA_HARNESS_PROXY_PORT || config.proxy_listen.port || 19080);

  const server = http.createServer((clientReq, clientRes) => {
    const resolved = resolveTarget(config, clientReq.url || '/');
    const target = resolved.target;
    const transport = target?.protocol === 'https:' ? https : http;
    const headers = target ? { ...clientReq.headers, host: target.host } : { ...clientReq.headers };

    logLine(config, {
      method: clientReq.method,
      incoming_path: clientReq.url,
      route_type: resolved.type,
      route_id: resolved.route?.id || null,
      target: target ? `${target.protocol}//${target.host}${target.pathname}` : null,
    });

    if (clientReq.method === 'OPTIONS' && clientReq.headers.origin) {
      clientRes.writeHead(204, withCorsHeaders(clientReq));
      clientRes.end();
      return;
    }

    if (resolved.type === 'mock') {
      clientRes.writeHead(200, withCorsHeaders(clientReq, { 'content-type': 'application/json' }));
      clientRes.end(JSON.stringify(resolved.response));
      return;
    }

    const upstream = transport.request(
      target,
      {
        method: clientReq.method,
        headers,
      },
      (upstreamRes) => {
        clientRes.writeHead(
          upstreamRes.statusCode || 502,
          withCorsHeaders(clientReq, upstreamRes.headers),
        );
        upstreamRes.pipe(clientRes);
      },
    );

    upstream.on('error', (error) => {
      clientRes.writeHead(
        502,
        withCorsHeaders(clientReq, { 'content-type': 'application/json' }),
      );
      clientRes.end(JSON.stringify({ code: 'HARNESS_PROXY_ERROR', message: error.message }));
    });

    clientReq.pipe(upstream);
  });

  server.on('connect', (clientReq, clientSocket, head) => {
    const [hostname, rawPort] = String(clientReq.url || '').split(':');
    const port = Number(rawPort || 443);

    if (!hostname || !Number.isInteger(port) || port <= 0) {
      clientSocket.write('HTTP/1.1 400 Bad Request\r\n\r\n');
      clientSocket.destroy();
      return;
    }

    logLine(config, {
      method: 'CONNECT',
      incoming_path: clientReq.url,
      route_type: 'tunnel',
      route_id: null,
      target: `${hostname}:${port}`,
    });

    const upstreamSocket = net.connect(port, hostname, () => {
      clientSocket.write('HTTP/1.1 200 Connection Established\r\n\r\n');
      if (head?.length) upstreamSocket.write(head);
      upstreamSocket.pipe(clientSocket);
      clientSocket.pipe(upstreamSocket);
    });

    upstreamSocket.on('error', (error) => {
      logLine(config, {
        method: 'CONNECT',
        incoming_path: clientReq.url,
        route_type: 'tunnel_error',
        route_id: null,
        target: `${hostname}:${port}`,
        error: error.message,
      });
      clientSocket.write('HTTP/1.1 502 Bad Gateway\r\n\r\n');
      clientSocket.destroy();
    });
  });

  server.listen(port, host, () => {
    console.error(`PASS: harness local proxy listening on http://${host}:${port}`);
    console.error(`INFO: fallback_base_url=${config.fallback_base_url}`);
  });
}

const args = process.argv.slice(2);
const checkOnly = args[0] === '--check';
const configPath = checkOnly ? args[1] : args[0];
if (!configPath) fail('missing local-routing.yml path');

const config = validateConfig(parseConfig(configPath), configPath);
if (checkOnly) {
  console.log(`PASS: local routing config valid for ${config.routes.length} route(s)`);
} else {
  startProxy(config);
}
