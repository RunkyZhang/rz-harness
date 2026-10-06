#!/usr/bin/env node
import crypto from 'node:crypto';
import childProcess from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const requiredFields = [
  'agent_id',
  'display_name',
  'kind',
  'adoption_level',
  'role_type',
  'source',
  'source_files',
  'runtime_targets',
  'permission',
  'trigger_stage',
  'input_artifacts',
  'output_artifacts',
  'output_contract',
  'required_gates',
  'gate_consumers',
  'degradation',
];

const arrayFields = [
  'source_files',
  'runtime_targets',
  'input_artifacts',
  'output_artifacts',
  'required_gates',
  'gate_consumers',
];

const permissions = new Set([
  'read_only',
  'orchestrator_write',
  'implementation_write_with_contract',
  'test_execution_only',
]);

const runtimeTargets = new Set([
  'codex_main_session',
  'codex_generated',
  'opencode',
]);

function fail(message) {
  console.error(`FAIL: ${message}`);
  process.exit(1);
}

function parseScalar(raw) {
  const value = raw.trim();
  if (!value) return '';
  if (value.startsWith('[') && value.endsWith(']')) {
    const body = value.slice(1, -1).trim();
    if (!body) return [];
    return body.split(',').map((item) => stripQuotes(item.trim())).filter(Boolean);
  }
  if (/^-?\d+$/.test(value)) return Number(value);
  return stripQuotes(value);
}

function stripQuotes(value) {
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }
  return value;
}

export function loadRegistry(registryPath) {
  if (!fs.existsSync(registryPath)) {
    fail(`registry file not found: ${registryPath}`);
  }

  const registry = { agents: [] };
  let currentAgent = null;
  const lines = fs.readFileSync(registryPath, 'utf8').split(/\r?\n/);

  lines.forEach((line, index) => {
    if (!line.trim() || line.trim().startsWith('#')) return;

    const topMatch = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (topMatch) {
      const [, key, raw] = topMatch;
      if (key === 'agents') return;
      registry[key] = parseScalar(raw);
      currentAgent = null;
      return;
    }

    const agentStart = line.match(/^  - ([A-Za-z0-9_-]+):\s*(.*)$/);
    if (agentStart) {
      const [, key, raw] = agentStart;
      currentAgent = {};
      currentAgent[key] = parseScalar(raw);
      registry.agents.push(currentAgent);
      return;
    }

    const agentField = line.match(/^    ([A-Za-z0-9_-]+):\s*(.*)$/);
    if (agentField && currentAgent) {
      const [, key, raw] = agentField;
      currentAgent[key] = parseScalar(raw);
      return;
    }

    fail(`${registryPath}:${index + 1}: unsupported registry syntax`);
  });

  return registry;
}

function requireValue(agent, key, label) {
  const value = agent[key];
  if (
    value === undefined ||
    value === null ||
    value === '' ||
    (Array.isArray(value) && value.length === 0)
  ) {
    fail(`${label} missing required key: ${key}`);
  }
}

