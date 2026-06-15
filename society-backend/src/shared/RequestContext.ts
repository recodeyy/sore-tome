import { AsyncLocalStorage } from "async_hooks";

export interface RequestContext {
  societyId?: string;
  requestId?: string;
  userId?: string;
}

export const requestContextStore = new AsyncLocalStorage<RequestContext>();
