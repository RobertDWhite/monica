# Monica MCP server

An [MCP](https://modelcontextprotocol.io) server that lets Claude read and
update your [Monica](https://www.monicahq.com) personal CRM on your behalf. It
talks to the same JSON API the Monica iOS app uses.

## What Claude can do

| Tool | Action |
| --- | --- |
| `monica_list_vaults` | List your vaults |
| `monica_list_contacts` | List / search contacts in a vault |
| `monica_get_contact` | Full contact record (notes, tasks, calls, reminders, dates, contact info, addresses, relationships…) |
| `monica_create_contact` | Create a contact |
| `monica_add_note` | Add a note |
| `monica_add_task` / `monica_toggle_task` | Add or complete a task |
| `monica_log_call` | Log a call |
| `monica_add_reminder` | Add a (recurring) reminder |
| `monica_add_important_date` | Add a birthday/anniversary |
| `monica_list_reference` | Look up type ids (for contact info) |
| `monica_add_contact_information` | Add an email / phone / … |
| `monica_add_address` | Add a postal address |

These map to the contact-module API added under
`routes/api.php` → `vaults/{vault}/contacts/{contact}/…`.

## Build

```bash
cd mcp
npm install
npm run build
```

## Configuration

Two environment variables:

- `MONICA_BASE_URL` — your Monica base URL, e.g. `https://app.monicahq.com`
  (no trailing slash).
- `MONICA_TOKEN` — a Monica API bearer token. Either a personal access token
  from **Settings → API** in Monica, or a token minted by the mobile OAuth
  exchange (`POST /api/auth/token`). The token needs the `abilities:read` and
  `abilities:write` abilities.

### Register with Claude Code

```bash
claude mcp add monica \
  --env MONICA_BASE_URL=https://app.monicahq.com \
  --env MONICA_TOKEN=xxxxxxxx \
  -- node /absolute/path/to/monica/mcp/dist/index.js
```

### Register with Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "monica": {
      "command": "node",
      "args": ["/absolute/path/to/monica/mcp/dist/index.js"],
      "env": {
        "MONICA_BASE_URL": "https://app.monicahq.com",
        "MONICA_TOKEN": "xxxxxxxx"
      }
    }
  }
}
```

Restart the client, then ask Claude things like *"add a note to my contact
Jordan that we met at the conference"* or *"what important dates does Sam
have?"*.

## Notes

- Vault and contact ids are UUID strings; module item ids (tasks, notes, …) are
  integers.
- Every write returns success; use `monica_get_contact` to read the updated
  record back.