export function validateRegistry(root, registryPath) {
  const registry = loadRegistry(registryPath);
  if (registry.version !== 1) {
    fail(`${registryPath}: version must be 1`);
  }
  if (!Array.isArray(registry.agents) || registry.agents.length === 0) {
    fail(`${registryPath}: agents must contain at least one agent`);
  }

  const seen = new Set();
  for (const agent of registry.agents) {
    const label = agent.agent_id || 'agent';
    for (const key of requiredFields) {
      requireValue(agent, key, label);
    }

    if (!/^[a-z0-9][a-z0-9-]*$/.test(agent.agent_id)) {
      fail(`${label}: agent_id must use lowercase kebab-case`);
    }
    if (seen.has(agent.agent_id)) {
      fail(`duplicate agent_id: ${agent.agent_id}`);
    }
    seen.add(agent.agent_id);

    for (const key of arrayFields) {
      if (!Array.isArray(agent[key])) {
        fail(`${label}: ${key} must be an inline array`);
      }
    }
    if (!permissions.has(agent.permission)) {
      fail(`${label}: unsupported permission: ${agent.permission}`);
    }
    for (const target of agent.runtime_targets) {
      if (!runtimeTargets.has(target)) {
        fail(`${label}: unsupported runtime target: ${target}`);
      }
    }
    for (const sourceFile of agent.source_files) {
      const absoluteSource = path.resolve(root, sourceFile);
      if (!fs.existsSync(absoluteSource)) {
        fail(`${label}: source file not found: ${sourceFile}`);
      }
      if (sourceFile.startsWith('.opencode/agents/')) {
        const source = fs.readFileSync(absoluteSource, 'utf8');
        if (!source.includes(`Registry: \`${agent.agent_id}\``)) {
          fail(`${label}: OpenCode agent source must contain Registry marker`);
        }
      }
    }
    for (const gate of [...agent.required_gates, ...agent.gate_consumers]) {
      if (gate.startsWith('scripts/') && !fs.existsSync(path.resolve(root, gate))) {
        fail(`${label}: gate file not found: ${gate}`);
      }
    }
    if (agent.runtime_targets.includes('codex_generated') && !agent.output_contract) {
      fail(`${label}: codex_generated agent requires output_contract`);
    }
  }

  return registry;
}

