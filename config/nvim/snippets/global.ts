import { TSSnippet } from "https://deno.land/x/denippet_vim@v0.5.1/loader.ts";
import { fn } from "https://deno.land/x/denippet_vim@v0.5.1/deps/denops.ts";

function pad(n: number): string {
  return String(n).padStart(2, "0");
}

function formatDate(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function formatTime(d: Date): string {
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

export const snippets: Record<string, TSSnippet> = {
  today: {
    prefix: "today",
    body: () => formatDate(new Date()),
  },
  tomorrow: {
    prefix: "tomorrow",
    body: () => {
      const d = new Date();
      d.setDate(d.getDate() + 1);
      return formatDate(d);
    },
  },
  yesterday: {
    prefix: "yesterday",
    body: () => {
      const d = new Date();
      d.setDate(d.getDate() - 1);
      return formatDate(d);
    },
  },
  now: {
    prefix: "now",
    body: () => {
      const d = new Date();
      return `${formatDate(d)} ${formatTime(d)}`;
    },
  },
  time: {
    prefix: "time",
    body: () => formatTime(new Date()),
  },
  uuid: {
    prefix: "uuid",
    body: () => crypto.randomUUID(),
  },
  fname: {
    prefix: "fname",
    body: async (denops) => await fn.expand(denops, "%:t:r") as string,
  },
  fpath: {
    prefix: "fpath",
    body: async (denops) => await fn.expand(denops, "%:p") as string,
  },
};
