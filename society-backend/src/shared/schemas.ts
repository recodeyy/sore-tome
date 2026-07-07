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
    portal: z.string().optional(),
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

// Finance Schemas (money is in integer minor units / paise)
const minorUnits = z.number().int().nonnegative();

export const CreateInvoiceSchema = z.object({
  body: z.object({
    number: sanitizedString.max(50),
    unitId: z.string().max(64).optional(),
    memberId: z.string().max(64).optional(),
    period: z.string().max(20).optional(),
    dueDate: z.string().max(40).optional(),
    lines: z.array(z.object({
      description: sanitizedString.max(200),
      component: z.string().max(50).optional(),
      quantity: z.number().int().positive().optional().default(1),
      unitPriceMinor: minorUnits,
      taxMinor: minorUnits.optional().default(0),
    })).min(1, "At least one line is required"),
  }).strict()
});

export const RecordPaymentSchema = z.object({
  body: z.object({
    idempotencyKey: sanitizedString.max(100),
    invoiceId: sanitizedString.max(64),
    amountMinor: z.number().int().positive(),
    provider: z.string().max(40).optional(),
    providerPaymentId: z.string().max(120).optional(),
    metadata: z.record(z.string(), z.any()).optional(),
  }).strict()
});

// Razorpay checkout (§12) — order amount is derived server-side from the invoice.
export const CreatePaymentOrderSchema = z.object({
  body: z.object({
    invoiceId: sanitizedString.max(64),
    payerMemberId: z.string().max(64).optional(),
  }).strict()
});

export const VerifyPaymentSchema = z.object({
  body: z.object({
    razorpay_order_id: sanitizedString.max(120),
    razorpay_payment_id: sanitizedString.max(120),
    razorpay_signature: sanitizedString.max(256),
    invoiceId: z.string().max(64).optional(),
  }).strict()
});

export const CreateExpenseSchema = z.object({
  body: z.object({
    vendor: z.string().max(120).optional(),
    category: z.string().max(50).optional(),
    description: sanitizedString.max(300),
    amountMinor: z.number().int().positive(),
    taxMinor: minorUnits.optional().default(0),
  }).strict()
});

export const DecideExpenseSchema = z.object({
  body: z.object({
    decision: z.enum(["approved", "rejected"]),
    comment: z.string().max(500).optional(),
  }).strict()
});

// Amenity booking schemas
export const CreateAmenitySchema = z.object({
  body: z.object({
    name: sanitizedString.max(100),
    capacity: z.number().int().positive().optional().default(1),
  }).strict()
});

export const BookAmenitySchema = z.object({
  body: z.object({
    startAt: z.string().datetime({ message: "startAt must be an ISO datetime" }),
    endAt: z.string().datetime({ message: "endAt must be an ISO datetime" }),
    memberId: z.string().max(64).optional(),
  }).strict()
});

// Complaint Schemas (Phase 4)
export const CreateComplaintSchema = z.object({
  body: z.object({
    title: sanitizedString.max(150),
    description: sanitizedString.max(2000),
    categoryId: z.string().uuid().optional(),
    unitId: z.string().max(64).optional(),
    location: z.string().max(120).optional(),
    priority: z.enum(["low", "medium", "high", "critical"]).optional(),
    isPrivate: z.boolean().optional().default(false),
  }).strict()
});

export const AssignComplaintSchema = z.object({
  body: z.object({
    assigneeId: sanitizedString.max(64),
    assigneeType: z.enum(["staff", "committee", "vendor"]).optional().default("staff"),
    reason: z.string().max(300).optional(),
  }).strict()
});

export const ComplaintStatusSchema = z.object({
  body: z.object({
    status: z.enum(["open", "in_progress", "resolved", "closed"]),
    note: z.string().max(1000).optional(),
  }).strict()
});

export const ComplaintSlaPauseSchema = z.object({
  body: z.object({
    pause: z.boolean(),
    reason: z.string().max(300).optional(),
  }).strict()
});

export const ComplaintCommentSchema = z.object({
  body: z.object({
    body: sanitizedString.max(2000),
    visibility: z.enum(["internal", "resident"]).optional().default("resident"),
  }).strict()
});

export const ComplaintFeedbackSchema = z.object({
  body: z.object({
    rating: z.number().int().min(1).max(5),
    comment: z.string().max(500).optional(),
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