function tomlString(value) {
  return String(value).replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

function tomlArray(values) {
  return `[${values.map((value) => `"${tomlString(value)}"`).join(', ')}]`;
}

function registryHash(registryPath) {
  return crypto.createHash('sha256').update(fs.readFileSync(registryPath)).digest('hex');
}

function renderTemplate(template, values) {
  return template.replace(/\{\{([a-zA-Z0-9_]+)\}\}/g, (_, key) => {
    if (!(key in values)) {
      fail(`template placeholder not provided: ${key}`);
    }
    return values[key];
  });
}

function renderCodexAgent(root, registryPath, registryHashValue, agent) {
  const templatePath = path.resolve(root, 'templates/codex-agent.toml');
  const template = fs.readFileSync(templatePath, 'utf8');
  const sourceRegistry = path.relative(root, registryPath) || registryPath;
  const instructions = [
    agent.instructions,
    '',
    `Source files: ${agent.source_files.join(', ')}`,
    `Required gates: ${agent.required_gates.join(', ')}`,
    `Gate consumers: ${agent.gate_consumers.join(', ')}`,
    'Follow AGENTS.md and do not bypass harness gates.',
  ].join('\n');

  return renderTemplate(template, {
    source_registry: tomlString(sourceRegistry),
    source_registry_hash: registryHashValue,
    agent_id: tomlString(agent.agent_id),
    display_name: tomlString(agent.display_name),
    kind: tomlString(agent.kind),
    role_type: tomlString(agent.role_type),
    adoption_level: tomlString(agent.adoption_level),
    permission: tomlString(agent.permission),
    trigger_stage: tomlString(agent.trigger_stage),
    output_contract: tomlString(agent.output_contract),
    degradation: tomlString(agent.degradation),
    source_files: tomlArray(agent.source_files),
    runtime_targets: tomlArray(agent.runtime_targets),
    input_artifacts: tomlArray(agent.input_artifacts),
    output_artifacts: tomlArray(agent.output_artifacts),
    required_gates: tomlArray(agent.required_gates),
    gate_consumers: tomlArray(agent.gate_consumers),
    developer_instructions: instructions.replace(/"""/g, '\\"\\"\\"'),
  });
}

export function generateCodexAgents(root, registryPath, outputDir, mode, allowGlobal) {
  const registry = validateRegistry(root, registryPath);
  const hash = registryHash(registryPath);
  const targets = registry.agents.filter((agent) => agent.runtime_targets.includes('codex_generated'));
  const outputAbsolute = path.resolve(outputDir);
  const homeAgents = path.resolve(os.homedir(), '.codex/agents');

  if (mode === 'apply' && !allowGlobal) {
    if (outputAbsolute === homeAgents || outputAbsolute.startsWith(`${homeAgents}${path.sep}`)) {
      fail('global output requires --allow-global');
    }
  }

  if (mode === 'dry-run') {
    console.log('CODEX_AGENT_GENERATOR_DRY_RUN=1');
    console.log(`REGISTRY=${path.relative(root, registryPath) || registryPath}`);
    console.log(`REGISTRY_HASH=${hash}`);
    console.log(`OUTPUT_DIR=${outputDir}`);
    for (const agent of targets) {
      console.log(`WOULD_WRITE=${path.join(outputDir, `${agent.agent_id}.toml`)}`);
    }
    return;
  }

  fs.mkdirSync(outputAbsolute, { recursive: true });
  for (const agent of targets) {
    const targetPath = path.join(outputAbsolute, `${agent.agent_id}.toml`);
    fs.writeFileSync(targetPath, renderCodexAgent(root, registryPath, hash, agent), 'utf8');
    console.log(`WROTE=${targetPath}`);
  }
  console.log(`REGISTRY_HASH=${hash}`);
}

function findAgent(registry, agentId) {
  const agent = registry.agents.find((item) => item.agent_id === agentId);
  if (!agent) {
    fail(`agent not found: ${agentId}`);
  }
  return agent;
}

function parseListField(value) {
  const parsed = parseScalar(value || '');
  if (Array.isArray(parsed)) return parsed;
  return String(parsed || '')
    .split(',')
    .map((item) => stripQuotes(item.trim()))
    .filter(Boolean);
}

function validateCandidateConfirmation(confirmationPath, agentIds) {
  if (!confirmationPath) {
    fail(`candidate agent requires --candidate-confirmation: ${agentIds.join(', ')}`);
  }

  const resolved = path.resolve(confirmationPath);
  if (!fs.existsSync(resolved)) {
    fail(`candidate confirmation file not found: ${confirmationPath}`);
  }

  const requiredValues = {
    candidate_dispatch_confirmation: 'CONFIRMED',
    business_code_start_gate: 'PASS',
    allowed_paths_confirmed: 'yes',
    isolated_worktree_required: 'yes',
    protected_actions_allowed: 'no',
    global_config_write_allowed: 'no',
    db_or_release_actions_allowed: 'no',
  };

  for (const [key, expected] of Object.entries(requiredValues)) {
    const actual = fieldValue(resolved, key);
    if (actual !== expected) {
      fail(`candidate confirmation ${resolved}: ${key} is '${actual || 'missing'}', expected '${expected}'`);
    }
  }

  const allowedAgentIds = parseListField(fieldValue(resolved, 'allowed_agent_ids'));
  for (const agentId of agentIds) {
    if (!allowedAgentIds.includes(agentId)) {
      fail(`candidate confirmation ${resolved}: allowed_agent_ids missing ${agentId}`);
    }
  }

  return resolved;
}

function selectDispatchAgents(registry, options) {
  let agents = registry.agents;
  if (options.agentId) {
    agents = options.agentId.split(',').map((agentId) => findAgent(registry, agentId.trim()));
  }
  if (options.stage) {
    agents = agents.filter((agent) => agent.trigger_stage === options.stage);
  }
  if (options.runtime) {
    agents = agents.filter((agent) => agent.runtime_targets.includes(options.runtime));
  }
  if (agents.length === 0) {
    fail('no agent matched dispatch filters');
  }
  const candidates = agents.filter((agent) => agent.adoption_level === 'candidate');
  if (candidates.length > 0 && !options.allowCandidate) {
    fail(`candidate agent requires --allow-candidate: ${candidates.map((agent) => agent.agent_id).join(', ')}`);
  }
  if (candidates.length > 0) {
    validateCandidateConfirmation(options.candidateConfirmation, candidates.map((agent) => agent.agent_id));
  }
  return agents;
}

function listValue(values) {
  return values.join(',');
}

function printDispatchPlan(root, registryPath, agents, options = {}) {
  console.log('AGENT_DISPATCH_PLAN=1');
  console.log(`REGISTRY=${path.relative(root, registryPath) || registryPath}`);
  console.log(`REGISTRY_HASH=${registryHash(registryPath)}`);
  if (agents.some((agent) => agent.adoption_level === 'candidate')) {
    console.log(`CANDIDATE_CONFIRMATION=${options.candidateConfirmation}`);
  }
  for (const agent of agents) {
    console.log('---');
    console.log(`AGENT_ID=${agent.agent_id}`);
    console.log(`ROLE_TYPE=${agent.role_type}`);
    console.log(`ADOPTION_LEVEL=${agent.adoption_level}`);
    console.log(`PERMISSION=${agent.permission}`);
    console.log(`TRIGGER_STAGE=${agent.trigger_stage}`);
    console.log(`OUTPUT_CONTRACT=${agent.output_contract}`);
    console.log(`REQUIRED_GATES=${listValue(agent.required_gates)}`);
    console.log(`GATE_CONSUMERS=${listValue(agent.gate_consumers)}`);
    console.log(`DEGRADATION=${agent.degradation}`);
  }
}

function writeDispatchMarkdown(root, registryPath, outputPath, changeId, agents, options = {}) {
  const lines = [
    `# Agent Dispatch Plan: ${changeId || 'unscoped-change'}`,
    '',
    `registry: ${path.relative(root, registryPath) || registryPath}`,
    `registry_hash: ${registryHash(registryPath)}`,
    '',
  ];

  for (const agent of agents) {
    lines.push(`## ${agent.agent_id}`);
    lines.push('');
    lines.push(`agent_id: ${agent.agent_id}`);
    lines.push(`display_name: ${agent.display_name}`);
    lines.push(`role_type: ${agent.role_type}`);
    lines.push(`adoption_level: ${agent.adoption_level}`);
    lines.push(`candidate_dispatch: ${agent.adoption_level === 'candidate' ? 'explicit_opt_in' : 'not_applicable'}`);
    lines.push(`candidate_confirmation: ${agent.adoption_level === 'candidate' ? options.candidateConfirmation : 'not_applicable'}`);
    lines.push(`permission: ${agent.permission}`);
    lines.push(`trigger_stage: ${agent.trigger_stage}`);
    lines.push(`output_contract: ${agent.output_contract}`);
    lines.push(`required_gates: ${listValue(agent.required_gates)}`);
    lines.push(`gate_consumers: ${listValue(agent.gate_consumers)}`);
    lines.push(`input_artifacts: ${listValue(agent.input_artifacts)}`);
    lines.push(`output_artifacts: ${listValue(agent.output_artifacts)}`);
    lines.push(`degradation: ${agent.degradation}`);
    lines.push('');
  }

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${lines.join('\n')}\n`, 'utf8');
}

function parseDispatchPlan(planPath) {
  const plans = [];
  let current = null;
  const lines = fs.readFileSync(planPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const heading = line.match(/^##\s+(.+?)\s*$/);
    if (heading) {
      current = { heading: heading[1].trim() };
      plans.push(current);
      continue;
    }
    if (!current) continue;
    const field = line.match(/^([a-zA-Z0-9_]+):\s*(.*)$/);
    if (field) {
      current[field[1]] = field[2].trim();
    }
  }
  return plans;
}

function comparePlanField(plan, agent, key, expectedValue) {
  if (plan[key] !== expectedValue) {
    fail(`${plan.agent_id}: ${key} is '${plan[key] || 'missing'}', expected '${expectedValue}'`);
  }
}

function resolveCandidateConfirmationPath(root, changeDir, confirmationPath) {
  if (!confirmationPath || confirmationPath === 'not_applicable') {
    fail(`candidate confirmation missing for ${changeDir}`);
  }
  if (path.isAbsolute(confirmationPath)) {
    return confirmationPath;
  }

  const changeRelative = path.resolve(changeDir, confirmationPath);
  if (fs.existsSync(changeRelative)) {
    return changeRelative;
  }
  return path.resolve(root, confirmationPath);
}

export function dispatchPlanGate(root, registryPath, changeDir) {
  const planPath = path.join(changeDir, 'agent-dispatch-plan.md');
  if (!fs.existsSync(planPath)) {
    fail(`missing agent dispatch plan: ${planPath}`);
  }

  const registry = validateRegistry(root, registryPath);
  const plans = parseDispatchPlan(planPath).filter((plan) => plan.agent_id);
  if (plans.length === 0) {
    fail(`${planPath}: no agent_id entries found`);
  }

  for (const plan of plans) {
    const agent = registry.agents.find((item) => item.agent_id === plan.agent_id);
    if (!agent) {
      fail(`unregistered agent_id in dispatch plan: ${plan.agent_id}`);
    }

    comparePlanField(plan, agent, 'output_contract', agent.output_contract);
    comparePlanField(plan, agent, 'required_gates', listValue(agent.required_gates));
    comparePlanField(plan, agent, 'gate_consumers', listValue(agent.gate_consumers));
    comparePlanField(plan, agent, 'permission', agent.permission);

    if (agent.adoption_level === 'candidate' && plan.candidate_dispatch !== 'explicit_opt_in') {
      fail(`${agent.agent_id}: candidate agent requires explicit opt-in marker`);
    }
    if (agent.adoption_level === 'candidate') {
      const confirmationPath = resolveCandidateConfirmationPath(root, changeDir, plan.candidate_confirmation);
      validateCandidateConfirmation(confirmationPath, [agent.agent_id]);
    }
  }

  console.log(`PASS: agent dispatch plan gate passed for ${planPath}`);
}

export function dispatchPlan(root, registryPath, options) {
  const registry = validateRegistry(root, registryPath);
  const agents = selectDispatchAgents(registry, options);
  printDispatchPlan(root, registryPath, agents, options);
  if (options.outputPath) {
    writeDispatchMarkdown(root, registryPath, options.outputPath, options.changeId, agents, options);
    console.log(`DISPATCH_PLAN_WRITTEN=${options.outputPath}`);
  }
}

function fieldValue(file, key) {
  const content = fs.readFileSync(file, 'utf8');
  const pattern = new RegExp(`^\\s*${key}\\s*:\\s*(.+?)\\s*$`, 'm');
  const match = content.match(pattern);
  return match ? match[1].trim() : '';
}

function hasBlockedRow(file) {
  return fs.readFileSync(file, 'utf8')
    .split(/\r?\n/)
    .some((line) => /^\|[^|]+?\|[^|]+?\|[^|]+?\|[^|]+?\|$/.test(line) && !line.includes('---') && !line.includes('Blocker'));
}

function runGate(root, script, changeDir) {
  const result = childProcess.spawnSync(path.resolve(root, script), [changeDir], {
    cwd: root,
    encoding: 'utf8',
  });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (result.status !== 0) {
    fail(`${script} failed for ${changeDir}`);
  }
}

function expectedArtifactPath(changeDir, artifact) {
  if (artifact === 'diff' || artifact.includes('_or_')) {
    return null;
  }
  if (!artifact.endsWith('.md') && !artifact.includes('/')) {
    return null;
  }
  if (artifact.startsWith('changes/<change-id>/')) {
    return path.join(changeDir, artifact.slice('changes/<change-id>/'.length));
  }
  if (artifact.includes('<change-id>')) {
    return path.join(changeDir, artifact.replaceAll('<change-id>', path.basename(changeDir)));
  }
  if (!artifact.includes('/')) {
    return path.join(changeDir, artifact);
  }
  return path.resolve(artifact);
}

function requireDeclaredArtifacts(agent, changeDir) {
  for (const artifact of agent.output_artifacts) {
    const expectedPath = expectedArtifactPath(changeDir, artifact);
    if (!expectedPath) continue;
    if (!fs.existsSync(expectedPath)) {
      fail(`${agent.agent_id}: missing output artifact: ${expectedPath}`);
    }
  }
}

function gateGoalAchievedOrBlocked(root, changeDir) {
  const verification = path.join(changeDir, 'test-agent-verification.md');
  const status = fieldValue(verification, 'verification_status');
  const finalDecision = fieldValue(verification, 'final_decision');

  if (status === 'GOAL_ACHIEVED' && finalDecision === 'GOAL_ACHIEVED') {
    runGate(root, 'scripts/test-agent-verification-gate.sh', changeDir);
    return;
  }

  if (status === 'BLOCKED' && finalDecision === 'BLOCKED') {
    if (!hasBlockedRow(verification)) {
      fail('sfa-test-agent: BLOCKED output requires a blocker row');
    }
    console.log(`PASS: Test Agent blocked handoff recorded in ${verification}`);
    return;
  }

  fail(`sfa-test-agent: verification_status/final_decision must be GOAL_ACHIEVED or BLOCKED; got ${status || 'missing'} / ${finalDecision || 'missing'}`);
}

export function outputContractGate(root, registryPath, changeDir, agentId) {
  const registry = validateRegistry(root, registryPath);
  const agent = findAgent(registry, agentId);
  requireDeclaredArtifacts(agent, changeDir);

  if (agent.output_contract === 'review_findings') {
    runGate(root, 'scripts/reviewer-gate.sh', changeDir);
  } else if (agent.output_contract === 'GOAL_ACHIEVED_OR_BLOCKED') {
    gateGoalAchievedOrBlocked(root, changeDir);
  }

  console.log(`PASS: ${agent.agent_id} output contract ${agent.output_contract} passed for ${changeDir}`);
}

function main() {
  const [command, rootArg, registryArg, outputArg, modeArg, allowGlobalArg] = process.argv.slice(2);
  const root = path.resolve(rootArg || process.cwd());
  const registryPath = path.resolve(registryArg || path.join(root, 'config/agent-registry.yml'));

  if (command === 'gate') {
    const registry = validateRegistry(root, registryPath);
    console.log(`PASS: agent registry has ${registry.agents.length} agents`);
    return;
  }

  if (command === 'generate') {
    const outputDir = outputArg || path.join(root, '.harness/generated/codex-agents');
    const mode = modeArg === 'apply' ? 'apply' : 'dry-run';
    const allowGlobal = allowGlobalArg === 'allow-global';
    generateCodexAgents(root, registryPath, outputDir, mode, allowGlobal);
    return;
  }

  if (command === 'dispatch') {
    const options = {
      runtime: outputArg || '',
      stage: modeArg || '',
      agentId: allowGlobalArg || '',
      allowCandidate: process.argv[8] === 'allow-candidate',
      changeId: process.argv[9] || '',
      outputPath: process.argv[10] || '',
      candidateConfirmation: process.argv[11] || '',
    };
    dispatchPlan(root, registryPath, options);
    return;
  }

  if (command === 'output-gate') {
    const changeDir = outputArg;
    const agentId = modeArg;
    if (!changeDir || !agentId) {
      fail('output-gate requires change dir and agent id');
    }
    outputContractGate(root, registryPath, path.resolve(changeDir), agentId);
    return;
  }

  if (command === 'dispatch-gate') {
    const changeDir = outputArg;
    if (!changeDir) {
      fail('dispatch-gate requires change dir');
    }
    dispatchPlanGate(root, registryPath, path.resolve(changeDir));
    return;
  }

  fail(`unknown command: ${command || '<empty>'}`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
