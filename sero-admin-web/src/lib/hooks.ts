"use client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "./api-client";

// Live-data hook. Every widget in the app uses this — there is no mock path.
export function useApi<T>(key: (string | number)[], path: string, enabled = true) {
  return useQuery<T>({
    queryKey: key,
    queryFn: () => api.get<T>(path),
    enabled,
  });
}

export function useApiMutation<TIn = any, TOut = any>(
  method: "post" | "put" | "patch" | "del",
  invalidate: (string | number)[][] = []
) {
  const qc = useQueryClient();
  return useMutation<TOut, Error, { path: string; body?: TIn }>({
    mutationFn: ({ path, body }) => api[method]<TOut>(path, body),
    onSuccess: () => {
      invalidate.forEach((k) => qc.invalidateQueries({ queryKey: k }));
    },
  });
}

export function num(v: unknown): number {
  if (typeof v === "number") return v;
  if (typeof v === "string") return Number(v) || 0;
  return 0;
}
