#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const BASE_URL = (process.env.MONICA_BASE_URL ?? "").replace(/\/+$/, "");
const TOKEN = process.env.MONICA_TOKEN ?? "";

if (!BASE_URL || !TOKEN) {
  console.error(
    "monica-mcp: set MONICA_BASE_URL (e.g. https://app.monicahq.com) and " +
      "MONICA_TOKEN (a Monica API bearer token) in the environment."
  );
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Tiny API client
// ---------------------------------------------------------------------------

class MonicaError extends Error {
  constructor(public status: number, public detail: string) {
    super(`Monica API error ${status}: ${detail}`);
  }
}

async function api<T = any>(
  path: string,
  method: string = "GET",
  body?: unknown
): Promise<T> {
  const res = await fetch(BASE_URL + path, {
    method,
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await res.text();
  if (!res.ok) {
    throw new MonicaError(res.status, text.slice(0, 500));
  }
  return (text ? JSON.parse(text) : {}) as T;
}

/** Wrap a tool handler so thrown errors come back as readable tool errors. */
function tool(fn: () => Promise<string>) {
  return async () => {
    try {
      return { content: [{ type: "text" as const, text: await fn() }] };
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      return { content: [{ type: "text" as const, text: msg }], isError: true };
    }
  };
}

function summarizeContact(c: any): string {
  const name =
    [c.prefix, c.first_name, c.middle_name, c.last_name, c.suffix]
      .filter(Boolean)
      .join(" ") ||
    c.nickname ||
    "Unnamed";
  return `${name} (id: ${c.id})`;
}

// ---------------------------------------------------------------------------
// Server + tools
// ---------------------------------------------------------------------------

const server = new McpServer({ name: "monica", version: "0.1.0" });

server.tool(
  "monica_list_vaults",
  "List the vaults (contact collections) in the Monica account.",
  {},
  tool(async () => {
    const res = await api<{ data: any[] }>("/api/vaults");
    if (!res.data.length) return "No vaults found.";
    return res.data
      .map((v) => `• ${v.name} (id: ${v.id})${v.description ? ` — ${v.description}` : ""}`)
      .join("\n");
  })
);

server.tool(
  "monica_list_contacts",
  "List contacts in a vault. Optionally filter by a name substring.",
  {
    vault_id: z.string().describe("The vault id (from monica_list_vaults)."),
    query: z.string().optional().describe("Case-insensitive name filter."),
  },
  async ({ vault_id, query }) =>
    tool(async () => {
      const res = await api<{ data: any[] }>(`/api/vaults/${vault_id}/contacts`);
      let contacts = res.data;
      if (query) {
        const q = query.toLowerCase();
        contacts = contacts.filter((c) =>
          summarizeContact(c).toLowerCase().includes(q)
        );
      }
      if (!contacts.length) return "No matching contacts.";
      return contacts.map((c) => `• ${summarizeContact(c)}`).join("\n");
    })()
);

server.tool(
  "monica_get_contact",
  "Get a contact's full record: notes, tasks, calls, reminders, important dates, contact info, addresses, relationships, and more.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
  },
  async ({ vault_id, contact_id }) =>
    tool(async () => {
      const res = await api<{ data: any }>(
        `/api/vaults/${vault_id}/contacts/${contact_id}`
      );
      return JSON.stringify(res.data, null, 2);
    })()
);

server.tool(
  "monica_create_contact",
  "Create a new contact in a vault. Provide at least one of first_name / last_name / nickname.",
  {
    vault_id: z.string(),
    first_name: z.string().optional(),
    last_name: z.string().optional(),
    middle_name: z.string().optional(),
    nickname: z.string().optional(),
    prefix: z.string().optional(),
    suffix: z.string().optional(),
  },
  async ({ vault_id, ...fields }) =>
    tool(async () => {
      const res = await api<{ data: any }>(
        `/api/vaults/${vault_id}/contacts`,
        "POST",
        { ...fields, listed: true }
      );
      return `Created contact ${summarizeContact(res.data)}.`;
    })()
);

server.tool(
  "monica_add_note",
  "Add a note to a contact.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    body: z.string().describe("The note text."),
    title: z.string().optional(),
  },
  async ({ vault_id, contact_id, body, title }) =>
    tool(async () => {
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/notes`,
        "POST",
        { body, title }
      );
      return "Note added.";
    })()
);

server.tool(
  "monica_add_task",
  "Add a task for a contact.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    label: z.string().describe("Short task title."),
    description: z.string().optional(),
    due_at: z.string().optional().describe("Due date, ISO 8601 (yyyy-MM-dd)."),
  },
  async ({ vault_id, contact_id, ...fields }) =>
    tool(async () => {
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/tasks`,
        "POST",
        fields
      );
      return "Task added.";
    })()
);

