import { z } from "zod";

// Generic string sanitizer
const sanitizedString = z.string().trim().min(1);

// File Schema
export const FileSchema = z.object({
  fieldname: z.string(),
  originalname: z.string(),
  encoding: z.string(),
  mimetype: z.string().refine(
    (m) => ["image/jpeg", "image/png", "image/webp", "application/pdf"].includes(m),
    "Unsupported file type"
  ),
  size: z.number().max(10 * 1024 * 1024, "File too large (max 10MB)"),
});

// Auth Schemas
export const RegisterSchema = z.object({
  body: z.object({
    name: sanitizedString.max(100),
    phone: z.string().regex(/^\+?[1-9]\d{1,14}$/, "Invalid phone format"),
    password: z.string().min(6).max(50),
    flatNumber: sanitizedString.max(20),
    blockName: z.string().max(50).optional().default(""),
    society_id: sanitizedString.max(50), // Mandated for multi-tenancy
  }).strict()
});

export const LoginSchema = z.object({
  body: z.object({
    phone: z.string().min(1, "Phone is required"),
    password: z.string().min(1, "Password is required"),
  }).strict()
});

export const RefreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, "Refresh token is required"),
  }).strict()
});

// Issues Schemas
export const CreateIssueSchema = z.object({
  body: z.object({
    title: sanitizedString.max(150),
    description: sanitizedString.max(2000),
    category: z.enum(["maintenance", "security", "cleanliness", "other"]).optional().default("other"),
    priority: z.enum(["low", "medium", "high", "critical"]).optional().default("medium"),
  }).strict()
});

export const UpdateIssueStatusSchema = z.object({
  body: z.object({
    status: z.enum(["open", "in_progress", "resolved"]),
    adminNote: z.string().max(500).optional(),
    priority: z.enum(["low", "medium", "high", "critical"]).optional(),
  }).strict()
});

// Funds Schemas
export const CreateTransactionSchema = z.object({
  body: z.object({
    title: sanitizedString.max(100),
    amount: z.number().positive(),
    type: z.enum(["credit", "debit"]),
    category: sanitizedString.max(50).optional().default("Other"),
    note: z.string().max(255).optional(),
    transactionId: z.string().max(100).optional().nullable(),
  }).strict()
});

// Media Schemas
export const MediaUploadSchema = z.object({
  file: FileSchema,
  body: z.object({
    messageId: z.string().optional(),
  }).strict()
});

// Notices Schemas
export const CreateNoticeSchema = z.object({
  body: z.object({
    title: sanitizedString.max(200),
    body: sanitizedString.max(5000),
    type: z.enum(["general", "event", "maintenance", "festival"]).default("general"),
  }).strict()
});

