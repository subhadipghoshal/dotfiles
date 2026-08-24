// i-have-adhd — OpenCode plugin (local install).
//
// Adapted from .opencode/plugins/i-have-adhd.mjs in ayghri/i-have-adhd v0.2.0.
// Changes from upstream: SKILL.md resolves to the canonical copy at
// the XDG agent skill root instead of a plugin-relative path.
//
//   • On demand   — registers the skills directory so the skill tool and
//                   /i-have-adhd can load the ruleset for the session.
//   • Always-on   — when the opt-in flag file exists, the full ruleset is
//                   appended to the system prompt every turn.
//
// Opt in to always-on:   touch ~/.config/opencode/.i-have-adhd-always
// Opt back out:          rm ~/.config/opencode/.i-have-adhd-always

import fs from 'fs';
import os from 'os';
import path from 'path';

const xdgConfigHome = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config');
const skillsDir = path.join(xdgConfigHome, 'agents', 'skills');
const skillPath = path.join(skillsDir, 'i-have-adhd', 'SKILL.md');

// Always-on opt-in flag, mirroring Claude Code's ~/.claude/.i-have-adhd-always
// but under OpenCode's config dir so the two tools stay independent.
const flagPath = path.join(
  xdgConfigHome,
  'opencode',
  '.i-have-adhd-always',
);

// Read SKILL.md and strip a leading YAML frontmatter block (--- ... ---).
// Regex matches upstream's always-on hooks so injections behave identically
// across harnesses.
function rulesetBody() {
  return fs
    .readFileSync(skillPath, 'utf8')
    .replace(/^---[^\S\r\n]*\r?\n[\s\S]*?\r?\n---[^\S\r\n]*(?:\r?\n|$)/, '')
    .replace(/(?:\r?\n)+$/, '');
}

export default async () => {
  return {
    // Make the skill discoverable (so the `skill` tool and the /i-have-adhd
    // command can load it).
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) config.skills.paths.push(skillsDir);
    },

    // Always-on: append the ruleset to the system prompt every turn while the
    // flag file exists. "stop adhd mode" turns it off for the session (the
    // model honours the skill's own Persistence rules); deleting the flag
    // turns always-on off for good.
    'experimental.chat.system.transform': async (_input, output) => {
      let on = false;
      try { on = fs.existsSync(flagPath); } catch (e) {}
      if (!on) return;

      let body;
      try { body = rulesetBody(); } catch (e) { return; }

      const header =
        'ADHD MODE ACTIVE (always-on). The ruleset below applies to every ' +
        'response. "stop adhd mode" or "normal mode" turns it off for this ' +
        'session; delete ' + flagPath + ' to turn always-on off for good.';
      const injected = header + '\n\n' + body;

      if (output.system.length > 0) {
        output.system[output.system.length - 1] += '\n\n' + injected;
      } else {
        output.system.push(injected);
      }
    },
  };
};