server.tool(
  "monica_toggle_task",
  "Toggle a contact task between completed and not completed.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    task_id: z.number().int(),
  },
  async ({ vault_id, contact_id, task_id }) =>
    tool(async () => {
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/tasks/${task_id}/toggle`,
        "POST"
      );
      return "Task toggled.";
    })()
);

server.tool(
  "monica_log_call",
  "Log a phone/video call with a contact.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    called_at: z.string().optional().describe("Date of the call, yyyy-MM-dd. Defaults to today."),
    type: z.enum(["audio", "video"]).optional(),
    who_initiated: z.enum(["me", "contact"]).optional(),
    answered: z.boolean().optional(),
    duration: z.number().int().optional().describe("Minutes."),
    description: z.string().optional(),
  },
  async ({ vault_id, contact_id, ...rest }) =>
    tool(async () => {
      const body = {
        called_at: rest.called_at ?? new Date().toISOString().slice(0, 10),
        type: rest.type ?? "audio",
        who_initiated: rest.who_initiated ?? "me",
        answered: rest.answered ?? true,
        duration: rest.duration,
        description: rest.description,
      };
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/calls`,
        "POST",
        body
      );
      return "Call logged.";
    })()
);

server.tool(
  "monica_add_reminder",
  "Add a reminder tied to a contact (e.g. recurring birthday wishes).",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    label: z.string(),
    day: z.number().int(),
    month: z.number().int(),
    year: z.number().int().optional(),
    type: z
      .enum(["one_time", "recurring_day", "recurring_month", "recurring_year"])
      .optional(),
  },
  async ({ vault_id, contact_id, ...rest }) =>
    tool(async () => {
      const body = {
        label: rest.label,
        day: rest.day,
        month: rest.month,
        year: rest.year,
        type: rest.type ?? "one_time",
        frequency_number: rest.type && rest.type !== "one_time" ? 1 : undefined,
      };
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/reminders`,
        "POST",
        body
      );
      return "Reminder added.";
    })()
);

server.tool(
  "monica_add_important_date",
  "Add an important date (birthday, anniversary, …) to a contact.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    label: z.string(),
    day: z.number().int(),
    month: z.number().int(),
    year: z.number().int().optional(),
  },
  async ({ vault_id, contact_id, ...fields }) =>
    tool(async () => {
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/important-dates`,
        "POST",
        fields
      );
      return "Important date added.";
    })()
);

server.tool(
  "monica_list_reference",
  "List the lookup ids needed by other tools — contact information types (for monica_add_contact_information), address types, and important date types.",
  { vault_id: z.string() },
  async ({ vault_id }) =>
    tool(async () => {
      const res = await api<{ data: any }>(`/api/vaults/${vault_id}/reference`);
      return JSON.stringify(res.data, null, 2);
    })()
);

server.tool(
  "monica_add_contact_information",
  "Add a piece of contact information (email, phone, …). Get the type id from monica_list_reference.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    contact_information_type_id: z.number().int(),
    data: z.string().describe("The value, e.g. the email address or phone number."),
  },
  async ({ vault_id, contact_id, ...fields }) =>
    tool(async () => {
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/contact-information`,
        "POST",
        fields
      );
      return "Contact information added.";
    })()
);

server.tool(
  "monica_add_address",
  "Add a postal address to a contact.",
  {
    vault_id: z.string(),
    contact_id: z.string(),
    line_1: z.string().optional(),
    line_2: z.string().optional(),
    city: z.string().optional(),
    province: z.string().optional(),
    postal_code: z.string().optional(),
    country: z.string().optional(),
    is_past_address: z.boolean().optional(),
  },
  async ({ vault_id, contact_id, ...rest }) =>
    tool(async () => {
      await api(
        `/api/vaults/${vault_id}/contacts/${contact_id}/addresses`,
        "POST",
        { ...rest, is_past_address: rest.is_past_address ?? false }
      );
      return "Address added.";
    })()
);

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

const transport = new StdioServerTransport();
await server.connect(transport);
console.error("monica-mcp running on stdio");
