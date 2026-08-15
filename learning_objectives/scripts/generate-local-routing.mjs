#!/usr/bin/env node
import fs from 'node:fs';

function fail(message) {
  console.error(`FAIL: ${message}`);
  process.exit(1);
}

function expandEnvVars(value) {
  return value.replace(/\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/g, (match, name) => {
    if (Object.prototype.hasOwnProperty.call(process.env, name)) {
      return process.env[name];
    }
    fail(`environment variable ${name} is required by local backend services`);
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

function parseArgs(argv) {
  const args = {};
  for (let index = 0; index < argv.length; index += 1) {
    const key = argv[index];
    if (!key.startsWith('--')) fail(`unexpected argument: ${key}`);
    const value = argv[index + 1];
    if (!value || value.startsWith('--')) fail(`missing value for ${key}`);
    args[key.slice(2)] = value;
    index += 1;
  }
  return args;
}

function parseServiceRegistry(path) {
  const content = fs.readFileSync(path, 'utf8');
  const registry = { proxy_listen: {}, services: [] };
  let section = null;
  let currentService = null;

  for (const rawLine of content.split(/\r?\n/)) {
    if (rawLine.trim().startsWith('#')) continue;
    const withoutComment = rawLine.replace(/\s+#.*$/, '');
    if (!withoutComment.trim()) continue;

    const top = withoutComment.match(/^([A-Za-z0-9_]+):(?:\s*(.*))?$/);
    if (top) {
      const [, key, value = ''] = top;
      section = key;
      if (key !== 'proxy_listen' && key !== 'services') {
        registry[key] = cleanValue(value);
      }
      continue;
    }

    const proxyValue = withoutComment.match(/^  ([A-Za-z0-9_]+):\s*(.*)$/);
    if (section === 'proxy_listen' && proxyValue) {
      registry.proxy_listen[proxyValue[1]] = cleanValue(proxyValue[2]);
      continue;
    }

    const serviceStart = withoutComment.match(/^  - ([A-Za-z0-9_]+):\s*(.*)$/);
    if (section === 'services' && serviceStart) {
      currentService = {};
      currentService[serviceStart[1]] = cleanValue(serviceStart[2]);
      registry.services.push(currentService);
      continue;
    }

    const serviceValue = withoutComment.match(/^    ([A-Za-z0-9_]+):\s*(.*)$/);
    if (section === 'services' && currentService && serviceValue) {
      currentService[serviceValue[1]] = cleanValue(serviceValue[2]);
      continue;
    }

    fail(`unsupported local backend services line: ${rawLine}`);
  }

  return registry;
}

function splitCsv(value) {
  return String(value || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function requireValue(object, key, label) {
  if (!object[key] || object[key].startsWith('<')) {
    fail(`${label} missing required key: ${key}`);
  }
}

function validateRegistry(registry, path) {
  requireValue(registry, 'fallback_base_url', path);
  try {
    const fallback = new URL(registry.fallback_base_url);
    if (!['http:', 'https:'].includes(fallback.protocol)) {
      fail(`${path}: fallback_base_url must use http or https`);
    }
  } catch {
    fail(`${path}: fallback_base_url must be a valid URL`);
  }
  if (!Array.isArray(registry.services) || registry.services.length === 0) {
    fail(`${path}: services must contain at least one service`);
  }
  for (const service of registry.services) {
    const label = service.backend_repo || 'service';
    for (const key of [
      'backend_repo',
      'frontend_prefix',
      'strip_prefix',
      'backend_prefix',
      'local_target',
      'frontend_repos',
      'source_contract',
      'reason',
    ]) {
      requireValue(service, key, label);
    }
  }
}

function yamlEscape(value) {
  if (/^[A-Za-z0-9_./:@-]+$/.test(value)) return value;
  return JSON.stringify(value);
}

function renderRouting({ changeId, frontendRepo, registry, routes }) {
  const lines = [
    `change_id: ${yamlEscape(changeId)}`,
    `frontend_repo: ${yamlEscape(frontendRepo)}`,
    `fallback_base_url: ${yamlEscape(registry.fallback_base_url)}`,
    'proxy_listen:',
    `  host: ${yamlEscape(registry.proxy_listen.host || '127.0.0.1')}`,
    `  port: ${yamlEscape(registry.proxy_listen.port || '19080')}`,
    'routes:',
  ];

  for (const route of routes) {
    lines.push(
      `  - id: ${yamlEscape(`${route.backend_repo}-service`)}`,
      `    frontend_prefix: ${yamlEscape(route.frontend_prefix)}`,
      `    strip_prefix: ${yamlEscape(route.strip_prefix)}`,
      `    backend_prefix: ${yamlEscape(route.backend_prefix)}`,
      `    backend_repo: ${yamlEscape(route.backend_repo)}`,
      `    local_target: ${yamlEscape(route.local_target)}`,
      `    source_contract: ${yamlEscape(route.source_contract)}`,
      `    reason: ${yamlEscape(route.reason)}`,
    );
  }

  return `${lines.join('\n')}\n`;
}

function renderEnv({ registry, activeBackends, routes }) {
  const host = registry.proxy_listen.host || '127.0.0.1';
  const port = registry.proxy_listen.port || '19080';
  return [
    `VUE_APP_BASE_API=http://${host}:${port}/`,
    `SFA_HARNESS_ACTIVE_BACKENDS=${activeBackends.join(',')}`,
    `SFA_HARNESS_LOCAL_SERVICE_PREFIXES=${routes.map((route) => route.frontend_prefix).join(',')}`,
    '',
  ].join('\n');
}

const args = parseArgs(process.argv.slice(2));
for (const key of ['change-id', 'frontend-repo', 'active-backends', 'services', 'output']) {
  if (!args[key]) fail(`missing --${key}`);
}

const registry = parseServiceRegistry(args.services);
validateRegistry(registry, args.services);

const activeBackends = splitCsv(args['active-backends']);
if (activeBackends.length === 0) fail('--active-backends must contain at least one backend repo');

const serviceByRepo = new Map(registry.services.map((service) => [service.backend_repo, service]));
const unknown = activeBackends.filter((backend) => !serviceByRepo.has(backend));
if (unknown.length > 0) fail(`unknown active backend repo(s): ${unknown.join(', ')}`);

const routes = activeBackends
  .map((backend) => serviceByRepo.get(backend))
  .filter((service) => splitCsv(service.frontend_repos).includes(args['frontend-repo']));

if (routes.length === 0) {
  fail(`no local services match frontend repo ${args['frontend-repo']} and active backends ${activeBackends.join(', ')}`);
}

fs.writeFileSync(
  args.output,
  renderRouting({
    changeId: args['change-id'],
    frontendRepo: args['frontend-repo'],
    registry,
    routes,
  }),
);

if (args['env-output']) {
  fs.writeFileSync(args['env-output'], renderEnv({ registry, activeBackends, routes }));
}

console.log(`PASS: generated local routing for ${routes.length} active backend service(s)`);
