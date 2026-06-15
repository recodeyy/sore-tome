import * as express from "express";

declare global {
  namespace Express {
    interface Request {
      user?: {
        uid: string;
        phone: string;
        role: string;
        name: string;
        society_id: string;
      } | any;
      requestId?: string;
    }
  }
}
