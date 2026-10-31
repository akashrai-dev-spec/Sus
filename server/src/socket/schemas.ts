import { z } from "zod";

export const sessionHelloSchema = z.object({
  name: z.string().trim().min(1).max(25),
  color: z.string().regex(/^#[0-9a-fA-F]{6}$/),
  resumeToken: z.string().uuid().optional(),
});

export const gameSettingsSchema = z.object({
  maxPlayers: z.number().int().min(3).max(12).default(6),
  imposters: z.number().int().min(1).max(3).default(1),
  rounds: z.number().int().min(1).max(3).default(2),
  guessAttempts: z.number().int().min(1).max(2).default(1),
  category: z.string().default("Random"),
});

export const roomsCreateSchema = z.object({
  name: z.string().trim().min(1).max(30),
  pin: z.string().regex(/^\d{4}$/, "PIN must be exactly 4 digits"),
  settings: gameSettingsSchema,
});

export const roomsJoinSchema = z.object({
  roomId: z.string().min(1),
  pin: z.string().regex(/^\d{4}$/, "PIN must be exactly 4 digits"),
});

export const turnClueSchema = z.object({
  text: z.string().trim().min(1).max(60),
});

export const accuseSubmitSchema = z.object({
  targetId: z.string().min(1),
});

export const imposterGuessSchema = z.object({
  word: z.string().trim().min(1).max(50),
});

export const profileUpdateSchema = z.object({
  name: z.string().trim().min(1).max(25),
  color: z.string().regex(/^#[0-9a-fA-F]{6}$/),
});
