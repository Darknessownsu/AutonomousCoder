import { sql } from "drizzle-orm";
import { pgTable, text, varchar } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

export const users = pgTable("users", {
  id: varchar("id")
    .primaryKey()
    .default(sql`gen_random_uuid()`),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
});

export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
});

export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;

// Code Generation Request/Response schemas
export const generateCodeRequestSchema = z.object({
  title: z.string().min(3).max(100),
  description: z.string().min(10).max(1000),
  language: z.enum([
    "swift", "python", "javascript", "typescript", "java", "kotlin",
    "cpp", "c", "rust", "go", "ruby", "php", "bash", "shell", "sql",
    "html", "css", "scala", "haskell", "lua", "perl", "r", "dart", "elixir"
  ]),
  difficulty: z.enum(["easy", "medium", "hard", "expert"]),
});

export const generateCodeResponseSchema = z.object({
  code: z.string(),
  explanation: z.string(),
  language: z.string(),
});

export type GenerateCodeRequest = z.infer<typeof generateCodeRequestSchema>;
export type GenerateCodeResponse = z.infer<typeof generateCodeResponseSchema>;
