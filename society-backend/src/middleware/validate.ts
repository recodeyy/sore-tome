import { Request, Response, NextFunction } from "express";
import { ZodSchema, ZodError } from "zod";
import { logger } from "../shared/Logger";

/**
 * Higher-order middleware to validate incoming requests against a Zod schema.
 * Rejects with 400 Bad Request if validation fails.
 */
export const validate = (schema: ZodSchema) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      const validated: any = await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
        file: (req as any).file,
        files: (req as any).files,
      });

      // Update request with strictly typed/sanitized data.
      // Only overwrite a part when the schema actually validated it — otherwise
      // `validated.params`/`query` is undefined and would wipe Express's real
      // req.params (e.g. a `:id` path param), breaking every body-only schema
      // on a parameterised route.
      if (validated.body !== undefined) req.body = validated.body;
      if (validated.query !== undefined) req.query = validated.query;
      if (validated.params !== undefined) req.params = validated.params;

      // Note: Multer properties are usually read-only on req.file,
      // but we ensure the validated data is what we use.
      if (validated.file) (req as any).validatedFile = validated.file;

      return next();
    } catch (error) {
      if (error instanceof ZodError) {
        const errors = error.issues.map((issue: any) => ({
          path: issue.path.join("."),
          message: issue.message,
        }));

        logger.warn({ errors, url: req.url }, "Request validation failed");

        return res.status(400).json({
          error: "Validation failed",
          details: errors,
        });
      }

      logger.error({ error }, "Unexpected error during validation middleware");
      return res.status(500).json({ error: "Internal server error" });
    }
  };
};
